#!/bin/zsh
set -e
cd "$(dirname "$0")"
APP=build/OttyOpener.app
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/PlugIns/OttyFinderExtension.appex/Contents/MacOS"

# 编译扩展二进制（app extension 入口为 NSExtensionMain）
swiftc src/FinderSync.swift \
  -module-name OttyFinderExtension \
  -parse-as-library \
  -application-extension \
  -O \
  -framework FinderSync -framework Cocoa \
  -Xlinker -e -Xlinker _NSExtensionMain \
  -Xlinker -application_extension \
  -o "$APP/Contents/PlugIns/OttyFinderExtension.appex/Contents/MacOS/OttyFinderExtension"

# 编译宿主 App（空壳，启动即退出）
swiftc src/main.swift -O -o "$APP/Contents/MacOS/OttyOpener"

cp src/App-Info.plist "$APP/Contents/Info.plist"
cp src/Ext-Info.plist "$APP/Contents/PlugIns/OttyFinderExtension.appex/Contents/Info.plist"

# ad-hoc 签名（先签内层 appex，再签外层 app）
codesign --force -s - --entitlements src/ext.entitlements "$APP/Contents/PlugIns/OttyFinderExtension.appex"
codesign --force -s - "$APP"
echo "build ok: $APP"
