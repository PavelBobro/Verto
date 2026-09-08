import Foundation

/// One finished translation, kept after the window closes.
public struct TranslationRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let source: LanguageCode
    public let target: LanguageCode
    public let sourceText: String
    public let targetText: String
    public let date: Date

    public init(id: UUID = UUID(), source: LanguageCode, target: LanguageCode,
                sourceText: String, targetText: String, date: Date = Date()) {
        self.id = id
        self.source = source
        self.target = target
        self.sourceText = sourceText
        self.targetText = targetText
        self.date = date
    }
}

/// The list itself, newest first.
///
/// Kept as a value type with no storage of its own so the rules — what counts as a
/// duplicate, when the list is full — can be exercised directly.
public struct History: Codable, Equatable, Sendable {

    /// Enough to find this morning's translation, small enough that the file stays
    /// trivial and the list stays scannable.
    public static let limit = 50

    public private(set) var records: [TranslationRecord] = []

    public init(records: [TranslationRecord] = []) {
        self.records = Array(records.prefix(Self.limit))
    }

    public var isEmpty: Bool { records.isEmpty }

    /// Adds a translation unless there is nothing to keep.
    ///
    /// Retranslating the same text — closing and reopening on the same phrase, or
    /// flipping the direction back and forth — must not fill the list with copies of
    /// one entry, so an identical translation is moved to the top instead of added.
    public mutating func add(_ record: TranslationRecord) {
        let source = record.sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let target = record.targetText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty, !target.isEmpty else { return }

        records.removeAll {
            $0.sourceText == record.sourceText && $0.targetText == record.targetText
        }
        records.insert(record, at: 0)

        if records.count > Self.limit {
            records.removeLast(records.count - Self.limit)
        }
    }

    public mutating func remove(_ id: UUID) {
        records.removeAll { $0.id == id }
    }

    public mutating func clear() {
        records.removeAll()
    }
}
