import AppKit
import Vision
import VertoCore

/// Reads text out of an image.
enum TextRecognizer {

    /// Languages are ordered, and the order matters: Vision uses it to break ties, so
    /// the pair the user actually translates goes first.
    static func read(_ image: NSImage, preferring pair: LanguagePair) async -> String? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = languages(for: pair)

        do {
            let observations = try await request.perform(on: cgImage)
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            let text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
            NSLog("Verto: text recognition failed — \(error)")
            return nil
        }
    }

    private static func languages(for pair: LanguagePair) -> [Locale.Language] {
        // Vision names its languages with a region attached — "ar-SA", "vi-VT",
        // "zh-TW" — so comparing whole identifiers against "ar" or "vi" silently
        // matches nothing and drops the language from the request.
        let supported = Set(RecognizeTextRequest().supportedRecognitionLanguages
            .compactMap { $0.languageCode?.identifier })

        let wanted = [pair.first, pair.second]
            .filter { supported.contains($0.rawValue) }
            .map(\.language)

        // An empty list makes Vision fall back to English alone, which would be worse
        // than reading with whatever it does support.
        return wanted.isEmpty ? [Locale.Language(identifier: "en")] : wanted
    }
}
