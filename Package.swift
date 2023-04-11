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
        .package(url: "https://github.com/Alkenso/SwiftConvenience.git", from: "0.0.23"),
    ],
    targets: [
        .target(
            name: "sSwiftUI",
            dependencies: ["SwiftConvenience"],
            linkerSettings: [.linkedFramework("SwiftUI")]
        ),
        .testTarget(
            name: "sSwiftUITests",
            dependencies: ["sSwiftUI"]),
    ]
)
