import VertoCore
import Foundation
import ServiceManagement

/// User preferences. Deliberately few: anything that does not change how fast a
/// translation appears did not earn a control.
@MainActor
final class Settings: ObservableObject {

    static let shared = Settings()

    @Published var pair: LanguagePair {
        didSet {
            guard pair != oldValue else { return }
            store(pair, as: .pair)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != oldValue else { return }
            if case .failure(let error) = LoginItem.set(launchAtLogin) {
                lastError = error.localizedDescription
                launchAtLogin = LoginItem.isEnabled
            } else {
                lastError = nil
            }
        }
    }

    @Published var hotKey: HotKeyCombo {
        didSet {
            guard hotKey != oldValue else { return }
            store(hotKey, as: .hotKey)
        }
    }

    /// Set when the system refuses the combination, which means something else owns it.
    @Published var hotKeyTaken = false

    /// Size of the text being translated and of the translation, in points.
    /// A single word at the system's 13 pt is easy to lose in a 360-point window.
    static let textSizes: ClosedRange<Double> = 13...28

    @Published var textSize: Double {
        didSet {
            guard textSize != oldValue else { return }
            UserDefaults.standard.set(textSize, forKey: "textSize")
        }
    }

    @Published var appLanguage: AppLanguage {
        didSet {
            guard appLanguage != oldValue else { return }
            UserDefaults.standard.set(appLanguage.rawValue, forKey: "appLanguage")
            L.use(appLanguage)
        }
    }

    /// Surfaced in the settings window; login items can legitimately fail on an
    /// ad-hoc signed build, and silence would look like the toggle is broken.
    @Published var lastError: String?

    private enum Key: String {
        case pair = "languagePair"
        case hotKey = "hotKey"
    }

    private init() {
        pair = Self.load(LanguagePair.self, as: .pair) ?? .default
        hotKey = Self.load(HotKeyCombo.self, as: .hotKey) ?? .default
        launchAtLogin = LoginItem.isEnabled
        let storedSize = UserDefaults.standard.double(forKey: "textSize")
        textSize = Self.textSizes.contains(storedSize) ? storedSize : Self.textSizes.lowerBound
        appLanguage = UserDefaults.standard.string(forKey: "appLanguage")
            .flatMap(AppLanguage.init(rawValue:)) ?? .system
        L.use(appLanguage)
    }

    private static func load<T: Decodable>(_ type: T.Type, as key: Key) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key.rawValue) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func store<T: Encodable>(_ value: T, as key: Key) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key.rawValue)
    }
}
