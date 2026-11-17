import Foundation
import Testing
import Translation
import VertoAppModel
import VertoCore

@MainActor
private final class FakeEngine: TranslationEngine {
    var state: TranslationService.State = .idle {
        didSet { onChange?(state) }
    }
    var onChange: ((TranslationService.State) -> Void)?

    var calls: [(text: String, source: LanguageCode, target: LanguageCode)] = []

    func translate(_ text: String, from source: LanguageCode, to target: LanguageCode) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state = .idle
            return
        }
        calls.append((text, source, target))
        state = .translated("translated: \(text)")
    }

    func cancel() {
        state = .idle
    }
}

@MainActor
private final class FakeHistory: HistorySink {
    var records: [TranslationRecord] = []

    func add(_ record: TranslationRecord) {
        records.append(record)
    }
}

@MainActor
private final class PairBox {
    var pair: LanguagePair

    init(_ pair: LanguagePair) {
        self.pair = pair
    }
}

@MainActor
private func makeModel(
    pair: LanguagePair = .default
) -> (model: PopoverModel, engine: FakeEngine, history: FakeHistory, box: PairBox) {
    let box = PairBox(pair)
    let engine = FakeEngine()
    let history = FakeHistory()
    let model = PopoverModel(
        service: engine,
        pair: { box.pair },
        history: history
    )
    return (model, engine, history, box)
}

@Suite("Модель попапа")
@MainActor
struct PopoverModelTests {

    @Test("Завершённый перевод уходит в историю, поле очищается")
    func archiveAndResetKeepsTranslation() {
        let (model, _, history, _) = makeModel()

        model.input = "привет"
        #expect(model.translatedText == "translated: привет")
        #expect(history.records.isEmpty)

        model.archiveAndReset()

        #expect(history.records.count == 1)
        #expect(history.records.first?.sourceText == "привет")
        #expect(history.records.first?.targetText == "translated: привет")
        #expect(model.input.isEmpty)
        #expect(model.state == .idle)
    }

    @Test("Смена пары обновляет направление, даже если один язык совпал")
    func syncPairComparesTheWholePair() {
        let (model, _, _, box) = makeModel()

        // Old pair RU↔EN, direction manually flipped to EN→RU. The new pair shares
        // English with the old source; the old guard returned early and left RU as
        // the target.
        model.swap()
        #expect(model.source == .english)
        #expect(model.target == .russian)

        box.pair = LanguagePair(first: .english, second: .german)
        model.syncPair()

        #expect(model.source == .english)
        #expect(model.target == .german)
    }

    @Test("Отмена загрузки не запускает перевод заново")
    func downloadCancelledDoesNotRetranslate() {
        let (model, engine, _, _) = makeModel()

        model.input = "hello"
        let callsBefore = engine.calls.count
        model.downloadConfiguration = TranslationSession.Configuration(
            source: LanguageCode.english.language,
            target: LanguageCode.german.language
        )

        model.downloadCancelled()

        #expect(model.downloadConfiguration == nil)
        #expect(engine.calls.count == callsBefore)
        #expect(model.state == .idle)
    }

    @Test("Завершённая загрузка повторяет перевод один раз")
    func downloadFinishedRetranslatesOnce() {
        let (model, engine, _, _) = makeModel()

        model.input = "hello"
        let callsBefore = engine.calls.count
        model.downloadConfiguration = TranslationSession.Configuration(
            source: LanguageCode.english.language,
            target: LanguageCode.german.language
        )

        model.downloadFinished()

        #expect(model.downloadConfiguration == nil)
        #expect(engine.calls.count == callsBefore + 1)
    }

    @Test("Запоздавшее завершение загрузки ничего не переводит")
    func staleDownloadCompletionIsIgnored() {
        let (model, engine, _, _) = makeModel()

        model.input = "hello"
        let callsBefore = engine.calls.count

        // The model was reset while the system sheet was up.
        model.downloadFinished()

        #expect(engine.calls.count == callsBefore)
    }
}
