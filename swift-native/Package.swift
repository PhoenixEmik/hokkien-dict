// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TaigiDictNative",
    defaultLocalization: "zh-Hant",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "TaigiDictCore",
            targets: ["TaigiDictCore"]
        ),
        .library(
            name: "TaigiDictUI",
            targets: ["TaigiDictUI"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/PhoenixEmik/SwiftyOpenCC.git",
            revision: "53f200cebe40eade3ebda025b0e8980e08cf23fa"
        ),
        .package(
            url: "https://github.com/groue/GRDB.swift.git",
            exact: "7.10.0"
        ),
        .package(
            url: "https://github.com/weichsel/ZIPFoundation.git",
            exact: "0.9.20"
        ),
    ],
    targets: [
        .target(
            name: "TaigiDictCore",
            dependencies: [
                .product(name: "OpenCC", package: "SwiftyOpenCC"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ]
        ),
        .target(
            name: "TaigiDictUI",
            dependencies: ["TaigiDictCore"],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "TaigiDictCoreTests",
            dependencies: [
                "TaigiDictCore",
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ]
        ),
        .testTarget(
            name: "TaigiDictUITests",
            dependencies: [
                "TaigiDictCore",
                "TaigiDictUI",
            ]
        ),
    ]
)
