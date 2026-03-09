# Harbor Distribution & Updates Design

**Date:** March 9, 2026
**Status:** Approved

## Overview

Design for Harbor's distribution system and automatic update checking. This enables users to easily install Harbor via DMG download or Homebrew, and be notified of new versions through GitHub-based update checking.

## Goals

1. **Primary distribution via DMG** - Simple download and install for all users
2. **Secondary distribution via Homebrew** - CLI option for developer users
3. **Automatic update notifications** - Check GitHub for new releases on launch
4. **Version tracking** - Proper semantic versioning with release notes
5. **No code signing required** - Works without Apple Developer ID

## Non-Goals

- Automatic download/install of updates (requires Sparkle + code signing)
- App Store distribution
- Custom update server infrastructure
- Auto-update for Homebrew users (Homebrew handles this)

## Version Management

### Versioning Scheme

**Marketing Version (user-facing):**

- Format: `X.Y` (e.g., 1.0, 1.1, 2.0)
- Stored in: `MARKETING_VERSION` (Xcode) → `CFBundleShortVersionString`
- Displayed in: About window, update dialogs, GitHub releases

**Build Number (internal):**

- Format: Integer (e.g., 1, 2, 3...)
- Stored in: `CURRENT_PROJECT_VERSION` (Xcode) → `CFBundleVersion`
- Used for: Build tracking, tiebreaker in version comparison

### Version Comparison

Compare marketing versions using semantic versioning:

- Strip "v" prefix from GitHub tags (v1.1 → 1.1)
- Compare: 1.0 < 1.1 < 1.2 < 2.0
- Use String comparison with version semantics

### Where Versions Appear

- About window: "Harbor 1.0"
- Update menu: "Update Available - Version 1.1"
- Update dialog: "Harbor 1.1 is Available"
- GitHub Release tag: `v1.1`
- DMG filename: `Harbor-1.1.dmg`

## Update Checker Service

### Architecture

**New component:** `UpdateCheckerService` (actor for background work)

**Responsibilities:**

- Check GitHub API for latest release
- Parse version and release notes
- Compare with current version
- Return update information or nil

### GitHub API Integration

**Endpoint:**

```
GET https://api.github.com/repos/markriggan/harbor/releases/latest
```

**Response model:**

```swift
struct GitHubRelease: Codable {
    let tagName: String        // "v1.1"
    let name: String           // "Version 1.1"
    let body: String           // Release notes (markdown)
    let htmlUrl: String        // Link to release page
}
```

**Rate limiting:**

- GitHub allows 60 unauthenticated requests/hour
- Harbor checks once per launch (well within limits)
- Cache last check time in UserDefaults
- Only check once per 24 hours automatically

### Version Comparison Logic

```swift
func isNewerVersion(current: String, latest: String) -> Bool {
    // Strip "v" prefix if present
    let currentClean = current.hasPrefix("v") ? String(current.dropFirst()) : current
    let latestClean = latest.hasPrefix("v") ? String(latest.dropFirst()) : latest

    // Compare using version semantics
    return currentClean.compare(latestClean, options: .numeric) == .orderedAscending
}
```

### Error Handling

**Network failures:**

- Silent failure (no user notification)
- Log error for debugging
- Menu shows "You're up to date" (graceful degradation)

**Rate limiting:**

- Respect 24-hour cooldown between automatic checks
- Manual checks always execute (user-initiated)

**Invalid response:**

- Parse errors logged, no user notification
- Fallback to "You're up to date"

**Already up to date:**

- No dialog shown
- Menu displays "You're up to date" (disabled)

### When Checks Run

1. **On launch** - After 2-second delay to avoid blocking startup
2. **Manual check** - When user clicks update menu item (if enabled)
3. **Cooldown** - Automatic checks limited to once per 24 hours

## Update UI/UX

### Menu Integration

**Dynamic menu item** (added below "ACTIVE SERVERS" section):

**State 1 - Checking:**

- Label: "Checking for updates..."
- Disabled (not clickable)
- Shows briefly during initial check

**State 2 - Up to date:**

- Label: "You're up to date"
- Disabled (not clickable)
- Gray/secondary text color

**State 3 - Update available:**

- Label: "Update Available - Version 1.1"
- Enabled (clickable)
- Primary text color

**State 4 - Check failed:**

- Falls back to State 2 (silent failure)
- No error shown to user

### Update Dialog (NSAlert)

**Triggered when:** User clicks "Update Available - Version X.X" menu item

**Dialog configuration:**

- Style: Informational
- Icon: Standard macOS info icon
- Title: "Harbor 1.1 is Available"
- Message: First 200 characters of release notes + "..."
- Buttons:
  - "View Release" (default) → Opens GitHub release page
  - "Later" (cancel) → Dismisses dialog

**Release notes formatting:**

- Strip markdown syntax for plain text
- Truncate at 200 characters
- Add "..." if truncated
- Preserve line breaks

### User Defaults Tracking

**Keys:**

- `lastUpdateCheckTime` (Date) - Timestamp of last check
- `currentVersion` (String) - Detect when app was updated

**Behavior:**

- Check timestamp to enforce 24-hour cooldown
- Reset cooldown when version changes (user updated manually)

## Release & Distribution Workflow

### Creating a Release

**Step 1: Update version**

```bash
# In Xcode, update:
# - MARKETING_VERSION: 1.0 → 1.1
# - CURRENT_PROJECT_VERSION: increment by 1
```

