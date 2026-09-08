import Testing
@testable import VertoCore

// The product rests on getting direction right without being asked. These are the
// cases that drove the design, not a sweep for coverage.

private let ruEn = LanguagePair(first: .russian, second: .english)

private func source(_ text: String, _ pair: LanguagePair = ruEn) -> LanguageCode? {
    LanguageDetector.detect(text, in: pair)?.source
}

// MARK: - The case the app exists for

@Suite("Направление")
struct DirectionTests {

    @Test("Русский и английский подряд разворачивают направление сами")
    func flipsWithoutBeingTold() {
        #expect(source("как твои дела?") == .russian)
        // Same pair, same settings, next paste — this is what every other translator
        // makes the user fix by hand.
        #expect(source("the build is flaky") == .english)
    }

    @Test("Ручной разворот не нужен на чистых фразах",
          arguments: ["Привет, как дела?", "Собрание перенесли на четверг"])
    func plainRussian(_ text: String) {
        #expect(source(text) == .russian)
    }
}

// MARK: - Why a language model was rejected

@Suite("Короткие строки")
struct ShortStringTests {

    // NLLanguageRecognizer answers these with confident nonsense, which is why the
    // detector counts characters instead.
    @Test("Латиница", arguments: ["OK", "Pizza", "Ping", "no", "Verto", "CI"])
    func latinIsEnglish(_ text: String) {
        #expect(source(text) == .english)
    }

    @Test("Кириллица", arguments: ["да", "Привет", "ок", "и"])
    func cyrillicIsRussian(_ text: String) {
        #expect(source(text) == .russian)
    }
}

// MARK: - Why the threshold is 15% and not 50%

@Suite("Порог 15%")
struct ThresholdTests {

    // Each case states its share of Cyrillic, and the set straddles the line. An
    // earlier version of this suite used a phrase that was 62% Cyrillic: it passed at
    // every threshold up to 62 and so proved nothing. A boundary test has to use data
    // near the boundary, and the share has to be counted rather than eyeballed.

    @Test("Выше порога, ниже половины — русский",
          arguments: [("срочно fix the build on arm64 runners", "20.7%"),
                      ("почини flaky tests in the release pipeline", "16.7%")])
    func aboveThreshold(_ text: String, _ share: String) {
        #expect(source(text) == .russian, "\(share) кириллицы")
    }

    @Test("Ниже порога — английский",
          arguments: [("надо rebase onto main before the release cut today", "9.5%"),
                      ("ок, merge the pull request into main branch now", "5.3%")])
    func belowThreshold(_ text: String, _ share: String) {
        #expect(source(text) == .english, "\(share) кириллицы")
    }

    @Test("Обычный рабочий русский с терминами")
    func technicalRussian() {
        #expect(source("задеплой на staging через CI") == .russian)
        #expect(source("please review the pull request now") == .english)
    }
}

// MARK: - Nothing to go on

@Suite("Нечего определять")
struct EmptyInputTests {

    @Test("Пустой ввод не даёт результата", arguments: ["", "   ", "\n\t "])
    func noResult(_ text: String) {
        #expect(LanguageDetector.detect(text, in: ruEn) == nil)
    }

    @Test("Текст без букв — направление не определено уверенно",
          arguments: ["12345", "!!! ??? ...", "3.14 + 2"])
    func notConfident(_ text: String) throws {
        let result = try #require(LanguageDetector.detect(text, in: ruEn))
        #expect(result.isConfident == false)
    }

    @Test("Буквы вне пары не голосуют")
    func outsideLettersDoNotVote() {
        // Greek belongs to neither language, so the Latin word decides.
        #expect(source("λόγος alpha") == .english)
    }
}

// MARK: - Languages written in more than one script

@Suite("Несколько письменностей у одного языка")
struct MultiScriptTests {

    private let jaEn = LanguagePair(first: .japanese, second: .english)

    @Test("Японский по кане, по кандзи и по обоим сразу",
          arguments: ["ありがとう", "日本語", "今日はいい天気ですね"])
    func japanese(_ text: String) {
        // A detector that knows only one script for Japanese misses half of these.
        #expect(source(text, jaEn) == .japanese)
    }

    @Test("Английский в паре с японским")
    func englishAgainstJapanese() {
        #expect(source("nice weather today", jaEn) == .english)
    }

    @Test("Две неевропейские письменности")
    func arabicAgainstRussian() {
        let pair = LanguagePair(first: .arabic, second: .russian)
        #expect(source("مرحبا بالعالم", pair) == .arabic)
        #expect(source("привет мир", pair) == .russian)
    }
}

// MARK: - Which method a pair gets

@Suite("Выбор метода по паре")
struct ScriptOverlapTests {

    @Test("Непересекающиеся письменности считаются по написанию",
          arguments: [LanguagePair(first: .russian, second: .english),
                      LanguagePair(first: .japanese, second: .english),
                      LanguagePair(first: .arabic, second: .french),
                      LanguagePair(first: .korean, second: .russian)])
    func disjoint(_ pair: LanguagePair) {
        #expect(pair.scriptsDiffer)
    }

    // Pairs a naive "is there Cyrillic?" test would get wrong every single time.
    @Test("Общая письменность — считать по написанию нельзя",
          arguments: [LanguagePair(first: .english, second: .german),
                      LanguagePair(first: .russian, second: .ukrainian),
                      LanguagePair(first: .japanese, second: .chinese)])
    func overlapping(_ pair: LanguagePair) {
        #expect(!pair.scriptsDiffer)
    }

    @Test("Общая письменность: направление определяет модель")
    func modelFallback() {
        let deEn = LanguagePair(first: .german, second: .english)
        #expect(source("Die Besprechung wurde auf Donnerstag verschoben", deEn) == .german)
        #expect(source("The meeting has been moved to Thursday", deEn) == .english)
    }
}

// MARK: - Every shipped language must be classifiable

@Suite("Целостность списка языков")
struct LanguageCatalogueTests {

    @Test("У каждого языка объявлена письменность", arguments: LanguageCode.allCases)
    func everyLanguageHasScripts(_ code: LanguageCode) {
        #expect(!code.scripts.isEmpty, "\(code.rawValue) не объявил письменность")
        #expect(!code.scripts.contains(.other), "\(code.rawValue) объявил неопределённую письменность")
    }

    @Test("Пара из одного языка недопустима")
    func pairNeedsTwoLanguages() {
        #expect(!LanguagePair(first: .english, second: .english).isValid)
        #expect(LanguagePair(first: .english, second: .german).isValid)
    }
}
