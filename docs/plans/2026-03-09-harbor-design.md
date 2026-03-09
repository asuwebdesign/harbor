# Harbor Design Document

**Date:** March 9, 2026
**Status:** Approved

## Overview

Harbor is a native macOS menubar utility app that helps developers manage localhost development servers. It provides a clean GUI to view and control active ports without using the terminal.

## Problem Statement

Developers frequently run multiple localhost applications on different ports. Determining which ports are in use and managing these processes requires terminal commands (`lsof`, `netstat`, `kill`) which can be intimidating for non-technical users or cumbersome for those who prefer a GUI.

## Solution

Harbor lives in the macOS menubar and provides a popover interface showing all active localhost ports (3000-9000) with relevant metadata. Users can stop individual ports or all ports with simple click actions.

## Technology Stack

**SwiftUI + Swift** for native macOS development:

- Native look and feel with automatic theme support
- Built-in menubar app support (NSStatusItem)
- Lightweight and performant
- Modern Apple development approach

## Architecture

**MVVM with Service Layer**

```
Harbor/
├── HarborApp.swift                    # App entry point, menubar setup
├── Models/
│   ├── PortInfo.swift                 # Data model for port information
│   └── AppSettings.swift              # Settings model
├── ViewModels/
│   ├── PortViewModel.swift            # Main business logic & state
│   └── SettingsViewModel.swift        # Settings state management
├── Views/
│   ├── PopoverView.swift              # Main popover content
│   ├── PortRowView.swift              # Individual port list item
│   ├── SettingsView.swift             # Settings window
│   └── EmptyStateView.swift           # "No ports active" state
├── Services/
│   ├── PortScannerService.swift       # Port detection logic
│   └── ProcessService.swift           # Process management (kill)
├── Managers/
│   └── AppStateManager.swift          # UserDefaults, app state
├── Utils/
│   └── Constants.swift                # Port range, refresh interval
└── Assets.xcassets/                   # App icon, menubar icons
```

**Key Architecture Decisions:**

