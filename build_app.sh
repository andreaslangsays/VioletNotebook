#!/bin/bash
set -e

echo "=== 1. VioletNotebook in Release-Modus bauen ==="
swift build -c release

echo "=== 2. App-Bundle-Struktur erstellen ==="
APP_DIR="build/VioletNotebook.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

echo "=== 3. Executable kopieren ==="
cp .build/release/VioletNotebook "$APP_DIR/Contents/MacOS/"

echo "=== 4. Info.plist erstellen ==="
cat <<EOF > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>VioletNotebook</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>de.andreas.VioletNotebook</string>
    <key>CFBundleName</key>
    <string>VioletNotebook</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF

echo "=== 5. App Logo (.icns) aus JPG generieren ==="
ICONSET="build/AppIcon.iconset"
mkdir -p "$ICONSET"

# Konvertiere JPG nach PNG für die Weiterverarbeitung
sips -s format png Resources/AppIcon.jpg --out "build/AppIcon.png" > /dev/null

# Erstelle die verschiedenen Auflösungen für das macOS App Icon
sips -z 16 16     "build/AppIcon.png" --out "$ICONSET/icon_16x16.png" > /dev/null
sips -z 32 32     "build/AppIcon.png" --out "$ICONSET/icon_16x16@2x.png" > /dev/null
sips -z 32 32     "build/AppIcon.png" --out "$ICONSET/icon_32x32.png" > /dev/null
sips -z 64 64     "build/AppIcon.png" --out "$ICONSET/icon_32x32@2x.png" > /dev/null
sips -z 128 128   "build/AppIcon.png" --out "$ICONSET/icon_128x128.png" > /dev/null
sips -z 256 256   "build/AppIcon.png" --out "$ICONSET/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "build/AppIcon.png" --out "$ICONSET/icon_256x256.png" > /dev/null
sips -z 512 512   "build/AppIcon.png" --out "$ICONSET/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "build/AppIcon.png" --out "$ICONSET/icon_512x512.png" > /dev/null
sips -z 1024 1024 "build/AppIcon.png" --out "$ICONSET/icon_512x512@2x.png" > /dev/null

# .icns Datei kompilieren
iconutil -c icns "$ICONSET" -o "$APP_DIR/Contents/Resources/AppIcon.icns"

# Aufräumen von temporären Icon-Dateien
rm -rf "$ICONSET" "build/AppIcon.png"

echo "=== Fertig! ==="
echo "Die App wurde erfolgreich unter '$(pwd)/$APP_DIR' erstellt."
echo "Du kannst die App nun per Doppelklick starten oder in deinen Programme-Ordner (/Applications) verschieben!"
