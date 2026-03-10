#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "🚀 开始构建 ClipboardTool..."

if ! command -v xcodegen &> /dev/null; then
    echo "📦 安装 XcodeGen..."
    brew install xcodegen
fi

if [ ! -f "icon.png" ]; then
    echo "❌ 图标文件 icon.png 不存在！"
    exit 1
fi

echo "📋 生成 Xcode 项目..."
xcodegen generate

echo "🔨 构建项目..."
xcodebuild -project ClipboardTool.xcodeproj \
    -scheme ClipboardTool \
    -configuration Release \
    -destination 'platform=macOS' \
    build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

BUILD_PRODUCTS_DIR=$(find ~/Library/Developer/Xcode/DerivedData/ClipboardTool-* -name "苹果剪切板.app" -type d | head -1)

if [ -z "$BUILD_PRODUCTS_DIR" ]; then
    echo "❌ 找不到构建产物"
    exit 1
fi

echo "📦 打包应用到开发目录..."
cp -f "$BUILD_PRODUCTS_DIR/Contents/Resources/icon.png" ./ 2>/dev/null || true

APP_PATH="./ClipboardTool.app"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

cp -f "$BUILD_PRODUCTS_DIR/Contents/MacOS/苹果剪切板" "$APP_PATH/Contents/MacOS/"
cp -f "$BUILD_PRODUCTS_DIR/Contents/Resources/icon.png" "$APP_PATH/Contents/Resources/" 2>/dev/null || true
cp -f "$BUILD_PRODUCTS_DIR/Info.plist" "$APP_PATH/Contents/" 2>/dev/null || true

cat > "$APP_PATH/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>苹果剪切板</string>
    <key>CFBundleIconFile</key>
    <string>icon.png</string>
    <key>CFBundleIdentifier</key>
    <string>com.clipboardtool.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>剪贴板工具</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 ClipboardTool. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <true/>
    <key>SMAppService</key>
    <dict>
        <key>Status2</key>
        <string>Enabled</string>
    </dict>
</dict>
</plist>
EOF

chmod +x "$APP_PATH/Contents/MacOS/苹果剪切板"

echo "✅ 构建成功！"
echo ""
echo "📱 应用位置: $APP_PATH"
echo ""
echo "💡 使用说明："
echo "   • 双击打开 $APP_PATH"
echo "   • 点击菜单栏图标或使用快捷键 ⌃⌥V 打开剪贴板窗口"
echo "   • 默认快捷键: ⌃⌥V (Control+Option+V)"
echo "   • 菜单中可设置开机自启动"
echo "   • 菜单中可打开快捷键设置"
echo ""
echo "🚀 启动应用..."
open "$APP_PATH"
