// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BalanceApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "BalanceApp",
            targets: ["BalanceApp"]
        )
    ],
    dependencies: [
        // Add dependencies here if needed
    ],
    targets: [
        .target(
            name: "BalanceApp",
            dependencies: [],
            path: "Sources/BalanceApp"
        ),
        .testTarget(
            name: "BalanceAppTests",
            dependencies: ["BalanceApp"],
            path: "Tests/BalanceAppTests"
        )
    ]
)