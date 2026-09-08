import Foundation

/// Every string the user can see, named rather than written inline.
///
/// Keys live here instead of being scattered through the views so a missing or
/// renamed one is a compile error rather than an English word appearing in a Russian
/// interface. English is the base language; the app follows the system.
enum L {

    /// Which bundle strings come from. Pointing this at a single `.lproj` is what lets
    /// the interface change language on the spot: reading `AppleLanguages` instead
    /// would only take effect on the next launch.
    nonisolated(unsafe) static var bundle: Bundle = .main

    /// The locale the interface is being read in. Anything the system localises for
    /// us — language names, dates — has to go through this, or it follows the Mac's
    /// language while the rest of the window follows the chosen one.
    nonisolated(unsafe) static var locale: Locale = .current

    static func use(_ language: AppLanguage) {
        switch language {
        case .system:
            bundle = .main
            locale = .current
        default:
            bundle = Bundle.main.path(forResource: language.rawValue, ofType: "lproj")
                .flatMap(Bundle.init(path:)) ?? .main
            locale = Locale(identifier: language.rawValue)
        }
    }

    private static func t(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    private static func t(_ key: String, _ argument: String) -> String {
        String(format: bundle.localizedString(forKey: key, value: nil, table: nil), argument)
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
    static var clearInput: String        { t("help.clearInput") }

    // Screen capture
    static var captureHelp: String       { t("capture.help") }
    static var recognizing: String       { t("capture.recognizing") }
    static var recognizedNothing: String { t("capture.nothing") }
    static var menuCapture: String       { t("menu.capture") }

    // History
    static var historyHelp: String       { t("history.help") }
    static var historyEmpty: String      { t("history.empty") }
    static var historyBack: String       { t("history.back") }
    static var historyClear: String      { t("history.clear") }
    static var historyDelete: String     { t("history.delete") }

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
    static var hotkeyRecording: String   { t("settings.hotkey.recording") }
    static var hotkeyHelp: String        { t("settings.hotkey.help") }
    static var hotkeyTaken: String       { t("settings.hotkey.taken") }
    static var launchAtLogin: String     { t("settings.launchAtLogin") }
    static var launchFailed: String      { t("settings.launchAtLogin.failed") }

    // Interface language
    static var interfaceLanguage: String { t("settings.language") }
    static var languageSystem: String    { t("settings.language.system") }

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


/// What the interface is written in. Separate from the translation pair — the app can
/// speak English while translating Russian.
enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case system
    case english = "en"
    case russian = "ru"

    /// Named in its own language, the way macOS lists languages.
    var title: String {
        switch self {
        case .system:  L.languageSystem
        case .english: "English"
        case .russian: "Русский"
        }
    }
}
