// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ChatServerForSwift",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
		// Redis kv cache
		.package(url: "https://github.com/vapor/redis.git", from: "4.0.0"),
		// database -> ORM
		.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
		.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
		// Protobuf
		.package(url: "https://github.com/apple/swift-protobuf.git", from: "1.27.0")
    ],
    targets: [
        .executableTarget(
            name: "ChatServerForSwift",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
				.product(name: "Redis", package: "redis"),
				.product(name: "Fluent", package: "fluent"),
				.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
				.product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ChatServerForSwiftTests",
            dependencies: [
                .target(name: "ChatServerForSwift"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
