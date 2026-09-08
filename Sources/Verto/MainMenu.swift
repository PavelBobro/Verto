import AppKit

/// A menu bar app has no visible menu, but macOS still routes ⌘X/⌘C/⌘V/⌘A and ⌘Q
/// through the main menu. Without one, pasting into a text field simply does nothing.
enum MainMenu {

    static func build() -> NSMenu {
        let root = NSMenu()
        root.addItem(appMenu())
        root.addItem(editMenu())
        return root
    }

    private static func appMenu() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu()
        menu.addItem(withTitle: L.menuSettings, action: #selector(MenuBarController.openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: L.menuHide, action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        menu.addItem(.separator())
        menu.addItem(withTitle: L.menuQuit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.submenu = menu
        return item
    }

    private static func editMenu() -> NSMenuItem {
        let item = NSMenuItem(title: L.menuEdit, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: L.menuEdit)

        menu.addItem(withTitle: L.menuUndo, action: Selector(("undo:")), keyEquivalent: "z")
        let redo = menu.addItem(withTitle: L.menuRedo, action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]

        menu.addItem(.separator())
        menu.addItem(withTitle: L.menuCut, action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: L.menuCopy, action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: L.menuPaste, action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(withTitle: L.menuSelectAll, action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        item.submenu = menu
        return item
    }

    /// Right-click menu on the status item — the only way out of an app with no Dock
    /// icon and no window.
    static func statusItemMenu(target: AnyObject) -> NSMenu {
        let menu = NSMenu()

        let settings = NSMenuItem(title: L.menuSettings,
                                  action: #selector(MenuBarController.openSettings),
                                  keyEquivalent: ",")
        settings.target = target
        menu.addItem(settings)
        menu.addItem(.separator())

        let launch = NSMenuItem(title: L.launchAtLogin,
                                action: #selector(MenuBarController.toggleLaunchAtLogin),
                                keyEquivalent: "")
        launch.target = target
        launch.state = LoginItem.isEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
        menu.addItem(launch)

        menu.addItem(.separator())
        menu.addItem(withTitle: L.menuQuit,
                     action: #selector(NSApplication.terminate(_:)),
                     keyEquivalent: "q")
        return menu
    }
}
