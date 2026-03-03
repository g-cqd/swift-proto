// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ProtoDemoPackage",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "ProtoDemoDomain",
            targets: ["ProtoDemoDomain"]
        ),
        .library(
            name: "ProtoAutoOpsDomain",
            targets: ["ProtoAutoOpsDomain"]
        ),
    ],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .target(
            name: "ProtoDemoDomain",
            dependencies: [
                .product(name: "Proto", package: "swift-proto")
            ],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "ProtoDemoApp",
            dependencies: [
                "ProtoDemoDomain"
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProtoDemoDomainTests",
            dependencies: [
                "ProtoDemoDomain"
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "ProtoAutoOpsDomain",
            dependencies: [
                .product(name: "Proto", package: "swift-proto")
            ],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "ProtoAutoOpsApp",
            dependencies: [
                "ProtoAutoOpsDomain"
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProtoAutoOpsDomainTests",
            dependencies: [
                "ProtoAutoOpsDomain"
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProtoDemoTests",
            dependencies: [
                "ProtoDemoDomain",
                "ProtoAutoOpsDomain",
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

private let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6)
]
