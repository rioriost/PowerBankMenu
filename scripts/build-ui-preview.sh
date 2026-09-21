#!/bin/sh
# Compile the actual AppKit views with local-only service fixtures.
set -eu
cd "$(dirname "$0")/.."
preview_dir="${TMPDIR:-/tmp}/PowerBankMenu-UIPreview.app"
mkdir -p "$preview_dir/Contents/MacOS" "$preview_dir/Contents/Resources"
cat > "$preview_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>st.rio.PowerBankMenu.UIPreview</string>
<key>CFBundleExecutable</key><string>PowerBankMenu-UIPreview</string>
<key>CFBundleName</key><string>PowerBankMenu UI Preview</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>UI Preview</string>
<key>CFBundleVersion</key><string>1</string>
</dict></plist>
PLIST
cp Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-256.png "$preview_dir/Contents/Resources/preview-icon.png"
cp Sources/Resources/*.strings "$preview_dir/Contents/Resources/"
xcrun swiftc -swift-version 6 -parse-as-library \
    TestingCLI/UIPreview.swift Sources/UI/AccountSettingsWindow.swift \
    Sources/UI/AboutWindow.swift Sources/UI/AppLocalization.swift \
    Sources/UI/MenuItemRenderer.swift Sources/App/StatusBarController.swift \
    Sources/App/SolixAppState.swift \
    -o "$preview_dir/Contents/MacOS/PowerBankMenu-UIPreview"
printf '%s\n' "$preview_dir"
