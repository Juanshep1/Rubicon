// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RubiconEngine",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "RubiconEngine", targets: ["RubiconEngine"]),
    ],
    targets: [
        .target(name: "RubiconEngine", path: "Sources/RubiconEngine"),
        .testTarget(name: "RubiconEngineTests", dependencies: ["RubiconEngine"], path: "Tests/RubiconEngineTests"),
    ]
)
