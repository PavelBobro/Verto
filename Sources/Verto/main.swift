import AppKit

/// Plain AppKit entry point rather than SwiftUI's `@main`: it keeps the app buildable
/// with SwiftPM alone, without an Xcode project.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MainMenu.build()
        controller = MenuBarController()
    }
}

if CommandLine.arguments.contains("--probe-login-item") {
    LoginItem.runProbe()
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // menu bar only, no Dock icon
app.run()
