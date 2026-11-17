import VertoCore

/// What the popover model needs from history. The real store stays in the app target;
/// tests provide their own sink and avoid touching `UserDefaults`.
@MainActor
public protocol HistorySink: AnyObject {
    func add(_ record: TranslationRecord)
}
