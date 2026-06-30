// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VioletNotebook",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "VioletNotebook", targets: ["VioletNotebook"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6")
    ],
    targets: [
        .executableTarget(
            name: "VioletNotebook",
            dependencies: ["Yams"],
            path: "Sources/VioletNotebook"
        ),
        .testTarget(
            name: "VioletNotebookTests",
            dependencies: ["VioletNotebook"],
            path: "Tests/VioletNotebookTests"
        )
    ]
)
