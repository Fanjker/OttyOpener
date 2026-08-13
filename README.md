# 访达右键菜单增强（OttyOpener）

> macOS Finder 右键菜单扩展：一键「打开 Otty」进入当前目录、「复制当前路径」到剪贴板。支持**空白处右键**。

## 解决的痛点

- **Finder 原生右键菜单没有"在此处打开终端"和"复制路径"**：日常在访达里找目录、复制路径、再切到终端粘贴，操作链又长又繁琐。本扩展把这两步直接放进右键菜单。
- **空白处右键也能用**：Finder 的 Automator 快速操作只对"选中的项目"生效——在目录空白处右键时什么都不会出现。FinderSync 扩展是 macOS 上唯一能在**空白处右键菜单**添加菜单项的机制。
- **后台无感运行**：无菜单栏图标、无窗口、无 Dock 图标、无常驻可见进程，由访达按需加载，零资源占用。
- **无 Xcode 也能构建**：项目用 `swiftc` 直接编译 + 手工组装 .app 结构 + ad-hoc 签名，只有 Command Line Tools 的机器也能一键构建安装。

## 功能特性

| 操作 | 「打开 Otty」 | 「复制当前路径」 |
| --- | --- | --- |
| 空白处右键 | 用 Otty 打开当前目录 | 复制当前目录路径 |
| 右键文件夹 | 用 Otty 打开该文件夹 | 复制该文件夹路径 |
| 右键文件 | 用 Otty 打开文件所在目录 | 复制**文件本身**的完整路径 |

- 菜单图标：Otty 官方应用图标（运行时从 `/Applications/Otty.app` 实时读取，Otty 更新图标自动跟随）+ SF Symbol `link`（12pt 缩小，观感协调）。
- 复制格式：不带尾部斜杠的绝对路径（如 `/Users/name/Code/project`）。

## 安装与使用

```zsh
cd OttyOpener
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

> 注意：Otty（`/Applications/Otty.app`）需要已安装。换其他终端 App 见 [MAINTENANCE.md](MAINTENANCE.md#常见修改)。

## 卸载

```zsh
pluginkit -e ignore -i local.ottyopener.finderext
rm -rf /Applications/OttyOpener.app
killall Finder
```

---

*维护者/交接文档（实现原理、文件结构、坑点、故障排查）见 [MAINTENANCE.md](MAINTENANCE.md)。*
