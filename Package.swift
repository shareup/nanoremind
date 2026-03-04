// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "nanoremind",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "nanoremind", path: "Sources")
    ]
)
