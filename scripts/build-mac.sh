#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ "$(uname -s)" == Darwin ]] || { echo 'macOS 14+ and Xcode 15+ required' >&2; exit 1; }
npm ci --no-audit --no-fund
npm run build
(cd apps/mac && swift build -c release --jobs 3)
BUNDLE="$PWD/build/Forge Remote.app"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp apps/mac/.build/release/ForgeRemote "$BUNDLE/Contents/MacOS/ForgeRemote"
mkdir -p "$BUNDLE/Contents/Resources/web"
rsync -a --delete apps/web/dist/ "$BUNDLE/Contents/Resources/web/"
cat > "$BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleIdentifier</key><string>dev.forgeremote.companion</string><key>CFBundleName</key><string>Forge Remote</string><key>CFBundleExecutable</key><string>ForgeRemote</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleShortVersionString</key><string>0.1.0</string><key>CFBundleVersion</key><string>1</string><key>LSMinimumSystemVersion</key><string>14.0</string><key>LSUIElement</key><true/><key>NSScreenCaptureUsageDescription</key><string>Show your screen to your explicitly paired iPhone.</string></dict></plist>
PLIST
codesign --force --sign "${FORGE_SIGN_IDENTITY:--}" "$BUNDLE"
printf 'Built %s\n' "$BUNDLE"
