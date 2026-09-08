// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Verto",
    platforms: [.macOS("26.0")],
    targets: [
        // Language detection and the language model, with no UI or system
        // dependencies — the part worth testing.
        .target(
            name: "VertoCore",
            path: "Sources/VertoCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "Verto",
            dependencies: ["VertoCore"],
            path: "Sources/Verto",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // Run with `make test`. A plain executable rather than a test target:
        // XCTest and swift-testing both ship only with Xcode, and Verto is meant to
        // be buildable — and checkable — without it.
        .executableTarget(
            name: "VertoCheck",
            dependencies: ["VertoCore"],
            path: "Sources/VertoCheck",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
