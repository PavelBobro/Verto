import VertoCore
import SwiftUI
import Translation

/// Holds what the popover shows. Direction lives here and nowhere else: it is
/// derived from the text on every change, never stored as a setting (Р-2).
@MainActor
final class PopoverModel: ObservableObject {

    /// Translation starts here, not from a view modifier.
    ///
    /// It used to hang off `.onChange` on the text field, which meant text arriving
    /// while the field was off screen — recognised from a screenshot, say — was never
    /// translated at all. What the model does must not depend on what is drawn.
    @Published var input = "" {
        didSet {
            guard input != oldValue else { return }
            inputChanged(input)
        }
    }
    @Published private(set) var state: TranslationService.State = .idle
    @Published private(set) var source: LanguageCode
    @Published private(set) var target: LanguageCode
    @Published private(set) var isConfident = true

    /// Reading text off a screenshot takes a moment, and the window is already open by
    /// then — without this it would sit there looking empty and broken.
    @Published private(set) var isRecognizing = false
    @Published private(set) var recognizedNothing = false

    /// Non-nil only while a language pack is downloading; that is what drives the
    /// one SwiftUI path we still need (FR-7).
    @Published var downloadConfiguration: TranslationSession.Configuration?

    private let service = TranslationService()
    private var manualOverride = false

    init() {
        let pair = Settings.shared.pair
        source = pair.first
        target = pair.second

        service.onChange = { [weak self] state in
            guard let self else { return }
            self.state = state
            if case .needsDownload = state {
                self.downloadConfiguration = TranslationSession.Configuration(
                    source: self.source.language, target: self.target.language
                )
            }
        }
    }

    func inputChanged(_ text: String) {
        if !manualOverride, let result = LanguageDetector.detect(text, in: Settings.shared.pair) {
            source = result.source
            target = result.target
            isConfident = result.isConfident
        }
        service.translate(text, from: source, to: target)
    }

    /// Manual swap sticks until the field is cleared — otherwise the detector would
    /// undo the correction on the user's very next keystroke.
    func swap() {
        (source, target) = (target, source)
        manualOverride = true
        isConfident = true
        service.translate(input, from: source, to: target)
    }

    /// Picks up a pair changed in settings while the popover was closed.
    func syncPair() {
        let pair = Settings.shared.pair
        guard source != pair.first && source != pair.second else { return }
        source = pair.first
        target = pair.second
        manualOverride = false
        if !input.isEmpty { inputChanged(input) }
    }

    /// Called when the popover closes, however it closes.
    ///
    /// The window reopens empty rather than holding yesterday's phrase — the app is
    /// for pasting something new, and a field that still has old text in it has to be
    /// cleared before it can be used. Nothing is lost: a finished translation goes to
    /// the history on the way out.
    func archiveAndReset() {
        archive()
        reset()
    }

    func archive() {
        guard case .translated(let text) = state else { return }
        HistoryStore.shared.add(
            TranslationRecord(source: source, target: target,
                              sourceText: input, targetText: text)
        )
    }

    func reset() {
        isRecognizing = false
        recognizedNothing = false
        input = ""
        manualOverride = false
        isConfident = true
        service.cancel()
    }

    /// Text read off the screen behaves exactly like text that was pasted: detection
    /// runs, the direction is decided, translation follows.
    func startedRecognizing() {
        isRecognizing = true
        recognizedNothing = false
    }

    func accept(recognized text: String) {
        isRecognizing = false
        manualOverride = false
        input = text
    }

    func recognitionFoundNothing() {
        isRecognizing = false
        recognizedNothing = true
    }

    /// Puts a past translation back into the fields, ready to copy again.
    func restore(_ record: TranslationRecord) {
        manualOverride = true
        source = record.source
        target = record.target
        input = record.sourceText
    }

    func downloadFinished() {
        downloadConfiguration = nil
        service.translate(input, from: source, to: target)
    }

    var translatedText: String? {
        if case .translated(let text) = state { return text }
        return nil
    }
}
