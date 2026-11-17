import Foundation
import VertoAppModel
import VertoCore

/// The history, saved so it survives a restart.
@MainActor
final class HistoryStore: ObservableObject {

    static let shared = HistoryStore()

    @Published private(set) var history: History {
        didSet { save() }
    }

    private static let key = "history"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        guard let data = defaults.data(forKey: Self.key) else {
            history = History()
            return
        }

        if let archive = try? JSONDecoder().decode(HistoryArchive.self, from: data),
           archive.version <= HistoryArchive.currentVersion {
            history = archive.history
            return
        }

        // Data written before the versioned envelope was simply `History`; read it
        // once and immediately rewrite it in the new shape.
        if let legacy = try? JSONDecoder().decode(History.self, from: data) {
            history = legacy
            save()
            return
        }

        history = History()
    }

    func add(_ record: TranslationRecord) { history.add(record) }
    func remove(_ id: UUID)               { history.remove(id) }
    func clear()                          { history.clear() }

    private func save() {
        guard let data = try? JSONEncoder().encode(HistoryArchive(history: history)) else { return }
        defaults.set(data, forKey: Self.key)
    }
}

extension HistoryStore: HistorySink {}
