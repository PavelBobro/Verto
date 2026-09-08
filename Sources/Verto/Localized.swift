import Foundation

/// Every string the user can see, named rather than written inline.
///
/// Keys live here instead of being scattered through the views so a missing or
/// renamed one is a compile error rather than an English word appearing in a Russian
/// interface. English is the base language; the app follows the system.
enum L {

    private static func t(_ key: String) -> String {
        NSLocalizedString(key, bundle: .main, comment: "")
    }

    private static func t(_ key: String, _ argument: String) -> String {
        String(format: NSLocalizedString(key, bundle: .main, comment: ""), argument)
    }

    // Popover
    static var outputPlaceholder: String { t("output.placeholder") }
    static var translating: String       { t("output.translating") }
    static func downloading(_ language: String) -> String { t("output.downloading", language) }
    static func unsupported(_ language: String) -> String { t("output.unsupported", language) }
    static var copyAndClose: String      { t("footer.copyAndClose") }
    static var swapHint: String          { t("footer.swap") }
    static var lowConfidence: String     { t("footer.lowConfidence") }
    static var swapHelp: String          { t("help.swap") }
    static var settingsHelp: String      { t("help.settings") }

    // Settings
    static var settingsTitle: String     { t("settings.title") }
    static var languagePair: String      { t("settings.pair") }
    static var firstLanguage: String     { t("settings.pair.first") }
    static var secondLanguage: String    { t("settings.pair.second") }
    static var hintSameLanguage: String  { t("settings.hint.same") }
    static var hintScriptsDiffer: String { t("settings.hint.scripts") }
    static var hintSharedScript: String  { t("settings.hint.model") }
    static var packs: String             { t("settings.packs") }
    static var packsFooter: String       { t("settings.packs.footer") }
    static var packChecking: String      { t("settings.packs.checking") }
    static var packInstalled: String     { t("settings.packs.installed") }
    static var packMissing: String       { t("settings.packs.missing") }
    static var packDownload: String      { t("settings.packs.download") }
    static var packDownloading: String   { t("settings.packs.downloading") }
    static var packRetry: String         { t("settings.packs.retry") }
    static func packUnsupported(_ language: String) -> String { t("settings.packs.unsupported", language) }
    static var behaviour: String         { t("settings.behaviour") }
    static var hotkeyLabel: String       { t("settings.hotkey") }
    static var launchAtLogin: String     { t("settings.launchAtLogin") }
    static var launchFailed: String      { t("settings.launchAtLogin.failed") }

    // Menus
    static var menuSettings: String      { t("menu.settings") }
    static var menuHide: String          { t("menu.hide") }
    static var menuQuit: String          { t("menu.quit") }
    static var menuEdit: String          { t("menu.edit") }
    static var menuUndo: String          { t("menu.undo") }
    static var menuRedo: String          { t("menu.redo") }
    static var menuCut: String           { t("menu.cut") }
    static var menuCopy: String          { t("menu.copy") }
    static var menuPaste: String         { t("menu.paste") }
    static var menuSelectAll: String     { t("menu.selectAll") }
}
