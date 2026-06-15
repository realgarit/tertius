#!/usr/bin/env bash
#
# Build Tertius.app (universal) with its Info.plist, and codesign it.
#
# Env:  VERSION        (default 0.0.0)
#       SIGN_IDENTITY  (codesign -s identity; empty ⇒ ad-hoc "-")
#       KEYCHAIN       (optional; passed to codesign --keychain)
#       APP_OUTPUT     (default dist/Tertius.app)
#       ARCHS          ("universal" [default] or "native")
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-0.0.0}"
IDENTITY="${SIGN_IDENTITY:-}"
APP="${APP_OUTPUT:-$ROOT/dist/Tertius.app}"
BUNDLE_ID="io.github.realgarit.tertius"

ARCH_FLAGS=(--arch arm64 --arch x86_64)
if [ "${ARCHS:-universal}" = "native" ]; then
  ARCH_FLAGS=()
fi

echo "Building (version $VERSION, ${ARCHS:-universal})…"
swift build -c release ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"} --package-path "$ROOT"
BINDIR="$(swift build -c release ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"} --package-path "$ROOT" --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BINDIR/Tertius" "$APP/Contents/MacOS/Tertius"

# Compile the app icon if an asset catalog is present (M4 onward).
ICON_KEYS=""
ASSETS="$ROOT/Sources/App/Resources/Assets.xcassets"
if [ -d "$ASSETS" ] && command -v actool >/dev/null 2>&1; then
  actool --compile "$APP/Contents/Resources" \
    --app-icon AppIcon \
    --output-partial-info-plist "$APP/Contents/_iconinfo.plist" \
    --platform macosx --minimum-deployment-target 26.0 \
    "$ASSETS" >/dev/null
  rm -f "$APP/Contents/_iconinfo.plist"
  ICON_KEYS="<key>CFBundleIconName</key><string>AppIcon</string><key>CFBundleIconFile</key><string>AppIcon</string>"
fi

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleName</key><string>Tertius</string>
    <key>CFBundleDisplayName</key><string>Tertius</string>
    <key>CFBundleExecutable</key><string>Tertius</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>26.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    $ICON_KEYS
</dict>
</plist>
EOF

plutil -lint "$APP/Contents/Info.plist" >/dev/null

if [ -n "$IDENTITY" ]; then
  codesign --force --sign "$IDENTITY" ${KEYCHAIN:+--keychain "$KEYCHAIN"} "$APP"
else
  codesign --force --sign - "$APP"
fi

codesign -v "$APP" >/dev/null 2>&1 && echo "Signed OK (identity: ${IDENTITY:-ad-hoc})"
echo "Built $APP"
