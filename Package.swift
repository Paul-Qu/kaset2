// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "kaset2",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "KasetCore", targets: ["KasetCore"]),
        .executable(name: "KasetApp", targets: ["KasetApp"]),
        .executable(name: "api-explorer", targets: ["APIExplorer"]),
    ],
    targets: [
        .target(name: "KasetCore"),
        .executableTarget(name: "KasetApp", dependencies: ["KasetCore"]),
        .executableTarget(name: "APIExplorer", dependencies: ["KasetCore"]),
        .testTarget(name: "KasetCoreTests", dependencies: ["KasetCore"]),
    ]
)
