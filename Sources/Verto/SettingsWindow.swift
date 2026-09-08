import AppKit
import SwiftUI

/// Keeps the single settings window alive, and lends the app a Dock icon for as long
/// as that window is open.
///
/// Verto is an accessory app: no Dock icon, no app switcher entry, because there is
/// nothing to open by clicking one. A settings window is the exception — while it is
/// on screen the app has something to show, so for that time it behaves like an
/// ordinary application and drops back afterwards.
@MainActor
final class SettingsWindow: NSObject, NSWindowDelegate {

    private var window: NSWindow?

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: hosting)
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            self.window = window
        }

        // Before ordering the window in: an accessory app cannot take focus properly,
        // and the window would open behind whatever the user was working in.
        NSApp.setActivationPolicy(.regular)

        // The title is set on every show, not only on creation: the window outlives
        // a language change.
        window?.title = L.settingsTitle
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        // Back to living in the menu bar. Deferred by one turn of the run loop so the
        // window finishes closing first — changing the policy mid-close leaves the
        // Dock icon behind.
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
