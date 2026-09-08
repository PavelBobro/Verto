import AppKit
import SwiftUI

/// Keeps the single settings window alive. An accessory app has no window by default,
/// so it also has to bring itself forward when the window opens.
@MainActor
final class SettingsWindow {

    private var window: NSWindow?

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: hosting)
            window.title = "Настройки Verto"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }

        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
