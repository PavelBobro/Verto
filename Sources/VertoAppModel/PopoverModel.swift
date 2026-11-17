import VertoCore
import SwiftUI
import Translation

/// Holds what the popover shows. Direction lives here and nowhere else: it is
/// derived from the text on every change, never stored as a setting (Р-2).
@MainActor
public final class PopoverModel: ObservableObject {

    /// Translation starts here, not from a view modifier.
    ///
    /// It used to hang off `.onChange` on the text field, which meant text arriving
    /// while the field was off screen — recognised from a screenshot, say — was never
    /// translated at all. What the model does must not depend on what is drawn.
    @Published public var input = "" {
        didSet {
            guard input != oldValue else { return }
            inputChanged(input)
        }
    }
    @Published public private(set) var state: TranslationService.State = .idle
    @Published public private(set) var source: LanguageCode
    @Published public private(set) var target: LanguageCode
    @Published public private(set) var isConfident = true

    /// Lives in the model rather than as @State in the view. On the macOS 27 SDK,
    /// @State is a macro whose implementation ships only with Xcode, so a view using
    /// it no longer builds with the Command Line Tools alone.
    @Published public var showingHistory = false

    /// Reading text off a screenshot takes a moment, and the window is already open by
    /// then — without this it would sit there looking empty and broken.
    @Published public private(set) var isRecognizing = false
    @Published public private(set) var recognizedNothing = false

    /// Non-nil only while a language pack is downloading; that is what drives the
    /// one SwiftUI path we still need (FR-7).
    @Published public var downloadConfiguration: TranslationSession.Configuration?

    private let service: any TranslationEngine
    private let pairProvider: () -> LanguagePair
    private let history: any HistorySink
    private var manualOverride = false
    /// The pair the direction was last derived from. Comparing the whole pair keeps a
    /// change of either language from being mistaken for "nothing changed".
    private var lastPair: LanguagePair

    public convenience init(pair: @escaping () -> LanguagePair,
                            history: any HistorySink) {
        self.init(service: TranslationService(), pair: pair, history: history)
    }

    public init(service: any TranslationEngine,
                pair: @escaping () -> LanguagePair,
                history: any HistorySink) {
        self.service = service
        self.pairProvider = pair
        self.history = history

        let currentPair = pair()
        source = currentPair.first
        target = currentPair.second
        lastPair = currentPair

        service.onChange = { [weak self] state in
            guard let self else { return }
            self.state = state
            switch state {
            case .needsDownload:
                // A fresh configuration equal to the previous one does not restart
                // .translationTask, so an earlier, abandoned download would leave the
                // spinner up for good. invalidate() forces the task to run again.
                var configuration = TranslationSession.Configuration(
                    source: self.source.language, target: self.target.language
                )
                if self.downloadConfiguration == configuration {
                    configuration.invalidate()
                }
                self.downloadConfiguration = configuration
                TranslationService.log.info("download requested \(self.source.rawValue, privacy: .public)→\(self.target.rawValue, privacy: .public)")
            case .translated, .idle, .failed, .unsupported:
                // Anything that is not waiting for a pack means no download is pending.
                self.downloadConfiguration = nil
            case .translating:
                break
            }
        }
    }

    public func inputChanged(_ text: String) {
        if !manualOverride, let result = LanguageDetector.detect(text, in: pairProvider()) {
            source = result.source
            target = result.target
            isConfident = result.isConfident
        }
        service.translate(text, from: source, to: target)
    }

    /// Manual swap sticks until the field is cleared — otherwise the detector would
    /// undo the correction on the user's very next keystroke.
    public func swap() {
        (source, target) = (target, source)
        manualOverride = true
        isConfident = true
        service.translate(input, from: source, to: target)
    }

    /// Picks up a pair changed in settings while the popover was closed.
    public func syncPair() {
        let pair = pairProvider()
        guard pair != lastPair else { return }
        lastPair = pair
        source = pair.first
        target = pair.second
        manualOverride = false
        isConfident = true
        if !input.isEmpty { inputChanged(input) }
    }

    /// Called when the popover closes, however it closes.
    ///
    /// The window reopens empty rather than holding yesterday's phrase — the app is
    /// for pasting something new, and a field that still has old text in it has to be
    /// cleared before it can be used. Nothing is lost: a finished translation goes to
    /// the history on the way out.
    public func archiveAndReset() {
        archive()
        reset()
    }

    public func archive() {
        guard case .translated(let text) = state else { return }
        history.add(
            TranslationRecord(source: source, target: target,
                              sourceText: input, targetText: text)
        )
    }

    public func reset() {
        downloadConfiguration = nil
        showingHistory = false
        isRecognizing = false
        recognizedNothing = false
        input = ""
        manualOverride = false
        isConfident = true
        service.cancel()
    }

    /// Text read off the screen behaves exactly like text that was pasted: detection
    /// runs, the direction is decided, translation follows.
    public func startedRecognizing() {
        isRecognizing = true
        recognizedNothing = false
    }

    public func accept(recognized text: String) {
        isRecognizing = false
        manualOverride = false
        input = text
    }

    public func recognitionFoundNothing() {
        isRecognizing = false
        recognizedNothing = true
    }

    /// Puts a past translation back into the fields, ready to copy again.
    public func restore(_ record: TranslationRecord) {
        manualOverride = true
        source = record.source
        target = record.target
        input = record.sourceText
    }

    public func downloadFinished() {
        // A completion that arrives after the popover was reset belongs to a download
        // nobody is waiting for any more.
        guard downloadConfiguration != nil else { return }
        downloadConfiguration = nil
        service.translate(input, from: source, to: target)
    }

    /// The system sheet can be dismissed. Clearing the configuration is what stops the
    /// `.translationTask` from immediately asking again; the next edit can retry.
    public func downloadCancelled() {
        guard downloadConfiguration != nil else { return }
        downloadConfiguration = nil
        state = .idle
    }

    public func downloadFailed(_ error: Error) {
        guard downloadConfiguration != nil else { return }
        downloadConfiguration = nil
        state = .failed(error.localizedDescription)
    }

    public var translatedText: String? {
        if case .translated(let text) = state { return text }
        return nil
    }
}
