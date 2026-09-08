import Foundation
import SwiftUI
import Translation

/// Finds out whether the packs for a pair are on the machine, and downloads them.
///
/// Apple ships no programmatic download call: the only way to fetch a pack is to hold
/// a session from `.translationTask` and call `prepareTranslation()`, which puts the
/// system's own confirmation sheet on screen. So this object decides *what* to
/// download, and the view it belongs to performs it.
@MainActor
final class LanguagePacks: ObservableObject {

    enum State: Equatable {
        case checking
        case installed
        case available          // supported by Apple, not on this machine yet
        case downloading
        case unsupported(LanguageCode)
        case failed(String)
    }

    @Published private(set) var state: State = .checking

    /// Non-nil while a download is in flight; the view watches it with `.translationTask`.
    @Published var pending: TranslationSession.Configuration?

    private var pair: LanguagePair?
    private var remainingLeg: TranslationSession.Configuration?

    func refresh(for pair: LanguagePair) async {
        self.pair = pair
        guard pair.isValid else { return }

        state = .checking
        let availability = LanguageAvailability()
        let forward  = await availability.status(from: pair.first.language,  to: pair.second.language)
        let backward = await availability.status(from: pair.second.language, to: pair.first.language)

        if forward == .unsupported  { state = .unsupported(pair.first);  return }
        if backward == .unsupported { state = .unsupported(pair.second); return }

        state = (forward == .installed && backward == .installed) ? .installed : .available
    }

    /// Packs are directional, so both legs are fetched — one after the other, because
    /// two system sheets at once would stack on top of each other.
    func download() {
        guard let pair, pair.isValid else { return }
        state = .downloading
        pending = TranslationSession.Configuration(source: pair.first.language,
                                                   target: pair.second.language)
        remainingLeg = TranslationSession.Configuration(source: pair.second.language,
                                                        target: pair.first.language)
    }

    func legFinished() async {
        if let next = remainingLeg {
            remainingLeg = nil
            pending = next
            return
        }
        pending = nil
        if let pair { await refresh(for: pair) }
    }

    func legFailed(_ error: Error) {
        pending = nil
        remainingLeg = nil
        state = .failed(error.localizedDescription)
    }
}
