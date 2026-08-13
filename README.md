# 访达右键菜单「打开 Otty + 复制当前路径」— 项目交接文档

> 本文档面向接管此项目的任何人（或大模型）。读完本文即可理解全部背景、原理、构建/安装流程和已知坑点，无需任何额外上下文。

## 需求与现状

**需求**：在 macOS 访达（Finder）中任意目录 —— 包括**空白处右键** —— 的右键菜单中显示两项：「打开 Otty」用终端软件 Otty 打开当前目录；「复制当前路径」把路径复制到剪贴板。要求后台无感知运行：无菜单栏图标、无窗口、无 Dock 图标、无常驻可见进程。

**现状（2026-08 已完成并验证）**：
- 已实现为原生 **FinderSync 访达扩展**，菜单项图标分别为 Otty 官方应用图标（运行时通过 `NSWorkspace.icon(forFile:)` 从 `/Applications/Otty.app` 读取并缩放到 16×16，Otty 更新图标会自动跟随）和 SF Symbol `link`（`pointSize: 12` 缩小，与 App 图标观感协调）。
- 行为：
  - 「打开 Otty」：空白处右键 → 当前目录；右键文件夹 → 该文件夹；右键文件 → 文件所在目录（目录解析见 `resolvedDirectoryURL()`）。
  - 「复制当前路径」：空白处右键 → 当前目录；右键文件夹 → 该文件夹路径；**右键文件 → 文件本身的完整路径**（路径解析见 `resolvedCopyURL()`）。
- 安装于 `/Applications/OttyOpener.app`（空壳宿主 App，用户无需打开它），扩展由访达按需加载。

## 为什么这样实现

- macOS 上**唯一**能往访达「空白处右键菜单」加菜单项的机制是 FinderSync 扩展（`FIFinderSync`）。Automator 快速操作只对"选中的项目"生效（本项目第一版就是快速操作，后已删除避免重复入口）。
- 本机（用户电脑）**没有安装完整 Xcode**，只有 Command Line Tools（`xcode-select -p` → `/Library/Developer/CommandLineTools`），因此没有用 Xcode 工程，而是用 `swiftc` 直接编译二进制、手工组装 .app/.appex 目录结构、ad-hoc 签名（`codesign -s -`）。整套流程都在 `build.sh` 里。
- Otty（`/Applications/Otty.app`，bundle id `io.appmakes.otty`）在 Info.plist 中声明接受 `public.folder` 文档类型，因此把目录 URL 直接交给它（等效 `open -a Otty <目录>`）即可打开并进入该目录。

## 文件结构

```
/Users/fanjk/Code/右键菜单/OttyOpener/
├── build.sh              # 一键构建脚本（编译 + 组装 + 签名）
├── build/                # 构建产物（build.sh 每次重建）
│   └── OttyOpener.app
└── src/
    ├── FinderSync.swift  # 扩展本体：菜单构造（两个菜单项）+ 打开 Otty + 复制路径的逻辑
    ├── main.swift        # 宿主 App：无界面，启动 5 秒后自动退出（仅用于让系统发现扩展）
    ├── App-Info.plist    # 宿主 App 的 Info.plist（LSUIElement=true，bundle id: local.ottyopener）
    ├── Ext-Info.plist    # 扩展的 Info.plist（NSExtensionPointIdentifier=com.apple.FinderSync，
    │                     #   bundle id: local.ottyopener.finderext，principal class: OttyFinderExtension.FinderSync）
    └── ext.entitlements  # ⚠️ 关键：com.apple.security.app-sandbox=true（见"坑点"）
```

## 构建与安装（完整流程）

```zsh
cd "/Users/fanjk/Code/右键菜单/OttyOpener"
./build.sh                                          # 产出 build/OttyOpener.app
rm -rf /Applications/OttyOpener.app
cp -R build/OttyOpener.app /Applications/
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/OttyOpener.app
open /Applications/OttyOpener.app                   # 宿主启动即退，触发扩展发现
sleep 5
pluginkit -e use -i local.ottyopener.finderext      # 启用扩展
killall Finder                                      # 重启访达加载扩展
```

验证：
```zsh
pluginkit -m -i local.ottyopener.finderext   # 应输出 "+  local.ottyopener.finderext(1.0)"，+ 表示已启用
pgrep -fl OttyFinderExtension                # 应有进程（由访达托管）
```

## 坑点记录（重要，均为实测踩过的）

1. **FinderSync 扩展必须启用 App Sandbox**，否则 pkd（插件守护进程）会**静默拒绝注册**——不写任何日志，`pluginkit -a` 返回成功但 `pluginkit -m` 查不到。这是本项目调试中最大的坑。解法：签名时附加 `ext.entitlements`（含 `com.apple.security.app-sandbox=true` 和对 `/` 的只读临时例外）。
2. appex 二进制入口是 `_NSExtensionMain` 而非 main：`swiftc` 需加 `-parse-as-library -application-extension -Xlinker -e -Xlinker _NSExtensionMain`。
3. `pluginkit` 的查询走 Spotlight/LaunchServices 索引；更新二进制后需 `lsregister -f` + 启动一次宿主 App 才会重新注册。装在 `/Applications`（而非 `~/Applications`）最可靠。
4. ad-hoc 签名本地可用；系统大版本升级后若菜单消失，按上面流程重装一遍即可。
5. 宿主 App 若启动即 `exit(0)` 可能影响扩展发现，现改为 NSApplication 运行 5 秒后自动退出（`ActivationPolicy.prohibited`，全程不可见）。

## 常见修改

- **改菜单文字/图标**：编辑 `src/FinderSync.swift` 中 `menu(for:)`（图标 SF Symbol 可用 `NSImage.SymbolConfiguration(pointSize:)` 调大小），重跑"构建与安装"。
- **复制路径格式**：`copyPath` 中 `url.path` 为不带尾部斜杠的绝对路径；想带斜杠可改成 `url.path + "/"`。
- **复制路径解析逻辑**：`copyPath` 用 `resolvedCopyURL()`（选中文件→文件本身；文件夹→文件夹；空白处→当前目录）；「打开 Otty」用 `resolvedDirectoryURL()`（文件→所在目录）。两者解析不同，改时注意区分。
- **换终端 App**：改 `openOtty` 中 `/Applications/Otty.app` 路径（目标 App 需支持接收文件夹，可用 `plutil -p .../Info.plist` 查其 CFBundleDocumentTypes 是否含 `public.folder`）。
- **卸载**：`pluginkit -e ignore -i local.ottyopener.finderext && rm -rf /Applications/OttyOpener.app && killall Finder`。

## 故障排查

- 菜单不出现：先查 `pluginkit -m -i local.ottyopener.finderext`；无输出→按"构建与安装"重装；有输出但无 `+`→`pluginkit -e use -i ...` 或到「系统设置 → 通用 → 登录项与扩展 → 访达」勾选；仍不行→`killall Finder`。
- 点击无反应：确认 `/Applications/Otty.app` 存在；查看扩展进程是否存活（`pgrep -f OttyFinderExtension`）。
