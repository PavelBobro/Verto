import SwiftUI
import Translation

/// Holds what the popover shows. Direction lives here and nowhere else: it is
/// derived from the text on every change, never stored as a setting (Р-2).
@MainActor
final class PopoverModel: ObservableObject {

    @Published var input = ""
    @Published private(set) var state: TranslationService.State = .idle
    @Published private(set) var source: LanguageCode
    @Published private(set) var target: LanguageCode
    @Published private(set) var isConfident = true

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

    func reset() {
        input = ""
        manualOverride = false
        isConfident = true
        service.cancel()
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
