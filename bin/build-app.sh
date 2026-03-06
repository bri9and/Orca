#!/usr/bin/env bash
set -euo pipefail

# ─── Build Jarvis.app — macOS AppleScript application ────────────────────────
# Creates a standalone .app bundle that launches the dashboard server
# and opens it in the default browser.
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="Jarvis"
APP_DIR="$ROOT_DIR/$APP_NAME.app"

echo "Building $APP_NAME.app..."

# Clean previous build
rm -rf "$APP_DIR"

# ─── Create the bash launcher script in a temp location ──────────────────────
LAUNCHER_SCRIPT=$(mktemp)
cat > "$LAUNCHER_SCRIPT" << LAUNCHER
#!/usr/bin/env bash
set -euo pipefail

DASHBOARD_DIR="$ROOT_DIR/dashboard"
PORT=3001
LOG_FILE="\$HOME/.jarvis.log"
PID_FILE="\$HOME/.jarvis.pid"

# Source user profile for PATH, node, npm, env vars
if [[ -f "\$HOME/.zprofile" ]]; then
  source "\$HOME/.zprofile" 2>/dev/null || true
fi
if [[ -f "\$HOME/.zshrc" ]]; then
  source "\$HOME/.zshrc" 2>/dev/null || true
fi

# Check if already running
if [[ -f "\$PID_FILE" ]]; then
  EXISTING_PID=\$(cat "\$PID_FILE")
  if kill -0 "\$EXISTING_PID" 2>/dev/null; then
    open "http://localhost:\$PORT"
    exit 0
  else
    rm -f "\$PID_FILE"
  fi
fi

# Preflight: check node
if ! command -v node &>/dev/null; then
  osascript -e 'display dialog "Node.js is not installed.\n\nInstall it from https://nodejs.org or:\n  brew install node" buttons {"OK"} default button "OK" with title "Jarvis" with icon stop'
  exit 1
fi

# Preflight: check dashboard
if [[ ! -d "\$DASHBOARD_DIR" ]]; then
  osascript -e 'display dialog "Dashboard not found.\n\nRun: git submodule update --init" buttons {"OK"} default button "OK" with title "Jarvis" with icon stop'
  exit 1
fi

# Install deps if needed
if [[ ! -d "\$DASHBOARD_DIR/node_modules" ]]; then
  cd "\$DASHBOARD_DIR" && npm install >> "\$LOG_FILE" 2>&1
fi

# Clean stale lock
rm -f "\$DASHBOARD_DIR/.next/dev/lock"

# Start the server in background
cd "\$DASHBOARD_DIR"
npx next dev --port "\$PORT" >> "\$LOG_FILE" 2>&1 &
SERVER_PID=\$!
echo "\$SERVER_PID" > "\$PID_FILE"

# Wait for server to be ready (up to 30s)
for i in {1..60}; do
  if curl -s "http://localhost:\$PORT" > /dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

# Open browser
open "http://localhost:\$PORT"

# Keep running — clean up on exit
cleanup() {
  if [[ -f "\$PID_FILE" ]]; then
    kill \$(cat "\$PID_FILE") 2>/dev/null || true
    rm -f "\$PID_FILE"
  fi
  exit 0
}
trap cleanup SIGINT SIGTERM EXIT
wait "\$SERVER_PID" 2>/dev/null || true
LAUNCHER

# ─── Build .app using osacompile ─────────────────────────────────────────────
# osacompile creates a proper macOS app bundle with a compiled executable
osacompile -o "$APP_DIR" -e "
  set launcherPath to \"$ROOT_DIR/bin/jarvis-app-launcher.sh\"
  do shell script \"bash \" & quoted form of launcherPath & \" &\"
"

# Move the launcher script to its permanent location
cp "$LAUNCHER_SCRIPT" "$ROOT_DIR/bin/jarvis-app-launcher.sh"
chmod +x "$ROOT_DIR/bin/jarvis-app-launcher.sh"
rm -f "$LAUNCHER_SCRIPT"

# ─── Custom Info.plist ────────────────────────────────────────────────────────
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Jarvis</string>
    <key>CFBundleDisplayName</key>
    <string>Jarvis</string>
    <key>CFBundleIdentifier</key>
    <string>com.jarvis.orchestrator</string>
    <key>CFBundleVersion</key>
    <string>2.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>applet</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
PLIST

# Remove the default applet.icns
rm -f "$APP_DIR/Contents/Resources/applet.icns"

# ─── Generate app icon ────────────────────────────────────────────────────────
ICON_DIR=$(mktemp -d)
export ICON_DIR

python3 << 'PYICON'
import struct, zlib, os, math

size = 512

def create_png(width, height, pixels):
    def make_chunk(chunk_type, data):
        chunk = chunk_type + data
        return struct.pack('>I', len(data)) + chunk + struct.pack('>I', zlib.crc32(chunk) & 0xffffffff)
    header = b'\x89PNG\r\n\x1a\n'
    ihdr = make_chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'
        for x in range(width):
            idx = (y * width + x) * 4
            raw_data += bytes(pixels[idx:idx+4])
    idat = make_chunk(b'IDAT', zlib.compress(raw_data, 9))
    iend = make_chunk(b'IEND', b'')
    return header + ihdr + idat + iend

