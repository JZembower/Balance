// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Balance",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Remove library product - iOS apps don't need this
    ],
    dependencies: [
        // Add dependencies here if needed later
    ],
    targets: [
        .executableTarget(
            name: "BalanceApp",
            dependencies: [],
            path: "Sources/BalanceApp",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "BalanceAppTests",
            dependencies: ["BalanceApp"],
            path: "Tests/BalanceAppTests"
        )
    ]
)