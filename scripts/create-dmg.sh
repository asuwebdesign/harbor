#!/bin/bash
set -e

# Harbor DMG Creation Script
# Usage: ./scripts/create-dmg.sh <version> <app-path>
# Example: ./scripts/create-dmg.sh 1.0 ~/Desktop/Harbor-v1.0/Harbor.app

VERSION=${1:-"1.0"}
APP_PATH=${2:-""}

if [ -z "$APP_PATH" ]; then
    echo "Error: Please provide path to Harbor.app"
    echo "Usage: $0 <version> <app-path>"
    echo "Example: $0 1.0 ~/Desktop/Harbor-v1.0/Harbor.app"
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

echo "Creating Harbor v$VERSION DMG..."

# Create temporary folder for DMG contents
DMG_FOLDER=$(mktemp -d)
echo "Using temporary folder: $DMG_FOLDER"

# Copy app to temp folder
cp -R "$APP_PATH" "$DMG_FOLDER/"

# Create symbolic link to Applications
ln -s /Applications "$DMG_FOLDER/Applications"

# Output DMG path
OUTPUT_DMG="Harbor-${VERSION}.dmg"

# Remove existing DMG if it exists
if [ -f "$OUTPUT_DMG" ]; then
    echo "Removing existing DMG: $OUTPUT_DMG"
    rm "$OUTPUT_DMG"
fi

# Create DMG
echo "Creating DMG..."
hdiutil create \
    -volname "Harbor" \
    -srcfolder "$DMG_FOLDER" \
    -ov \
    -format UDZO \
    "$OUTPUT_DMG"

# Clean up
echo "Cleaning up temporary folder..."
rm -rf "$DMG_FOLDER"

# Verify DMG
echo "Verifying DMG..."
hdiutil verify "$OUTPUT_DMG"

echo ""
echo "✅ DMG created successfully: $OUTPUT_DMG"
echo ""
echo "Next steps:"
echo "1. Test the DMG: hdiutil mount $OUTPUT_DMG"
echo "2. Create git tag: git tag -a v$VERSION -m 'Harbor $VERSION'"
echo "3. Push tag: git push origin v$VERSION"
echo "4. Create GitHub release and upload $OUTPUT_DMG"