pixels = [0] * (size * size * 4)
cx, cy = size // 2, size // 2

for y in range(size):
    for x in range(size):
        idx = (y * size + x) * 4
        dx, dy = x - cx, y - cy
        dist = math.sqrt(dx*dx + dy*dy)
        r, g, b, a = 0, 0, 0, 0

        # Background circle
        if dist < 240:
            a = 255
            t = dist / 240
            r = int(5 + 15 * t)
            g = int(8 + 20 * t)
            b = int(25 + 40 * t)
            if dist > 200:
                glow = (dist - 200) / 40
                r = int(r + 30 * glow)
                g = int(g + 80 * glow)
                b = int(b + 120 * glow)
        elif dist < 250:
            a = int(255 * (1 - (dist - 240) / 10))
            r, g, b = 20, 40, 80

        # Sun
        if dist < 35:
            a = 255
            t = dist / 35
            r = int(255 - 30 * t)
            g = int(200 - 60 * t)
            b = int(50 + 20 * t)
        elif dist < 50:
            glow = 1 - (dist - 35) / 15
            if a < 255: a = 255
            r = int(min(255, r + 255 * glow * 0.3))
            g = int(min(255, g + 180 * glow * 0.3))
            b = int(min(255, b + 50 * glow * 0.1))

        # Orbital rings
        for radius, opacity in [(80, 0.15), (130, 0.15), (185, 0.15)]:
            ring_dist = abs(dist - radius)
            if ring_dist < 1.5:
                ra = opacity * (1 - ring_dist / 1.5)
                r = int(min(255, r + 100 * ra))
                g = int(min(255, g + 160 * ra))
                b = int(min(255, b + 255 * ra))

        # Mercury
        mx, my = cx + 80 * math.cos(math.radians(45)), cy + 80 * math.sin(math.radians(45))
        if math.sqrt((x-mx)**2 + (y-my)**2) < 8: a, r, g, b = 255, 180, 120, 200
        # Earth
        ex, ey = cx + 130 * math.cos(math.radians(160)), cy + 130 * math.sin(math.radians(160))
        if math.sqrt((x-ex)**2 + (y-ey)**2) < 14: a, r, g, b = 255, 70, 140, 220
        # Mars
        rx2, ry2 = cx + 185 * math.cos(math.radians(280)), cy + 185 * math.sin(math.radians(280))
        if math.sqrt((x-rx2)**2 + (y-ry2)**2) < 11: a, r, g, b = 255, 220, 90, 60

        # Stars
        for sx, sy in [(100,50),(400,80),(60,350),(420,400),(250,30),(450,250),(30,150),(470,130),(380,450),(120,440),(200,460),(350,30),(50,250),(460,350),(300,470)]:
            sd = math.sqrt((x-sx)**2 + (y-sy)**2)
            if sd < 2 and dist < 235:
                br = 1 - sd/2
                r = int(min(255, r + 200*br)); g = int(min(255, g + 200*br)); b = int(min(255, b + 220*br))
                if a < 200: a = 255

        pixels[idx] = min(255, max(0, r))
        pixels[idx+1] = min(255, max(0, g))
        pixels[idx+2] = min(255, max(0, b))
        pixels[idx+3] = min(255, max(0, a))

icon_dir = os.environ['ICON_DIR']
for s in [512, 256, 128, 32, 16]:
    scale = size // s
    p = [0] * (s * s * 4)
    for y in range(s):
        for x in range(s):
            src = (y * scale * size + x * scale) * 4
            dst = (y * s + x) * 4
            p[dst:dst+4] = pixels[src:src+4]
    with open(os.path.join(icon_dir, f'icon_{s}x{s}.png'), 'wb') as f:
        f.write(create_png(s, s, p))

print("Icons generated.")
PYICON

# Build .iconset and convert to .icns
ICONSET="$ICON_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"
cp "$ICON_DIR/icon_16x16.png"   "$ICONSET/icon_16x16.png"
cp "$ICON_DIR/icon_32x32.png"   "$ICONSET/icon_16x16@2x.png"
cp "$ICON_DIR/icon_32x32.png"   "$ICONSET/icon_32x32.png"
cp "$ICON_DIR/icon_128x128.png" "$ICONSET/icon_32x32@2x.png"
cp "$ICON_DIR/icon_128x128.png" "$ICONSET/icon_128x128.png"
cp "$ICON_DIR/icon_256x256.png" "$ICONSET/icon_128x128@2x.png"
cp "$ICON_DIR/icon_256x256.png" "$ICONSET/icon_256x256.png"
cp "$ICON_DIR/icon_512x512.png" "$ICONSET/icon_256x256@2x.png"
cp "$ICON_DIR/icon_512x512.png" "$ICONSET/icon_512x512.png"
cp "$ICON_DIR/icon_512x512.png" "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$APP_DIR/Contents/Resources/AppIcon.icns"
rm -rf "$ICON_DIR"

echo ""
echo -e "\033[0;32m✓ Built $APP_NAME.app successfully!\033[0m"
echo ""
echo "  Location: $APP_DIR"
echo ""
echo "  To install to Applications:"
echo "    cp -r $APP_DIR /Applications/"
echo ""
echo "  Or just double-click Jarvis.app to launch!"
echo ""
