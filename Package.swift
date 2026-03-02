// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "kaset2",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "KasetCore", targets: ["KasetCore"]),
        .executable(name: "api-explorer", targets: ["APIExplorer"]),
    ],
    targets: [
        .target(name: "KasetCore"),
        .executableTarget(name: "APIExplorer", dependencies: ["KasetCore"]),
        .testTarget(name: "KasetCoreTests", dependencies: ["KasetCore"]),
    ]
)
