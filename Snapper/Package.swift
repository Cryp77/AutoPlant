// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Snapper",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Snapper", path: "Sources/Snapper")
    ]
)
