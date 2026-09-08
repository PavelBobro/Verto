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

    /// Surfaced in the settings window; login items can legitimately fail on an
    /// ad-hoc signed build, and silence would look like the toggle is broken.
    @Published var lastError: String?

    private enum Key: String { case pair = "languagePair" }

    private init() {
        pair = Self.load(LanguagePair.self, as: .pair) ?? .default
        launchAtLogin = LoginItem.isEnabled
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
