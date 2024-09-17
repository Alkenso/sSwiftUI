// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sSwiftUI",
    platforms: [.macOS(.v11), .iOS(.v14), .tvOS(.v14), .watchOS(.v7)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "sSwiftUI",
            targets: ["sSwiftUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alkenso/SwiftSpellbook.git", from: "1.1.3"),
    ],
    targets: [
        .target(
            name: "sSwiftUI",
            dependencies: [.product(name: "SpellbookFoundation", package: "SwiftSpellbook")],
            linkerSettings: [.linkedFramework("SwiftUI")]
        )
    ]
)
