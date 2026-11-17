// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NetworkLayer",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "NetworkLayer", targets: ["NetworkLayer"])
    ],
    targets: [
        // Production code
        .target(name: "NetworkLayer", path: "Sources/NetworkLayer"),

        // Shared fixtures, mocks and a local HTTP server used by the test targets
        .target(name: "TestSupport", dependencies: ["NetworkLayer"], path: "Tests/TestSupport"),

        // Tests
        .testTarget(name: "UnitTests",
                    dependencies: ["NetworkLayer", "TestSupport"],
                    path: "Tests/UnitTests"),
        .testTarget(name: "IntegrationTests",
                    dependencies: ["NetworkLayer", "TestSupport"],
                    path: "Tests/IntegrationTests"),
        .testTarget(name: "EndToEndTests",
                    dependencies: ["NetworkLayer", "TestSupport"],
                    path: "Tests/EndToEndTests"),
    ]
)
