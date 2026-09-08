import Foundation
import ServiceManagement

/// Registering a login item requires a code signature the system trusts. Verto ships
/// with an ad-hoc signature for now, so this is the one part of the app that may
/// simply refuse to work — hence the explicit reporting rather than a silent try?.
enum LoginItem {

    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .enabled:        "включён"
        case .notRegistered:  "не зарегистрирован"
        case .notFound:       "не найден"
        case .requiresApproval: "ждёт подтверждения в Системных настройках"
        @unknown default:     "неизвестно"
        }
    }

    @discardableResult
    static func set(_ enabled: Bool) -> Result<Void, Error> {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    /// `Verto --probe-login-item` — registers, reports, unregisters, exits.
    /// Exists so the ad-hoc signature question can be answered without shipping a
    /// half-built settings window first.
    static func runProbe() -> Never {
        let path = Bundle.main.bundleURL.path
        print("bundle:            \(path)")
        print("bundle id:         \(Bundle.main.bundleIdentifier ?? "—")")
        print("status before:     \(statusDescription)")

        switch set(true) {
        case .success:
            print("register():        успех")
        case .failure(let error):
            print("register():        ОШИБКА — \(error)")
            print("status after:      \(statusDescription)")
            exit(1)
        }

        print("status after:      \(statusDescription)")

        switch set(false) {
        case .success:      print("unregister():      успех, система приведена в исходное состояние")
        case .failure(let e): print("unregister():      ОШИБКА — \(e)")
        }
        print("status final:      \(statusDescription)")
        exit(0)
    }
}
