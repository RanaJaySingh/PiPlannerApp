// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PiPlannerCore",
    platforms: [
        .macOS(.v13),
        .iOS(.v17)
    ],
    products: [
        .library(name: "PiPlannerCore", targets: ["PiPlannerCore"])
    ],
    targets: [
        .target(
            name: "PiPlannerCore",
            path: "Sources/PiPlannerCore"
        ),
        .testTarget(
            name: "PiPlannerCoreTests",
            dependencies: ["PiPlannerCore"],
            path: "Tests/PiPlannerCoreTests"
        )
    ]
)
