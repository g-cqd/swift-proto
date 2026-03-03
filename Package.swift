// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Proto",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "Proto",
            targets: ["Proto"]
        ),
        .library(
            name: "ProtoCore",
            targets: ["ProtoCore"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            exact: "602.0.0"
        ),
    ],
    targets: [
        .target(
            name: "ProtoMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ],
            path: "ProtoCore/Sources/ProtoMacros",
            swiftSettings: swiftSettings
        ),
        .macro(
            name: "ProtoMacroPlugin",
            dependencies: [
                "ProtoMacros",
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            path: "ProtoCore/Sources/ProtoMacroPlugin",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "ProtoCore",
            dependencies: ["ProtoMacroPlugin"],
            path: "ProtoCore/Sources/Core",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "Proto",
            dependencies: ["ProtoCore"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProtoTests",
            dependencies: [
                "ProtoMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
            ],
            path: "ProtoTests/Tests/MacroTests",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProtoIntegrationTests",
            dependencies: [
                "Proto",
                "ProtoCore",
            ],
            path: "Tests/ProtoIntegrationTests",
            swiftSettings: swiftSettings
        ),
    ]
)

private let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6)
]
