// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NotchDock",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "NotchDock", path: "Sources/NotchDock")
    ]
)
