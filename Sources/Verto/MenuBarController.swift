import AppKit
import Combine
import SwiftUI

/// The whole app surface: an icon in the menu bar and a popover under it.
/// No Dock icon, no main window — see `LSUIElement` in Info.plist.
@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate {

    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var hotKey: HotKey?
    private let model = PopoverModel()
    private let settingsWindow = SettingsWindow()
    private var cancellables = Set<AnyCancellable>()

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
        // The model belongs to the controller, not the view: closing the window has
        // to archive and clear it, and the view is not around at that moment.
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(
                model: model,
                onClose: { [weak self] in self?.close() },
                onOpenSettings: { [weak self] in self?.openSettings() }
            )
        )


        let hotKey = HotKey { [weak self] in self?.toggle() }
        self.hotKey = hotKey

        Settings.shared.$hotKey
            .sink { combo in
                let registered = hotKey.register(combo)
                // @Published fires from willSet, so the store is mid-update here.
                // Writing another property of the same object from inside that is what
                // makes SwiftUI complain about publishing during a view update.
                DispatchQueue.main.async {
                    Settings.shared.hotKeyTaken = !registered
                }
            }
            .store(in: &cancellables)

        // Menus are built once, so they have to be rebuilt when the language changes;
        // SwiftUI views redraw on their own.
        Settings.shared.$appLanguage
            .dropFirst()
            .sink { language in
                L.use(language)
                NSApp.mainMenu = MainMenu.build()
            }
            .store(in: &cancellables)
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

    /// Fires however the popover closes — esc, the shortcut, or a click elsewhere.
    func popoverDidClose(_ notification: Notification) {
        model.archiveAndReset()
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
