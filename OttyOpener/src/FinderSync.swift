import Cocoa
import FinderSync

class FinderSync: FIFinderSync {

    override init() {
        super.init()
        // 监控整个磁盘，让菜单在所有目录生效
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")

        // 「打开 Otty」：使用 Otty 官方应用图标（从 Otty.app 实时读取，随其更新自动跟随）
        let item = NSMenuItem(title: "打开 Otty", action: #selector(openOtty(_:)), keyEquivalent: "")
        item.target = self
        let icon = NSWorkspace.shared.icon(forFile: "/Applications/Otty.app")
        icon.size = NSSize(width: 16, height: 16)
        item.image = icon
        menu.addItem(item)

        // 「复制当前路径」：SF Symbol 链接图标（更简约，缩小至 12pt 与 App 图标观感协调）
        let copyItem = NSMenuItem(title: "复制当前路径", action: #selector(copyPath(_:)), keyEquivalent: "")
        copyItem.target = self
        copyItem.image = NSImage(systemSymbolName: "link", accessibilityDescription: "复制路径")?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 12, weight: .regular))
        menu.addItem(copyItem)

        return menu
    }

    // 解析当前右键目标目录：右键文件夹 → 该文件夹；右键文件 → 所在目录；空白处 → 当前目录
    private func resolvedDirectoryURL() -> URL? {
        let controller = FIFinderSyncController.default()
        if let selected = controller.selectedItemURLs(), let first = selected.first {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: first.path, isDirectory: &isDir), isDir.boolValue {
                return first
            } else {
                return first.deletingLastPathComponent()
            }
        }
        return controller.targetedURL()
    }

    // 解析当前右键目标路径：右键文件 → 文件本身；右键文件夹 → 该文件夹；空白处 → 当前目录
    private func resolvedCopyURL() -> URL? {
        let controller = FIFinderSyncController.default()
        if let selected = controller.selectedItemURLs(), let first = selected.first {
            return first
        }
        return controller.targetedURL()
    }

    @objc func openOtty(_ sender: AnyObject?) {
        guard let url = resolvedDirectoryURL() else { return }
        NSWorkspace.shared.open(
            [url],
            withApplicationAt: URL(fileURLWithPath: "/Applications/Otty.app"),
            configuration: NSWorkspace.OpenConfiguration()
        )
    }

    @objc func copyPath(_ sender: AnyObject?) {
        guard let url = resolvedCopyURL() else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.path, forType: .string)
    }
}
