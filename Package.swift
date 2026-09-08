// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Verto",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(
            name: "Verto",
            path: "Sources/Verto",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
