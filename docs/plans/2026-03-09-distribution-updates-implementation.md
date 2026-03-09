# Distribution & Updates Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add GitHub-based update checking and version management to Harbor, enabling users to be notified of new releases through a dynamic menu item.

**Architecture:** Create `UpdateCheckerService` actor to check GitHub API for latest release, compare with current version, and update menu item state. No automatic downloads - users click to open GitHub release page in browser.

**Tech Stack:** Swift 6, URLSession for GitHub API, UserDefaults for tracking, NSAlert for update dialog

---

## Task 1: Add GitHub Repository Constants

**Files:**

- Modify: `Harbor/Harbor/Utils/Constants.swift`

**Step 1: Add GitHub and update constants**

```swift
// After existing constants, add:

// GitHub & Updates
nonisolated static let githubRepoOwner = "markriggan"
nonisolated static let githubRepoName = "harbor"
nonisolated static let githubApiBaseURL = "https://api.github.com"
nonisolated static let updateCheckInterval: TimeInterval = 86400 // 24 hours
```

**Step 2: Verify build succeeds**

Build in Xcode (Cmd+B)
Expected: Build succeeds with no errors

**Step 3: Commit**

```bash
git add Harbor/Harbor/Utils/Constants.swift
git commit -m "feat: add GitHub repository constants for update checking"
```

---

## Task 2: Create GitHubRelease Model

**Files:**

- Create: `Harbor/Harbor/Models/GitHubRelease.swift`

**Step 1: Create GitHubRelease model file**

```swift
//
//  GitHubRelease.swift
//  Harbor
//

import Foundation

struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let body: String
    let htmlUrl: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
    }

    /// Extracts version from tag (removes "v" prefix if present)
    var version: String {
        tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
    }

    /// Truncates release notes to specified character limit
    func truncatedBody(maxLength: Int = 200) -> String {
        guard body.count > maxLength else { return body }
        let truncated = String(body.prefix(maxLength))
        return truncated + "..."
    }
}
```

**Step 2: Build and verify**

Build in Xcode (Cmd+B)
Expected: Build succeeds

**Step 3: Commit**

```bash
git add Harbor/Harbor/Models/GitHubRelease.swift
git commit -m "feat: add GitHubRelease model for API responses"
```

---

## Task 3: Create UpdateCheckerService

**Files:**

- Create: `Harbor/Harbor/Services/UpdateCheckerService.swift`

**Step 1: Create UpdateCheckerService actor**

```swift
//
//  UpdateCheckerService.swift
//  Harbor
//

import Foundation

actor UpdateCheckerService {

    /// Checks GitHub API for the latest release
    func checkForUpdates() async -> UpdateCheckResult {
        let urlString = "\(Constants.githubApiBaseURL)/repos/\(Constants.githubRepoOwner)/\(Constants.githubRepoName)/releases/latest"

        guard let url = URL(string: urlString) else {
            return .error(.invalidURL)
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return .error(.networkError)
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

            guard let currentVersion = getCurrentVersion() else {
                return .error(.invalidCurrentVersion)
            }

            if isNewerVersion(current: currentVersion, latest: release.version) {
                return .updateAvailable(release)
            } else {
                return .upToDate
            }

        } catch {
            return .error(.networkError)
        }
    }

    /// Gets current app version from bundle
    private func getCurrentVersion() -> String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    /// Compares two version strings
    private func isNewerVersion(current: String, latest: String) -> Bool {
        // Strip "v" prefix if present
        let currentClean = current.hasPrefix("v") ? String(current.dropFirst()) : current
        let latestClean = latest.hasPrefix("v") ? String(latest.dropFirst()) : latest

        // Use numeric comparison for version strings
        return currentClean.compare(latestClean, options: .numeric) == .orderedAscending
    }
}

enum UpdateCheckResult {
    case updateAvailable(GitHubRelease)
    case upToDate
    case error(UpdateCheckError)
}

enum UpdateCheckError {
    case invalidURL
    case networkError
    case invalidCurrentVersion
}
```

**Step 2: Build and verify**

Build in Xcode (Cmd+B)
Expected: Build succeeds

**Step 3: Commit**

```bash
git add Harbor/Harbor/Services/UpdateCheckerService.swift
git commit -m "feat: add UpdateCheckerService for GitHub release checking"
```

---

## Task 4: Add Update Tracking to AppStateManager

**Files:**

- Modify: `Harbor/Harbor/Managers/AppStateManager.swift`

**Step 1: Add update tracking properties**

After the existing properties (showBadgeCount, launchAtLogin), add:

```swift
// Update tracking
@AppStorage("lastUpdateCheckTime") var lastUpdateCheckTime: TimeInterval = 0
@AppStorage("currentVersion") var currentVersion: String = ""
```

**Step 2: Add update tracking methods**

After the existing methods, add:

```swift
// MARK: - Update Tracking

func shouldCheckForUpdates() -> Bool {
    let now = Date().timeIntervalSince1970
    let elapsed = now - lastUpdateCheckTime
    return elapsed >= Constants.updateCheckInterval
}

func recordUpdateCheck() {
    lastUpdateCheckTime = Date().timeIntervalSince1970
}

func updateCurrentVersion() {
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
        currentVersion = version
    }
}
```

