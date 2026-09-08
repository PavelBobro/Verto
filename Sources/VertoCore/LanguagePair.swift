import Foundation

/// Writing systems, used to decide how a language is detected (FR-1).
public enum Script: Hashable {
    case latin, cyrillic, greek, arabic, hebrew
    case han, kana, hangul, devanagari, thai
    case other

    public init?(_ scalar: Unicode.Scalar) {
        guard CharacterSet.letters.contains(scalar) else { return nil }
        switch scalar.value {
        case 0x0041...0x005A, 0x0061...0x007A, 0x00C0...0x024F: self = .latin
        case 0x0370...0x03FF:                                   self = .greek
        case 0x0400...0x052F:                                   self = .cyrillic
        case 0x0590...0x05FF:                                   self = .hebrew
        case 0x0600...0x06FF, 0x0750...0x077F:                  self = .arabic
        case 0x0900...0x097F:                                   self = .devanagari
        case 0x0E00...0x0E7F:                                   self = .thai
        case 0x3040...0x30FF:                                   self = .kana
        case 0xAC00...0xD7AF, 0x1100...0x11FF:                  self = .hangul
        case 0x4E00...0x9FFF, 0x3400...0x4DBF:                  self = .han
        default:                                                self = .other
        }
    }
}

/// The languages Apple's on-device translation covers. Each carries the scripts its
/// text is actually written in — Japanese needs three, and detection would misread it
/// with only one.
public enum LanguageCode: String, CaseIterable, Codable, Sendable, Hashable {
    case arabic     = "ar"
    case chinese    = "zh"
    case dutch      = "nl"
    case english    = "en"
    case french     = "fr"
    case german     = "de"
    case hindi      = "hi"
    case indonesian = "id"
    case italian    = "it"
    case japanese   = "ja"
    case korean     = "ko"
    case polish     = "pl"
    case portuguese = "pt"
    case russian    = "ru"
    case spanish    = "es"
    case thai       = "th"
    case turkish    = "tr"
    case ukrainian  = "uk"
    case vietnamese = "vi"

    public var scripts: Set<Script> {
        switch self {
        case .russian, .ukrainian: [.cyrillic]
        case .arabic:              [.arabic]
        case .hindi:               [.devanagari]
        case .thai:                [.thai]
        case .korean:              [.hangul]
        case .chinese:             [.han]
        case .japanese:            [.kana, .han]
        default:                   [.latin]
        }
    }

    public var badge: String { rawValue.uppercased() }

    /// Named in the language the interface is in, which is not necessarily the
    /// system's: someone reading Verto in English should see "Russian", not
    /// "Русский", even on a Russian Mac.
    public func name(in locale: Locale) -> String {
        locale.localizedString(forLanguageCode: rawValue)?
            .capitalized(with: locale) ?? rawValue
    }

    public var localizedName: String { name(in: .current) }

    public var language: Locale.Language { Locale.Language(identifier: rawValue) }
}

/// The pair the user picked. Direction is never stored — it is decided per input.
public struct LanguagePair: Equatable, Codable, Sendable {
    public var first: LanguageCode
    public var second: LanguageCode

    public init(first: LanguageCode, second: LanguageCode) {
        self.first = first
        self.second = second
    }

    public static let `default` = LanguagePair(first: .russian, second: .english)

    public var isValid: Bool { first != second }

    /// True when the exact script method of FR-1 applies: no writing system is shared,
    /// so counting characters can tell the two apart with certainty.
    public var scriptsDiffer: Bool { first.scripts.isDisjoint(with: second.scripts) }
}