- `HarborApp.swift` creates `NSStatusItem` for menubar presence
- `PortViewModel` is `@Observable` (SwiftUI's modern state management)
- `PortScannerService` uses Swift Concurrency (async/await with TaskGroup) for parallel port scanning
- `ProcessService` handles `kill()` system calls safely
- All settings persist via `AppStateManager` wrapping UserDefaults

## Data Models

```swift
struct PortInfo: Identifiable {
    let id = UUID()
    let port: Int
    let pid: Int
    let processName: String
    let workingDirectory: String
    let command: String
    let startTime: Date
}

struct AppSettings {
    var showBadgeCount: Bool = true
    var launchAtLogin: Bool = false
}
```

## Application Flow

### 1. App Launch

- `HarborApp` creates `NSStatusItem` in menubar
- Initializes `PortViewModel`
- Starts background timer (5-second scan interval)
- Loads settings from `AppStateManager`

### 2. Background Scanning (every 5 seconds)

- Timer triggers `PortViewModel.scanPorts()`
- ViewModel calls `PortScannerService.scanPortRange(3000...9000)`
- Service uses Swift TaskGroup to check ports in parallel
- Results update ViewModel's `@Published var activePorts: [PortInfo]`
- SwiftUI automatically updates badge count if enabled

### 3. User Opens Popover (left-click menubar)

- Popover shows `PopoverView` bound to ViewModel
- **If `activePorts.isEmpty`**: Shows `EmptyStateView` with friendly message:
  - Icon: Harbor/anchor illustration
  - Headline: "All quiet in the harbor"
  - Subtext: "No localhost servers are currently running"
- **If ports active**: Shows scrollable list of `PortRowView` items
- Fresh scan triggered immediately for accuracy

### 4. User Stops a Port

- User taps "Stop" on port row
- ViewModel calls `ProcessService.killProcess(pid: Int)`
- Service executes `kill(pid, SIGTERM)`
- Next scan (within 5s) updates the list automatically

### 5. User Right-clicks Menubar

- Shows `NSMenu` with: Settings, About, Quit
- Settings opens `SettingsView` window

### 6. User Stops All Ports

- User clicks "Stop All" button
- Confirmation dialog appears: "Stop all X running servers?"
- Lists project names in alert body
- Buttons: "Cancel" (default), "Stop All" (destructive style)
- If confirmed, kills all processes sequentially

## UI/UX Design

### Menubar Icon

- SF Symbol-based icon (harbor/port themed)
- Template rendering mode for automatic light/dark theme adaptation
- When `showBadgeCount` enabled: overlay number badge (macOS native style)
- Badge shows count only when > 0

### Popover Design

- Width: 320px, height: dynamic (min 200px, max 500px)
- Padding: 12px all around
- Background: System standard popover material (auto adapts to light/dark)

### Port Row Layout

**Default state:**

```
┌────────────────────────────────────┐
│ my-app                  Port 3000  │
│ ~/projects/my-app                  │
│ node • npm run dev • 2h 34m        │
└────────────────────────────────────┘
```

**On hover:**

```
┌────────────────────────────────────┐
│ my-app            Port 3000 [Stop] │
│ ~/projects/my-app                  │
│ node • npm run dev • 2h 34m        │
└────────────────────────────────────┘
```

**Visual Hierarchy:**

- **Line 1**:
  - Primary: Parent folder name (17pt bold, primary text color)
  - Secondary: "Port 3000" (13pt regular, secondary text color, right-aligned)
  - On hover: [Stop] button appears after port number with smooth fade-in
- **Line 2**: Full path (12pt, tertiary color, truncated with ellipsis if needed)
- **Line 3**: Process • Command • Uptime (11pt, tertiary color)
- Row separators between items
- Subtle background highlight on hover (system standard)

### Popover Footer

- "Stop All" button (centered, secondary button style)
- Only visible when `activePorts.count > 1`

### Empty State

- Centered harbor/anchor icon
- Headline: "All quiet in the harbor"
- Subtext: "No localhost servers are currently running"
- Calm, friendly design matching macOS aesthetic

### Settings Window

- Standard macOS preferences window (300x150px)
- Two toggle switches:
  - "Show badge count in menubar"
  - "Launch Harbor at login"
- Native SwiftUI `Toggle` controls
- Changes save immediately via AppStateManager

## Port Scanning Implementation

### Strategy

Port range: **3000-9000** (6,000 ports)

**Performance Optimizations:**

- Parallel scanning with Swift Concurrency (async/await + TaskGroup)
- BSD sockets for native port detection
- Smart caching - cache results between scans
- Background queue for scanning, main thread for UI updates
- Socket connection timeout: 50ms per port (fast fail for closed ports)

### High-Level Approach

```swift
func scanPortRange(_ range: ClosedRange<Int>) async -> [PortInfo] {
    await withTaskGroup(of: PortInfo?.self) { group in
        for port in range {
            group.addTask { await checkPort(port) }
        }

        return await group.compactMap { $0 }
    }
}
```

### Metadata Gathering

For each active port:

1. **Port & PID**: Use `lsof -i :PORT -t` to get process ID listening on the port
2. **Process name**: Parse from `ps -p PID -o comm=`
3. **Working directory**: Get from `lsof -p PID -Fn` (current working directory)
4. **Command**: Full command from `ps -p PID -o args=`
5. **Start time**: Process start time from `ps -p PID -o lstart=`

**Performance Expectations:**

- Full scan of 3000-9000: ~500ms-1s on modern Mac
- Typical case with 3-5 active ports: imperceptible to user
- Only active ports trigger metadata gathering (expensive shell commands)

## Error Handling

### Permission Issues

- If `lsof` or `ps` fails for a PID, show graceful fallback:
  - Process name: "Unknown"
  - Working directory: "Unknown"
  - Still show port number and allow stop action

### Process Termination

- Use `SIGTERM` (graceful shutdown) for kill operations
- Handle case where process exits between scan and kill attempt (silently succeed)

### Invalid Data

- If working directory path is inaccessible, show just the folder name
- If command string is empty, show just process name
- Uptime calculation handles processes started before Harbor launched

### Scan Failures

- If entire scan fails (rare), keep showing last successful results
- Add small error indicator in popover footer: "Last updated X seconds ago"
- Auto-retry on next interval

### Multiple Processes on Same Port

- Should be impossible, but if detected, show the first/primary process
- Log anomaly for debugging

### Stop All Confirmation

- Standard macOS alert: "Stop all X running servers?"
- Buttons: "Cancel" (default), "Stop All" (destructive style)
- Lists project names in alert body

## Security & Safety

### Process Kill Safety

- Only kill processes owned by current user (verified via PID owner check)
- Never allow killing system processes or processes owned by root
- Validate PID exists before attempting kill operation
- Use `kill()` system call directly (safer than shell execution)

### Port Range Restriction

- Fixed range 3000-9000 prevents scanning privileged ports (<1024)
- No arbitrary port scanning capability
- Localhost only - never scan network interfaces

### Data Privacy

- All scanning happens locally, no network calls
- No telemetry, analytics, or data collection
- Settings stored in standard UserDefaults (sandboxed)
- No file system access beyond reading process info

### Sandboxing

- App Sandbox enabled in Xcode project
- Required entitlements:
  - `com.apple.security.network.client` (for socket operations)
  - `com.apple.security.files.user-selected.read-only` (for displaying paths)
- No outbound network access needed
- No unnecessary entitlements requested

### Code Injection Prevention

- All shell commands use Process() with explicit arguments (no shell interpolation)
- Never execute user-provided strings
- PID validation before any operations

## Settings (v1)

**Minimal Settings:**

- Show badge count (toggle) - default: ON
- Launch at login (toggle) - default: OFF

Settings are accessible via:

- Right-click menubar icon → "Settings..."
- Opens standard macOS preferences window

## Future Enhancements (Post v1)

Not in scope for initial release, but potential additions:

- Custom port ranges
- Grouped view by project/folder
- Search/filter functionality
- Custom refresh intervals
- SIGKILL option if SIGTERM fails
- Click port to open in browser
- Process resource usage (CPU/memory)
- Git branch detection
- Export running ports list

## Success Criteria

Harbor v1 is successful when:

- ✅ Menubar icon appears and shows active port count
- ✅ Popover displays all active ports in range 3000-9000
- ✅ Port metadata is accurate (folder, process, command, uptime)
- ✅ Single port stop works instantly
- ✅ Stop All shows confirmation and kills all processes
- ✅ Settings persist between launches
- ✅ App is lightweight (<10MB memory footprint)
- ✅ Full port scan completes in <1 second
- ✅ Native macOS look and feel with theme support
- ✅ Zero-state is friendly and informative