**Step 2: Commit version bump**

```bash
git add Harbor/Harbor.xcodeproj/project.pbxproj
git commit -m "chore: bump version to 1.1"
git push
```

**Step 3: Create git tag**

```bash
git tag v1.1
git push origin v1.1
```

**Step 4: Build release binary**

```
Product → Archive → Export
Select: "Distribute App" → "Copy App"
```

**Step 5: Create DMG**

```bash
# Manual: Create folder with Harbor.app, create DMG via Disk Utility
# Or use create-dmg tool (can be added later)
# Result: Harbor-1.1.dmg
```

**Step 6: Create GitHub Release**

1. Go to GitHub → Releases → "Create a new release"
2. Tag: `v1.1`
3. Title: `Version 1.1`
4. Description: Use release notes template (see below)
5. Upload: `Harbor-1.1.dmg`
6. Publish release

### Release Notes Template

```markdown
## New Features

- Feature description with user benefit
- Another feature

## Bug Fixes

- Fix description and what it resolves
- Another fix

## Improvements

- Performance or UX improvement
- Another improvement

---

**Installation:** Download Harbor-1.1.dmg, drag to Applications, replace existing version.
```

**Guidelines:**

- Use user-friendly language (not technical jargon)
- Focus on benefits, not implementation details
- Keep each item to 1-2 lines
- Categorize clearly (Features, Fixes, Improvements)

### DMG Packaging

**Contents:**

- App bundle: `Harbor.app`
- Simple layout (app icon + Applications folder shortcut optional)

**Naming:**

- Format: `Harbor-{version}.dmg`
- Example: `Harbor-1.1.dmg`

**Future enhancements:**

- Background image with drag instructions
- Automatic DMG creation script
- Code signing (requires Developer ID)

### Homebrew Cask Distribution

**Timeline:** After 2-3 stable releases with DMG

**Process:**

1. Create homebrew-cask formula pointing to GitHub Releases
2. Submit PR to homebrew/homebrew-cask
3. Homebrew community maintains formula
4. Users install: `brew install --cask harbor`
5. Users update: `brew upgrade harbor`

**Formula auto-detects latest release** - No manual updates needed after initial submission.

## Documentation Updates

### README.md Changes

**Current Installation section:**

```markdown
## Installation

### Building from Source

1. Clone this repository
2. Open `Harbor.xcodeproj` in Xcode 15.0+
3. Build and run (Cmd+R)
4. Harbor will appear in your menubar
```

**New Installation section:**

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

Note: Homebrew cask will be available after the first stable release.

### Building from Source

1. Clone this repository
2. Open `Harbor.xcodeproj` in Xcode 15.0+
3. Build and run (Cmd+R)

````

### CLAUDE.md Updates

Add new section under "Development Notes":

```markdown
### Releasing a New Version

1. Update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in Xcode
2. Commit version bump: `git commit -m "chore: bump version to X.X"`
3. Tag release: `git tag vX.X && git push origin vX.X`
4. Archive and export app (Product → Archive → Export)
5. Create DMG with app bundle
6. Create GitHub Release with tag, upload DMG, add release notes
7. Update checker will automatically detect new version
````

## Technical Implementation

### New Files

**Harbor/Services/UpdateCheckerService.swift:**

- Actor for background update checking
- GitHub API integration
- Version comparison logic

**Harbor/Models/GitHubRelease.swift:**

- Codable model for API response
- Release information structure

### Modified Files

**Harbor/HarborApp.swift:**

- Add update menu item to menu builder
- Handle update check on launch
- Show update dialog when user clicks menu

**Harbor/Managers/AppStateManager.swift:**

- Add update tracking keys
- Store last check time
- Store current version

**Harbor/Utils/Constants.swift:**

- Add GitHub repository URL
- Add update check interval (24 hours)

### Code Flow

```
App Launch
    ↓
Delay 2 seconds
    ↓
UpdateCheckerService.checkForUpdates()
    ↓
Fetch GitHub API
    ↓
Parse response
    ↓
Compare versions
    ↓
Update menu item state
    ↓
If update available → Enable menu item
If up to date → Disable menu item
```

## Security Considerations

### Network Security

- HTTPS only (GitHub API)
- No custom servers
- No user data sent
- Read-only API access

### Version Verification

- Compare against known format (vX.Y)
- Validate response structure before parsing
- Handle malformed data gracefully

### User Control

- Manual download/install (user reviews DMG before installing)
- No automatic downloads
- User initiates all update actions
- Can ignore updates indefinitely

## Future Enhancements

**Post v1.1 (not in scope):**

- Sparkle integration when code signing available
- Automatic DMG creation script
- Delta updates for smaller downloads
- In-app release notes view (SwiftUI)
- Update preferences (auto-check on/off)
- Beta channel for testing
- Version history view

## Success Criteria

The distribution and update system is successful when:

- ✅ Users can download DMG from GitHub Releases
- ✅ DMG installation is simple (drag to Applications)
- ✅ Harbor checks for updates on launch
- ✅ Update menu item shows correct state
- ✅ Clicking "Update Available" opens GitHub release page
- ✅ Release notes are clear and user-friendly
- ✅ Version numbers are consistent across all touchpoints
- ✅ No user complaints about update frequency/notifications
- ✅ Homebrew cask is available within 2 months of v1.0
