// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Awake",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Awake",
            path: "Sources/Awake"
        )
    ]
)