import Foundation
import Testing
@testable import VertoCore

private func record(_ source: String, _ target: String,
                    from: LanguageCode = .russian, to: LanguageCode = .english)
-> TranslationRecord {
    TranslationRecord(source: from, target: to, sourceText: source, targetText: target)
}

@Suite("Что попадает в историю")
struct HistoryAddTests {

    @Test("Перевод сохраняется")
    func keepsATranslation() {
        var history = History()
        history.add(record("привет", "hello"))
        #expect(history.records.count == 1)
        #expect(history.records.first?.targetText == "hello")
    }

    @Test("Новое идёт сверху")
    func newestFirst() {
        var history = History()
        history.add(record("первый", "first"))
        history.add(record("второй", "second"))
        #expect(history.records.map(\.sourceText) == ["второй", "первый"])
    }

    @Test("Пустое не сохраняется", arguments: [("", "hello"), ("привет", ""), ("  ", "\n")])
    func ignoresEmpty(_ pair: (String, String)) {
        var history = History()
        history.add(record(pair.0, pair.1))
        #expect(history.isEmpty)
    }
}

@Suite("Повторы не засоряют историю")
struct HistoryDuplicateTests {

    @Test("Тот же перевод поднимается наверх, а не дублируется")
    func duplicateMovesUp() {
        // Closing and reopening on the same phrase, or flipping the direction back and
        // forth, would otherwise fill the list with copies of one entry.
        var history = History()
        history.add(record("привет", "hello"))
        history.add(record("пока", "bye"))
        history.add(record("привет", "hello"))

        #expect(history.records.count == 2)
        #expect(history.records.first?.sourceText == "привет")
    }

    @Test("Тот же исходник с другим переводом — отдельная запись")
    func differentTranslationIsSeparate() {
        var history = History()
        history.add(record("замок", "castle"))
        history.add(record("замок", "lock"))
        #expect(history.records.count == 2)
    }
}

@Suite("Границы истории")
struct HistoryLimitTests {

    @Test("Список не растёт бесконечно")
    func staysWithinTheLimit() {
        var history = History()
        for index in 0..<(History.limit + 20) {
            history.add(record("исходник \(index)", "source \(index)"))
        }
        #expect(history.records.count == History.limit)
    }

    @Test("Переполнение вытесняет самое старое")
    func oldestFallsOff() {
        var history = History()
        for index in 0..<(History.limit + 1) {
            history.add(record("исходник \(index)", "source \(index)"))
        }
        #expect(history.records.first?.sourceText == "исходник \(History.limit)")
        #expect(!history.records.contains { $0.sourceText == "исходник 0" })
    }

    @Test("Список, созданный из длинного массива, обрезается")
    func initialiserTrims() {
        let many = (0..<(History.limit + 30)).map { record("и \($0)", "s \($0)") }
        #expect(History(records: many).records.count == History.limit)
    }
}

@Suite("Удаление")
struct HistoryRemovalTests {

    @Test("Удаляется именно выбранная запись")
    func removesOne() {
        var history = History()
        let keep = record("остаётся", "stays")
        history.add(record("уходит", "goes"))
        history.add(keep)
        history.remove(history.records.last!.id)

        #expect(history.records.count == 1)
        #expect(history.records.first?.sourceText == "остаётся")
    }

    @Test("Очистка убирает всё")
    func clearsEverything() {
        var history = History()
        history.add(record("привет", "hello"))
        history.clear()
        #expect(history.isEmpty)
    }
}

@Suite("История переживает перезапуск")
struct HistoryPersistenceTests {

    @Test("Кодируется и читается обратно")
    func roundTrips() throws {
        var history = History()
        history.add(record("привет", "hello"))
        history.add(record("the build is flaky", "сборка нестабильна", from: .english, to: .russian))

        let data = try JSONEncoder().encode(history)
        let restored = try JSONDecoder().decode(History.self, from: data)

        #expect(restored == history)
        #expect(restored.records.first?.source == .english)
    }
}