**Step 3: Build and verify**

Build in Xcode (Cmd+B)
Expected: Build succeeds

**Step 4: Commit**

```bash
git add Harbor/Harbor/Managers/AppStateManager.swift
git commit -m "feat: add update tracking to AppStateManager"
```

---

## Task 5: Add Update Menu State to HarborApp

**Files:**

- Modify: `Harbor/Harbor/HarborApp.swift`

**Step 1: Add update checker service and state**

In the `AppDelegate` class, after the existing properties, add:

```swift
private let updateChecker = UpdateCheckerService()
private var updateMenuItemTitle = "Checking for updates..."
private var updateMenuItemEnabled = false
private var latestRelease: GitHubRelease?
```

**Step 2: Add update check on launch**

In `applicationDidFinishLaunching`, after the existing setup code, add:

```swift
// Check for updates after short delay
Task { @MainActor in
    try? await Task.sleep(for: .seconds(2))
    await checkForUpdates()
}
```

**Step 3: Add checkForUpdates method**

Add this method to the `AppDelegate` class:

```swift
@MainActor
private func checkForUpdates() async {
    // Only check if cooldown period has passed
    guard AppStateManager.shared.shouldCheckForUpdates() else {
        updateMenuItemTitle = "You're up to date"
        updateMenuItemEnabled = false
        return
    }

    let result = await updateChecker.checkForUpdates()

    switch result {
    case .updateAvailable(let release):
        updateMenuItemTitle = "Update Available - Version \(release.version)"
        updateMenuItemEnabled = true
        latestRelease = release
        AppStateManager.shared.recordUpdateCheck()

    case .upToDate:
        updateMenuItemTitle = "You're up to date"
        updateMenuItemEnabled = false
        AppStateManager.shared.recordUpdateCheck()

    case .error:
        // Silent failure - show up to date
        updateMenuItemTitle = "You're up to date"
        updateMenuItemEnabled = false
    }
}
```

**Step 4: Build and verify**

Build in Xcode (Cmd+B)
Expected: Build succeeds

**Step 5: Commit**

```bash
git add Harbor/Harbor/HarborApp.swift
git commit -m "feat: add update checking on app launch"
```

---

## Task 6: Add Dynamic Update Menu Item

**Files:**

- Modify: `Harbor/Harbor/HarborApp.swift`

**Step 1: Add separator and update menu item to buildMenu**

In the `buildMenu()` method, after the "ACTIVE SERVERS" section and before "Stop All", add:

```swift
// Separator before update item
menu.addItem(NSMenuItem.separator())

// Update menu item (dynamic)
let updateItem = NSMenuItem(
    title: updateMenuItemTitle,
    action: updateMenuItemEnabled ? #selector(showUpdateDialog) : nil,
    keyEquivalent: ""
)
updateItem.isEnabled = updateMenuItemEnabled
if !updateMenuItemEnabled {
    // Gray out disabled items
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 13),
        .foregroundColor: NSColor.secondaryLabelColor
    ]
    updateItem.attributedTitle = NSAttributedString(string: updateMenuItemTitle, attributes: attributes)
}
menu.addItem(updateItem)
```

**Step 2: Add showUpdateDialog method**

Add this method to the `AppDelegate` class:

```swift
@MainActor
@objc private func showUpdateDialog() {
    guard let release = latestRelease else { return }

    let alert = NSAlert()
    alert.messageText = "Harbor \(release.version) is Available"
    alert.informativeText = release.truncatedBody()
    alert.alertStyle = .informational
    alert.addButton(withTitle: "View Release")
    alert.addButton(withTitle: "Later")

    let response = alert.runModal()

    if response == .alertFirstButtonReturn {
        // Open GitHub release page in browser
        if let url = URL(string: release.htmlUrl) {
            NSWorkspace.shared.open(url)
        }
    }
}
```

**Step 3: Build and run**

Build and run in Xcode (Cmd+R)
Expected: App builds and runs, shows "Checking for updates..." briefly, then shows actual status

**Step 4: Test update menu item**

- Click menubar icon
- Look for update menu item below separator
- Should show "You're up to date" (disabled) if no update available
- If testing with older version, should show "Update Available - Version X.X" (enabled)

**Step 5: Commit**

```bash
git add Harbor/Harbor/HarborApp.swift
git commit -m "feat: add dynamic update menu item with dialog"
```

---

## Task 7: Update README Installation Section

**Files:**

- Modify: `README.md`

**Step 1: Replace Installation section**

Find the current Installation section and replace it with:

````markdown
## Installation

### Download (Recommended)

