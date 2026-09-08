import Foundation

/// A test runner in thirty lines.
///
/// `swift test` needs XCTest or swift-testing, and neither ships with the Command
/// Line Tools — only with Xcode. Verto's whole point is that it builds without Xcode,
/// so its tests should run without Xcode too.
enum Check {

    nonisolated(unsafe) private static var failures: [String] = []
    nonisolated(unsafe) private static var checks = 0
    nonisolated(unsafe) private static var group = ""

    static func suite(_ name: String, _ body: () -> Void) {
        group = name
        body()
    }

    static func expect(_ condition: Bool, _ description: String,
                       file: StaticString = #file, line: UInt = #line) {
        checks += 1
        guard !condition else { return }
        failures.append("\(group) → \(description)   (\(URL(fileURLWithPath: "\(file)").lastPathComponent):\(line))")
    }

    static func equal<T: Equatable>(_ actual: T, _ expected: T, _ description: String,
                                    file: StaticString = #file, line: UInt = #line) {
        checks += 1
        guard actual != expected else { return }
        failures.append("\(group) → \(description)\n      ожидалось: \(expected)\n      получено:  \(actual)   (\(URL(fileURLWithPath: "\(file)").lastPathComponent):\(line))")
    }

    static func report() -> Never {
        if failures.isEmpty {
            print("✓ \(checks) проверок пройдено")
            exit(0)
        }
        print("✗ \(failures.count) из \(checks) проверок не прошли\n")
        for failure in failures { print("  • \(failure)") }
        exit(1)
    }
}
