import VertoCore
import Foundation
import Translation

/// Wraps `Translation.framework`.
///
/// Uses the direct session API (macOS 26) rather than the SwiftUI `.translationTask`
/// modifier, so translation is testable on its own and cancellation is the framework's
/// own `cancel()` instead of a Task race (FR-2, Р-10).
@MainActor
final class TranslationService {

    enum State: Equatable {
        case idle
        case translating
        case translated(String)
        case needsDownload(LanguageCode)
        case unsupported(LanguageCode)
        case failed(String)
    }

    private(set) var state: State = .idle { didSet { onChange?(state) } }
    var onChange: ((State) -> Void)?

    /// Time to wait after the last keystroke. Long enough that typing does not fire
    /// a request per character, short enough to feel immediate on paste (FR-2).
    static let debounce = Duration.milliseconds(300)

    private var work: Task<Void, Never>?
    private var session: TranslationSession?
    private var sessionKey: String?
    private var inFlight = false

    func translate(_ text: String, from source: LanguageCode, to target: LanguageCode) {
        work?.cancel()
        // Only tear the session down when there is something to stop. `cancel()` is
        // terminal — a cancelled session refuses every later request — so calling it
        // per keystroke would poison the cache after the first translation.
        if inFlight { invalidateSession() }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }

        work = Task { [weak self] in
            try? await Task.sleep(for: Self.debounce)
            guard !Task.isCancelled else { return }
            await self?.run(trimmed, from: source, to: target)
        }
    }

    func cancel() {
        work?.cancel()
        invalidateSession()
        state = .idle
    }

    /// Stops in-flight work and drops the session, so the next request builds a fresh
    /// one rather than reusing a dead handle.
    private func invalidateSession() {
        session?.cancel()
        session = nil
        sessionKey = nil
        inFlight = false
    }

    // MARK: - Private

    private func run(_ text: String, from source: LanguageCode, to target: LanguageCode) async {
        state = .translating

        switch await LanguageAvailability().status(from: source.language, to: target.language) {
        case .unsupported:
            state = .unsupported(source)
            return
        case .supported:
            // The pack is not on disk yet. Downloading needs the SwiftUI path, which
            // is what shows the system download sheet (FR-7).
            state = .needsDownload(source)
            return
        case .installed:
            break
        @unknown default:
            break
        }

        inFlight = true
        defer { inFlight = false }

        do {
            let response = try await session(for: source, to: target).translate(text)
            guard !Task.isCancelled else { return }
            state = .translated(response.targetText)
        } catch is CancellationError {
            // Superseded by newer input — leave the previous result on screen.
        } catch {
            // A failed session cannot be trusted for the next request either.
            invalidateSession()
            NSLog("Verto: translate \(source.rawValue)>\(target.rawValue) failed — \(error)")
            state = .failed(error.localizedDescription)
        }
    }

    /// Sessions are reused per direction; rebuilding one on every keystroke is what
    /// makes the framework throttle.
    private func session(for source: LanguageCode, to target: LanguageCode) -> TranslationSession {
        let key = "\(source.rawValue)>\(target.rawValue)"
        if key == sessionKey, let session { return session }

        let fresh = TranslationSession(installedSource: source.language, target: target.language)
        session = fresh
        sessionKey = key
        return fresh
    }
}