1. Download the latest release from [Releases](https://github.com/markriggan/harbor/releases)
2. Open the DMG and drag Harbor to your Applications folder
3. Launch Harbor from Applications

Harbor automatically checks for updates on launch and will notify you when new versions are available.

### Homebrew

```bash
brew install --cask harbor
```
````

_Note: Homebrew cask will be available after the first stable release._

### Building from Source

1. Clone this repository
2. Open `Harbor.xcodeproj` in Xcode 15.0+
3. Build and run (Cmd+R)
4. Harbor will appear in your menubar

````

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README with download and Homebrew installation"
````

---

## Task 8: Update CLAUDE.md with Release Process

**Files:**

- Modify: `CLAUDE.md`

**Step 1: Add release section to Development Notes**

At the end of the "Development Notes" section in CLAUDE.md, add:

````markdown
### Releasing a New Version

**Version update:**

1. In Xcode, update `MARKETING_VERSION` (e.g., 1.0 → 1.1)
2. Increment `CURRENT_PROJECT_VERSION` by 1

**Create release:**

```bash
# Commit version bump
git add Harbor/Harbor.xcodeproj/project.pbxproj
git commit -m "chore: bump version to X.X"

# Create and push tag
git tag vX.X
git push origin main
git push origin vX.X
```
````

**Build and distribute:**

1. Product → Archive → Export ("Distribute App" → "Copy App")
2. Create DMG with Harbor.app
3. Go to GitHub → Releases → "Create a new release"
4. Tag: `vX.X`, Title: `Version X.X`
5. Upload DMG as `Harbor-X.X.dmg`
6. Add release notes (see template in distribution design doc)
7. Publish release

**Release notes template:**

```markdown
## New Features

- Feature description

## Bug Fixes

- Fix description

## Improvements

- Improvement description

---

**Installation:** Download Harbor-X.X.dmg, drag to Applications, replace existing version.
```

Update checker will automatically detect the new version on next launch.

````

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add release process to CLAUDE.md"
````

---

## Task 9: Create First GitHub Release

**Files:**

- N/A (GitHub UI task)

**Step 1: Update version in Xcode**

1. Open `Harbor.xcodeproj` in Xcode
2. Select Harbor project in navigator
3. Select Harbor target
4. Under "General" tab, find:
   - Marketing Version: Change to `1.0`
   - Current Project Version: Change to `1`

**Step 2: Commit version**

```bash
git add Harbor/Harbor.xcodeproj/project.pbxproj
git commit -m "chore: set initial version to 1.0"
```

**Step 3: Create and push tag**

```bash
git tag v1.0
git push origin main
git push origin v1.0
```

**Step 4: Build release binary**

1. In Xcode: Product → Archive
2. Once archived, click "Distribute App"
3. Select "Custom" → "Copy App"
4. Choose export location
5. Click "Export"

**Step 5: Create DMG**

1. Create a new folder
2. Copy `Harbor.app` into it
3. Open Disk Utility
4. File → New Image → Image from Folder
5. Select folder, save as `Harbor-1.0.dmg`

**Step 6: Create GitHub Release**

1. Go to https://github.com/markriggan/harbor/releases
2. Click "Create a new release"
3. Tag: `v1.0`
4. Title: `Version 1.0`
5. Description:

```markdown
## Initial Release

Harbor is a native macOS menubar utility for managing localhost development servers.

### Features

- Automatic port detection (3000-9000)
- Rich process metadata (folder, command, uptime)
- Quick actions to stop individual or all servers
- Native macOS design with dark mode support
- Badge count showing active ports
- Launch at login option

---

**Installation:** Download Harbor-1.0.dmg, drag to Applications folder, and launch.
```

6. Drag and drop `Harbor-1.0.dmg` to attach
7. Click "Publish release"

**Step 7: Test update checker**

1. Build and run Harbor from Xcode (should be version 1.0)
2. Wait 2 seconds for update check
3. Click menubar → should show "You're up to date" (no newer version exists)

---

## Task 10: Final Testing

**Files:**

- N/A (manual testing)

**Step 1: Test update check on launch**

1. Build and run Harbor
2. Wait 2-3 seconds
3. Click menubar icon
4. Verify update menu item shows "You're up to date" (disabled, gray)

**Step 2: Test 24-hour cooldown**

1. Check UserDefaults: `defaults read com.harbor.Harbor lastUpdateCheckTime`
2. Should show recent timestamp
3. Restart app
4. Update menu should immediately show "You're up to date" (no "Checking...")
5. This confirms cooldown is working

**Step 3: Test update available scenario (simulate)**

To test the update available state, you would need to:

1. Temporarily change current version to 0.9 in Xcode
2. Build and run
3. Should detect 1.0 as available
4. Click "Update Available - Version 1.0"
5. Should show dialog with release notes
6. Click "View Release" → should open GitHub in browser

**Step 4: Verify no crashes or errors**

- Check Xcode console for any errors during update check
- Verify network request completes successfully
- Confirm graceful handling of network failures (disconnect WiFi, restart app)

---

## Summary

This implementation adds:

- ✅ GitHub API-based update checking
- ✅ Dynamic menu item showing update status
- ✅ Version comparison logic
- ✅ Update dialog with link to GitHub
- ✅ 24-hour check cooldown
- ✅ Updated documentation (README, CLAUDE.md)
- ✅ Initial v1.0 release on GitHub

**Next steps after this plan:**

- Submit Homebrew cask formula (after 2-3 stable releases)
- Consider adding Sparkle if you get Apple Developer ID
- Add automatic DMG creation script
