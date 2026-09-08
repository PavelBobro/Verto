import AppKit
import SwiftUI

/// The whole app surface: an icon in the menu bar and a popover under it.
/// No Dock icon, no main window — see `LSUIElement` in Info.plist.
@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate {

    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var hotKey: HotKey?
    private let settingsWindow = SettingsWindow()

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = VertoIcon.menuBar()
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover.behavior = .transient
        popover.animates = false            // the point of the app is that it is instant
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(
                onClose: { [weak self] in self?.close() },
                onOpenSettings: { [weak self] in self?.openSettings() }
            )
        )


        hotKey = HotKey { [weak self] in self?.toggle() }
    }

    @objc private func handleClick() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else {
            toggle()
        }
    }

    func toggle() {
        popover.isShown ? close() : open()
    }

    /// Attaching the menu permanently would hijack left-click, so it is lent to the
    /// status item for the duration of one click.
    private func showMenu() {
        close()
        statusItem.menu = MainMenu.statusItemMenu(target: self)
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func open() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        // Without this the popover opens behind whatever the user was working in.
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
    }

    func close() {
        popover.performClose(nil)
    }

    /// The one feature that can legitimately fail on an ad-hoc signed build, so the
    /// failure is shown rather than swallowed.
    @objc func openSettings() {
        close()
        settingsWindow.show()
    }

    @objc func toggleLaunchAtLogin() {
        if case .failure(let error) = LoginItem.set(!LoginItem.isEnabled) {
            let alert = NSAlert()
            alert.messageText = L.launchFailed
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }
}
