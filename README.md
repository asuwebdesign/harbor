# Harbor

<p align="center">
  <img src="docs/screenshots/harbor-icon.png?raw=true" width="128" height="128" alt="Harbor Icon">
</p>

<p align="center">
  <strong>A native macOS menubar utility for managing localhost development servers</strong>
</p>

<p align="center">
  <a href="https://github.com/asuwebdesign/harbor/releases/latest">
    <img src="https://img.shields.io/badge/Download-v1.1-blue?style=for-the-badge" alt="Download v1.1">
  </a>
</p>

<p align="center">
  <a href="https://github.com/asuwebdesign/harbor/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License">
  </a>
  <a href="https://github.com/asuwebdesign/harbor">
    <img src="https://img.shields.io/badge/platform-macOS%2014.0%2B-lightgrey.svg" alt="Platform">
  </a>
  <a href="https://github.com/asuwebdesign/harbor">
    <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift 6.0">
  </a>
  <a href="https://github.com/asuwebdesign/harbor/stargazers">
    <img src="https://img.shields.io/github/stars/asuwebdesign/harbor?style=social" alt="GitHub stars">
  </a>
</p>

**[Download the latest .dmg from Releases →](https://github.com/asuwebdesign/harbor/releases/latest)**

Harbor automatically scans your localhost ports, displays active development servers in your menubar, and lets you stop them with a single click.

## Requirements

- macOS 14.0 Sonoma or later
- Compatible with Apple Silicon and Intel Macs

## Features

- 🔍 **Automatic Port Detection** - Scans ports 3000-9000 to find active localhost servers
- 📊 **Rich Metadata** - See process name, working directory, command, uptime, and memory usage for each server
- ⚡ **Quick Actions** - Stop individual ports or all ports with one click
- 🎨 **Native macOS Design** - Fully native SwiftUI app with automatic light/dark mode support
- 🔔 **Badge Count** - Optional menubar badge showing number of active ports
- 🔄 **Automatic Updates** - Built-in update checking via GitHub releases
- 🚀 **Lightweight** - Minimal memory footprint with efficient parallel port scanning
- 🔒 **Secure** - Sandboxed app with minimal permissions required

## Preview

<p align="center">
  <img src="docs/screenshots/harbor-preview.png?raw=true" width="600" alt="Harbor Preview">
</p>

## Installation

### Download (Recommended)

**[Download Harbor.dmg from Releases →](https://github.com/asuwebdesign/harbor/releases/latest)**

1. Open the DMG file
2. Drag Harbor to your Applications folder
3. Launch Harbor from Applications

### First Launch

Since Harbor is distributed outside the Mac App Store, macOS may block it on first launch. To fix this:

**Option 1: Remove quarantine flag (Recommended)**

```bash
xattr -cr /Applications/Harbor.app
```

**Option 2: Manual approval**

1. Right-click Harbor in Applications
2. Select "Open"
3. Click "Open" in the security dialog

You only need to do this once. After the first launch, Harbor will open normally.

### Homebrew

```bash
brew install --cask harbor
```

_Note: Homebrew cask will be available after v1.0 release._

### Building from Source

1. Clone this repository
2. Open `Harbor.xcodeproj` in Xcode 15.0+
3. Build and run (Cmd+R)
4. Harbor will appear in your menubar

## Usage

### Viewing Active Ports

- **Left-click** the Harbor menubar icon to view all active localhost servers
- See project names, port numbers, and process details at a glance

### Stopping Servers

- **Hover** over a port row to reveal the "Stop" button
- **Click "Stop"** to terminate that specific server
- **Click "Stop All"** to terminate all running servers (with confirmation)

### Settings

- **Right-click** the Harbor menubar icon and select "Settings..."
- **Show badge count** - Display the number of active ports in the menubar
- **Launch at login** - Automatically start Harbor when you log in

## Architecture

Harbor is built with:

- **SwiftUI** for native macOS UI
- **MVVM** architecture with Service Layer
- **Swift Concurrency** for parallel port scanning
- **AppKit** for menubar integration (NSStatusItem)
- **Two-stage port detection** - BSD socket test + HTTP verification to identify web servers
- **Smart process detection** - Uses `lsof -sTCP:LISTEN` to identify actual server processes, not client connections

See [Design Document](docs/plans/2026-03-09-harbor-design.md) for detailed architecture information.

## Development

### Running Tests

```bash
# Run all tests
Cmd+U in Xcode

# Or via command line
xcodebuild test -scheme Harbor
```

### Project Structure

```
Harbor/
├── Models/          # Data models (PortInfo, AppSettings)
├── ViewModels/      # Observable view models
├── Views/           # SwiftUI views
├── Services/        # Port scanning and process management
├── Managers/        # Settings persistence
└── Utils/           # Constants and helpers
```

## License

MIT License - see LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
