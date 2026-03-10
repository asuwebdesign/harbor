# Harbor

<p align="center">
  <img src="https://github.com/asuwebdesign/harbor/blob/main/Harbor/Harbor/Assets.xcassets/AppIcon.appiconset/harbor-app-icon-512-2x.png?raw=true" width="128" height="128" alt="Harbor Icon" style="border-radius: 20%;">
</p>

A native macOS menubar utility for managing localhost development servers.

## Features

- 🔍 **Automatic Port Detection** - Scans ports 3000-9000 to find active localhost servers
- 📊 **Rich Metadata** - See process name, working directory, command, and uptime for each server
- ⚡ **Quick Actions** - Stop individual ports or all ports with one click
- 🎨 **Native macOS Design** - Fully native SwiftUI app with automatic light/dark mode support
- 🔔 **Badge Count** - Optional menubar badge showing number of active ports
- 🚀 **Lightweight** - Minimal memory footprint with efficient parallel port scanning
- 🔒 **Secure** - Sandboxed app with minimal permissions required

## Installation

### Download (Recommended)

1. Download the latest release from [Releases](https://github.com/asuwebdesign/harbor/releases)
2. Open the DMG and drag Harbor to your Applications folder
3. Launch Harbor from Applications

Harbor automatically checks for updates on launch and will notify you when new versions are available.

### Homebrew

```bash
brew install --cask harbor
```

_Note: Homebrew cask will be available after the first stable release._

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
