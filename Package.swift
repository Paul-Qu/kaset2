// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "kaset2",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "KasetCore", targets: ["KasetCore"]),
        .executable(name: "api-explorer", targets: ["APIExplorer"]),
        .executable(name: "KasetApp", targets: ["KasetApp"]),
    ],
    targets: [
        .target(name: "KasetCore"),
        .executableTarget(name: "APIExplorer", dependencies: ["KasetCore"]),
        .executableTarget(name: "KasetApp", dependencies: ["KasetCore"]),
        .testTarget(name: "KasetCoreTests", dependencies: ["KasetCore"]),
    ]
)
