# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Harbor is a native macOS menubar app for managing localhost development servers. It scans ports 3000-9000, detects active HTTP servers, and provides quick actions to view process details and stop servers.

**Stack**: SwiftUI + AppKit, Swift 6 with strict concurrency, macOS 14.0+

## Build Commands

```bash
# Build the project
cd Harbor
xcodebuild -project Harbor.xcodeproj -scheme Harbor -configuration Debug build

# Clean build
xcodebuild -project Harbor.xcodeproj -scheme Harbor -configuration Debug clean build

# Run tests (Cmd+U in Xcode or):
xcodebuild test -scheme Harbor

# Run the app in Xcode
# Open Harbor.xcodeproj and press Cmd+R
```

## Architecture

### Swift 6 Strict Concurrency

**Critical**: This project uses Swift 6 strict concurrency. All code must properly handle actor isolation:

- **ViewModels**: Always `@MainActor` (e.g., `PortViewModel`, `SettingsViewModel`, `AppStateManager`)
- **Services**: Use `actor` for background work (e.g., `PortScannerService`)
- **Constants**: Mark as `@MainActor` with `nonisolated static` properties to allow cross-actor access
- **Timer closures**: Use `[weak self]` and `MainActor.assumeIsolated` when already on main queue

### NSMenu + SwiftUI Integration Pattern

Harbor uses a **custom NSMenuItem with NSHostingView** approach (NOT NSPopover):

```swift
// Pattern: Embed SwiftUI view in NSMenuItem
class PortMenuItem: NSMenuItem {
    init(portInfo: PortInfo, onOpen: @escaping () -> Void, onOpenInFinder: @escaping () -> Void, onStop: @escaping () -> Void) {
        super.init(title: "", action: nil, keyEquivalent: "")

        let hostingView = NSHostingView(
            rootView: PortMenuItemView(...)
                .padding(.horizontal, 8) // Margins to match native menu items
        )

        hostingView.frame = NSRect(x: 0, y: 0, width: 336, height: 64)
        self.view = hostingView
    }
}
```

**Key Points**:

- Menu is rebuilt on every show (reset `statusItem.menu` to nil after display)
- Use 8px horizontal padding on SwiftUI views to match native menu item margins
- Window centering for modals uses `NSScreen.main.visibleFrame` to calculate absolute center

### Port Scanning Architecture

**Two-stage verification**:

1. BSD socket connection test (50ms timeout)
2. HTTP HEAD request verification (only accept 2xx/3xx responses)

This filters out non-HTTP services that accept socket connections but aren't web servers.

**Self-PID Filtering**: Harbor filters out its own process ID from scan results to prevent the app from killing itself. The `scanPorts()` method excludes `ProcessInfo.processInfo.processIdentifier` from the active ports list.

**Process Metadata Gathering**:

- `pwdx` - Primary method for working directory (more reliable)
- `lsof` - Fallback for working directory, also used for PID lookup
- `ps` - Process name, command args, start time

### String Sanitization

**Required** for all shell command output displayed in UI:

```swift
// PortInfo provides sanitized properties:
portInfo.sanitizedFolderName  // Use this, not .folderName
portInfo.sanitizedCommand      // Use this, not .command
portInfo.sanitizedProcessName  // Use this, not .processName
```

Sanitization removes:

- Control characters (0x00-0x1F, 0x7F)
- ANSI escape sequences
- Excessive whitespace

**Folder Name Format**: The `folderName` property returns **parent/child format** (e.g., "Sites/harbor" not just "harbor"). This shows the last two path components if available. Always use `sanitizedFolderName` in the UI.

### Custom Icons

Icons use SwiftUI `Canvas` with exact SVG path coordinates (not SF Symbols where custom design is needed):

- `AnchorIcon` - Menubar icon (NSImage with NSBezierPath, includes Y-axis flip for SVG coordinate system)
- `FolderIcon`, `StopCircleIcon` - Button icons (SwiftUI Canvas)

**Pattern**: Convert SVG paths to SwiftUI/AppKit drawing commands with proper scaling and coordinate transformation.

### NotificationCenter Events

Cross-component communication:

- `"PortsDidUpdate"` - Triggers menu rebuild and badge update
- `"SettingsDidUpdate"` - Triggers badge update

Posted from ViewModels, observed in `AppDelegate` with `MainActor.assumeIsolated` (observers run on main queue).

## Key Files

- `Harbor/HarborApp.swift` - App entry point, menubar setup, menu building
- `Harbor/Services/PortScannerService.swift` - Actor-based port scanning with HTTP verification
- `Harbor/ViewModels/PortViewModel.swift` - Port list management with auto-refresh
- `Harbor/Views/PortMenuItemView.swift` - Custom menu item with hover actions
- `Harbor/Models/PortInfo.swift` - Port metadata with sanitization helpers
- `Harbor/Utils/Constants.swift` - App-wide constants (must be @MainActor with nonisolated statics)

## Development Notes

### Testing Changes

Run a local dev server to test:

```bash
# In another project directory
npm run dev  # or equivalent

# Harbor should detect it within 5 seconds
```

### Common Issues

**Actor isolation errors**: Check that:

- ViewModels are marked `@MainActor`
- Constants enum is `@MainActor` with `nonisolated static` properties
- Timer closures use `[weak self]` and avoid direct property access
- @objc methods calling async code must use `Task { @MainActor in ... }` not just `Task { ... }`

**Special characters in UI**: Always use sanitized properties from `PortInfo` (e.g., `sanitizedFolderName` not `folderName`)

**Menu not updating**: Ensure `statusItem.menu` is set to `nil` after menu display to allow rebuild on next show

**Windows not centered**: Use `NSScreen.main.visibleFrame` to calculate center position, set `frameOrigin` explicitly
