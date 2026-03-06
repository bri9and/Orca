#!/usr/bin/env bash
set -euo pipefail

# ─── Build Jarvis.dmg — macOS disk image installer ──────────────────────────
# Creates a .dmg with Jarvis.app and an alias to /Applications
# for drag-and-drop installation.
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="Jarvis"
APP_DIR="$ROOT_DIR/$APP_NAME.app"
DMG_NAME="Jarvis-2.0"
DMG_PATH="$ROOT_DIR/$DMG_NAME.dmg"
VOLUME_NAME="Jarvis"
STAGING_DIR=$(mktemp -d)

# Check that the .app exists
if [[ ! -d "$APP_DIR" ]]; then
  echo "Error: $APP_DIR not found. Run bin/build-app.sh first."
  exit 1
fi

echo "Building $DMG_NAME.dmg..."

# Clean previous DMG
rm -f "$DMG_PATH"

# ─── Stage contents ──────────────────────────────────────────────────────────
cp -R "$APP_DIR" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# ─── Create background image with install instructions ───────────────────────
BG_DIR="$STAGING_DIR/.background"
mkdir -p "$BG_DIR"

python3 << 'PYBG'
import struct, zlib, os

W, H = 600, 400

def create_png(width, height, pixels):
    def make_chunk(ct, d):
        c = ct + d
        return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    header = b'\x89PNG\r\n\x1a\n'
    ihdr = make_chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
    raw = b''
    for y in range(height):
        raw += b'\x00'
        for x in range(width):
            i = (y * width + x) * 4
            raw += bytes(pixels[i:i+4])
    idat = make_chunk(b'IDAT', zlib.compress(raw, 9))
    iend = make_chunk(b'IEND', b'')
    return header + ihdr + idat + iend

pixels = [0] * (W * H * 4)
for y in range(H):
    for x in range(W):
        i = (y * W + x) * 4
        t = y / H
        r = int(12 + 8 * t)
        g = int(15 + 12 * t)
        b = int(30 + 25 * t)
        pixels[i], pixels[i+1], pixels[i+2], pixels[i+3] = r, g, b, 255

staging = os.environ.get('STAGING_DIR', '/tmp')
with open(os.path.join(staging, '.background', 'bg.png'), 'wb') as f:
    f.write(create_png(W, H, pixels))
print("Background generated.")
PYBG

# ─── Create temporary DMG ───────────────────────────────────────────────────
TEMP_DMG=$(mktemp -u).dmg
hdiutil create -srcfolder "$STAGING_DIR" \
  -volname "$VOLUME_NAME" \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" \
  -format UDRW \
  "$TEMP_DMG" \
  -quiet

# ─── Mount and configure window ─────────────────────────────────────────────
MOUNT_DIR=$(hdiutil attach -readwrite -noverify "$TEMP_DMG" | grep "/Volumes/" | sed 's/.*\/Volumes/\/Volumes/')

# AppleScript to set DMG window appearance
osascript << APPLESCRIPT
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {100, 100, 700, 500}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 96
    set background picture of viewOptions to file ".background:bg.png"
    set position of item "$APP_NAME.app" of container window to {150, 200}
    set position of item "Applications" of container window to {450, 200}
    close
    open
    update without registering applications
    delay 1
    close
  end tell
end tell
APPLESCRIPT

# Ensure it's fully synced
sync

# ─── Unmount ─────────────────────────────────────────────────────────────────
hdiutil detach "$MOUNT_DIR" -quiet

# ─── Compress into final DMG ────────────────────────────────────────────────
hdiutil convert "$TEMP_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG_PATH" \
  -quiet

rm -f "$TEMP_DMG"
rm -rf "$STAGING_DIR"

# Get file size
DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1 | xargs)

echo ""
echo -e "\033[0;32m✓ Built $DMG_NAME.dmg ($DMG_SIZE)\033[0m"
echo ""
echo "  Location: $DMG_PATH"
echo ""
echo "  Double-click to open, then drag Jarvis to Applications."
echo ""
