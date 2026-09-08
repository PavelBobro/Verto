import Foundation
import VertoCore

/// The history, saved so it survives a restart.
@MainActor
final class HistoryStore: ObservableObject {

    static let shared = HistoryStore()

    @Published private(set) var history: History {
        didSet { save() }
    }

    private static let key = "history"

    private init() {
        history = UserDefaults.standard.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(History.self, from: $0) } ?? History()
    }

    func add(_ record: TranslationRecord) { history.add(record) }
    func remove(_ id: UUID)               { history.remove(id) }
    func clear()                          { history.clear() }

    private func save() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
