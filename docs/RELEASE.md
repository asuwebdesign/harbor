# Harbor Release Guide

This document outlines the process for creating a new Harbor release.

## Version 1.0 Release Checklist

### Pre-Release

- [x] Version set to 1.0 in Xcode (MARKETING_VERSION)
- [x] Update checking implemented via GitHub API
- [x] README updated with download instructions and First Launch section
- [x] Memory usage metrics added to port display
- [x] Settings redesigned with macOS-style toggles
- [ ] Test all features on clean macOS install
- [ ] Verify update checking works
- [ ] Take screenshots for README/release notes

### Building the Release

1. **Clean Build in Release Mode**

   ```bash
   cd Harbor
   xcodebuild -project Harbor.xcodeproj -scheme Harbor -configuration Release clean build
   ```

2. **Archive the App**
   - In Xcode: Product → Archive
   - Organizer window will open
   - Select the archive → Distribute App
   - Choose "Copy App" (no code signing)
   - Export to a folder (e.g., `~/Desktop/Harbor-v1.0`)

3. **Create DMG**

   **Option A: Manual DMG Creation**

   ```bash
   # Create temporary folder for DMG contents
   mkdir -p ~/Desktop/Harbor-DMG
   cp -R ~/Desktop/Harbor-v1.0/Harbor.app ~/Desktop/Harbor-DMG/

   # Create symbolic link to Applications
   ln -s /Applications ~/Desktop/Harbor-DMG/Applications

   # Create DMG
   hdiutil create -volname "Harbor" -srcfolder ~/Desktop/Harbor-DMG -ov -format UDZO ~/Desktop/Harbor-1.0.dmg

   # Clean up
   rm -rf ~/Desktop/Harbor-DMG
   ```

   **Option B: Using create-dmg tool** (recommended)

   ```bash
   # Install if needed
   brew install create-dmg

   # Create professional DMG with window customization
   create-dmg \
     --volname "Harbor" \
     --volicon "Harbor/Harbor/Assets.xcassets/AppIcon.appiconset/harbor-app-icon-512-2x.png" \
     --window-pos 200 120 \
     --window-size 600 400 \
     --icon-size 100 \
     --icon "Harbor.app" 175 120 \
     --hide-extension "Harbor.app" \
     --app-drop-link 425 120 \
     "Harbor-1.0.dmg" \
     "~/Desktop/Harbor-v1.0/"
   ```

### Creating the GitHub Release

1. **Prepare Release Notes**

   Create `docs/releases/v1.0.md`:

   ````markdown
   # Harbor 1.0 - Initial Release

   First stable release of Harbor, a native macOS menubar utility for managing localhost development servers.

   ## Features

   - 🔍 Automatic port detection (ports 3000-9000)
   - 📊 Rich metadata: process name, directory, command, uptime, and memory usage
   - ⚡ Quick actions: stop individual or all servers
   - 🎨 Native SwiftUI with light/dark mode
   - 🔔 Optional menubar badge count
   - 🔄 Automatic update checking
   - 🚀 Lightweight and efficient

   ## System Requirements

   - macOS 14.0 Sonoma or later
   - Compatible with Apple Silicon and Intel Macs

   ## Installation

   1. Download `Harbor-1.0.dmg`
   2. Open the DMG and drag Harbor to Applications
   3. Launch Harbor from Applications

   ### First Launch

   macOS may block Harbor on first launch. Run this command once:

   ```bash
   xattr -cr /Applications/Harbor.app
   ```
   ````

   Then right-click Harbor and select Open.

   ## Known Issues

   None currently. Please report issues at https://github.com/asuwebdesign/harbor/issues

   ```

   ```

2. **Create Git Tag**

   ```bash
   git tag -a v1.0 -m "Harbor 1.0 - Initial Release"
   git push origin v1.0
   ```

3. **Create GitHub Release**
   - Go to https://github.com/asuwebdesign/harbor/releases/new
   - Select tag: `v1.0`
   - Title: `Harbor 1.0 - Initial Release`
   - Description: Copy content from `docs/releases/v1.0.md`
   - Upload: `Harbor-1.0.dmg`
   - Check "Set as the latest release"
   - Click "Publish release"

### Post-Release

1. **Test Download**
   - Download DMG from GitHub release page
   - Verify installation process
   - Test first launch with quarantine flag
   - Verify update checking works (should say "You're up to date")

2. **Update README Badges**
   - Release badge should automatically update
   - Verify download link works

3. **Announce Release**
   - Twitter/X
   - Reddit (r/macapps, r/webdev)
   - Hacker News (Show HN)
   - Product Hunt (optional)

## Future Releases

For subsequent releases (1.1, 1.2, etc.):

1. Update MARKETING_VERSION in Xcode
2. Update CHANGELOG.md with new features/fixes
3. Follow the same build/DMG/release process
4. Users with v1.0 will automatically be notified of updates

## Troubleshooting

### DMG won't mount

- Verify DMG integrity: `hdiutil verify Harbor-1.0.dmg`
- Recreate with different compression: Use `-format UDRW` for testing

### App crashes on launch

- Check for proper code signing (even without Developer ID)
- Verify all dependencies are included
- Test on clean VM or different Mac

### Update checking fails

- Verify GitHub API rate limits (60 requests/hour unauthenticated)
- Check that tag format is `vX.Y` (e.g., `v1.0`)
- Ensure release is published (not draft)
