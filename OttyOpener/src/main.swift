import Cocoa
// 宿主 App 仅用于承载 FinderSync 扩展。无界面（LSUIElement），
// 启动后停留几秒等系统完成扩展注册，然后自动退出。
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
    app.terminate(nil)
}
app.run()
