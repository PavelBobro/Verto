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
        // The popover model and the translation wrapper, kept out of the executable
        // so their rules can be exercised without launching the app.
        .target(
            name: "VertoAppModel",
            dependencies: ["VertoCore"],
            path: "Sources/VertoAppModel",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "Verto",
            dependencies: ["VertoCore", "VertoAppModel"],
            path: "Sources/Verto",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "VertoCoreTests",
            dependencies: ["VertoCore"],
            path: "Tests/VertoCoreTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "VertoAppModelTests",
            dependencies: ["VertoCore", "VertoAppModel"],
            path: "Tests/VertoAppModelTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
