import Foundation
import NaturalLanguage

/// Which language of a pair a piece of text is written in.
///
/// The method is chosen from the pair itself (FR-1). When the two languages use
/// different scripts, counting characters beats any model: it is exact on short
/// strings like "OK" or "Pizza", where `NLLanguageRecognizer` is unreliable.
/// Only when both sides share a script (en/de, ru/uk) do we fall back to the model.
enum LanguageDetector {

    struct Result {
        let source: LanguageCode
        let target: LanguageCode
        /// False when the caller should warn the user (FR-6).
        let isConfident: Bool
    }

    /// Share of "own script" letters above which the text counts as that language.
    ///
    /// Deliberately low: everyday Russian is full of Latin technical terms
    /// ("задеплой на staging через CI"), and a 50% threshold would send those
    /// the wrong way.
    static let scriptThreshold = 0.15

    static func detect(_ text: String, in pair: LanguagePair) -> Result? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if pair.scriptsDiffer {
            return detectByScript(trimmed, in: pair)
        }
        return detectByModel(trimmed, in: pair)
    }

    // MARK: - Different scripts

    private static func detectByScript(_ text: String, in pair: LanguagePair) -> Result {
        var firstCount = 0
        var secondCount = 0

        for scalar in text.unicodeScalars {
            guard let script = Script(scalar) else { continue }
            if pair.first.scripts.contains(script)  { firstCount += 1 }
            if pair.second.scripts.contains(script) { secondCount += 1 }
        }

        // Only letters belonging to one of the two languages count. Everything else —
        // digits, punctuation, a stray Greek letter — carries no evidence either way.
        let decisive = firstCount + secondCount
        guard decisive > 0 else {
            return Result(source: pair.first, target: pair.second, isConfident: false)
        }

        let firstShare = Double(firstCount) / Double(decisive)
        let isFirst = firstShare >= scriptThreshold

        // Near the threshold the text is genuinely mixed, so flag it (FR-6).
        let margin = abs(firstShare - scriptThreshold)
        let confident = margin > 0.08 || firstShare > 0.5

        return isFirst
            ? Result(source: pair.first, target: pair.second, isConfident: confident)
            : Result(source: pair.second, target: pair.first, isConfident: confident)
    }

    // MARK: - Shared script

    private static func detectByModel(_ text: String, in pair: LanguagePair) -> Result {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        let hypotheses = recognizer.languageHypotheses(withMaximum: 4)
        let firstScore = hypotheses[NLLanguage(pair.first.rawValue)] ?? 0
        let secondScore = hypotheses[NLLanguage(pair.second.rawValue)] ?? 0

        let isFirst = firstScore >= secondScore
        let winner = max(firstScore, secondScore)
        let confident = winner > 0.6 && abs(firstScore - secondScore) > 0.2

        return isFirst
            ? Result(source: pair.first, target: pair.second, isConfident: confident)
            : Result(source: pair.second, target: pair.first, isConfident: confident)
    }
}
