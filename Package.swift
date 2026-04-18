// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "smart-dock-sort",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "smart-dock-sort", targets: ["SmartDockSort"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.1"),
    ],
    targets: [
        .executableTarget(
            name: "SmartDockSort",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "./Info.plist",
                ]),
            ]
        ),
    ]
)
