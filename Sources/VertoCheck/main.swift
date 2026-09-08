import VertoCore

// The whole product rests on getting direction right without being asked.
// These are the cases that drove the design, not a sweep for coverage.

let ruEn = LanguagePair(first: .russian, second: .english)

func source(_ text: String, _ pair: LanguagePair = ruEn) -> LanguageCode? {
    LanguageDetector.detect(text, in: pair)?.source
}

// MARK: - The case the app exists for

Check.suite("Направление разворачивается само") {
    Check.equal(source("как твои дела?"), .russian, "русская фраза")
    // Same pair, same settings, next paste — this is what every other translator
    // makes the user fix by hand.
    Check.equal(source("the build is flaky"), .english, "английская фраза следом")
}

// MARK: - Why a language model was rejected

Check.suite("Короткие строки, на которых модель ошибается") {
    for text in ["OK", "Pizza", "Ping", "no", "Verto", "CI"] {
        Check.equal(source(text), .english, "«\(text)» — английский")
    }
    for text in ["да", "Привет", "ок", "и"] {
        Check.equal(source(text), .russian, "«\(text)» — русский")
    }
}

// MARK: - Why the threshold is 15% and not 50%

Check.suite("Порог 15%") {
    // These two straddle the threshold, and the share of Cyrillic in each is stated
    // because a case that does not sit near 15% proves nothing about it. An earlier
    // version of this suite used a phrase that was 62% Cyrillic and passed at every
    // threshold up to 62 — it tested nothing.

    // 20.7% Cyrillic — above the threshold, below half. A 50% threshold would send
    // this to be translated as English.
    Check.equal(source("срочно fix the build on arm64 runners"), .russian,
                "20.7% кириллицы — русский")

    // 16.7% — barely above.
    Check.equal(source("почини flaky tests in the release pipeline"), .russian,
                "16.7% кириллицы — всё ещё русский")

    // 9.5% — below the threshold, so a lone Russian word does not hijack an English
    // sentence.
    Check.equal(source("надо rebase onto main before the release cut today"), .english,
                "9.5% кириллицы — английский")

    // 5.3% — well clear.
    Check.equal(source("ок, merge the pull request into main branch now"), .english,
                "5.3% кириллицы — английский")

    Check.equal(source("please review the pull request now"), .english,
                "чистый английский")
    Check.equal(source("задеплой на staging через CI"), .russian,
                "русский с терминами (62% кириллицы)")
}

// MARK: - Nothing to go on

Check.suite("Нечего определять") {
    for text in ["", "   ", "\n\t "] {
        Check.expect(LanguageDetector.detect(text, in: ruEn) == nil,
                     "пустой ввод не даёт результата")
    }
    for text in ["12345", "!!! ??? ...", "3.14 + 2"] {
        Check.expect(LanguageDetector.detect(text, in: ruEn)?.isConfident == false,
                     "«\(text)» — направление не определено уверенно")
    }
    // Greek belongs to neither language, so the Latin word decides.
    Check.equal(source("λόγος alpha"), .english, "буквы вне пары не голосуют")
}

// MARK: - Languages written in more than one script

Check.suite("Японский: кана и кандзи вместе") {
    let jaEn = LanguagePair(first: .japanese, second: .english)
    Check.equal(source("ありがとう", jaEn), .japanese, "только кана")
    // A single-script model of Japanese would miss this entirely.
    Check.equal(source("日本語", jaEn), .japanese, "только кандзи")
    Check.equal(source("今日はいい天気ですね", jaEn), .japanese, "как японский пишется на самом деле")
    Check.equal(source("nice weather today", jaEn), .english, "английский в той же паре")
}

Check.suite("Две неевропейские письменности") {
    let arRu = LanguagePair(first: .arabic, second: .russian)
    Check.equal(source("مرحبا بالعالم", arRu), .arabic, "арабский")
    Check.equal(source("привет мир", arRu), .russian, "русский")
}

// MARK: - Which method a pair gets

Check.suite("Выбор метода по паре") {
    for pair in [LanguagePair(first: .russian, second: .english),
                 LanguagePair(first: .japanese, second: .english),
                 LanguagePair(first: .arabic, second: .french),
                 LanguagePair(first: .korean, second: .russian)] {
        Check.expect(pair.scriptsDiffer,
                     "\(pair.first.badge)⇄\(pair.second.badge) — считаем по написанию")
    }

    // Pairs that a naive "is there Cyrillic?" test would get wrong every single time.
    for pair in [LanguagePair(first: .english, second: .german),
                 LanguagePair(first: .russian, second: .ukrainian),
                 LanguagePair(first: .japanese, second: .chinese)] {
        Check.expect(!pair.scriptsDiffer,
                     "\(pair.first.badge)⇄\(pair.second.badge) — считать по написанию нельзя")
    }
}

Check.suite("Общая письменность: работает модель") {
    let deEn = LanguagePair(first: .german, second: .english)
    Check.equal(source("Die Besprechung wurde auf Donnerstag verschoben", deEn), .german, "немецкий")
    Check.equal(source("The meeting has been moved to Thursday", deEn), .english, "английский")
}

// MARK: - Every shipped language must be classifiable

Check.suite("Все языки объявили письменность") {
    for code in LanguageCode.allCases {
        Check.expect(!code.scripts.isEmpty, "\(code.rawValue) объявил письменность")
        Check.expect(!code.scripts.contains(.other), "\(code.rawValue) — письменность определена")
    }
    Check.expect(!LanguagePair(first: .english, second: .english).isValid,
                 "пара из одного языка недопустима")
}

Check.report()
