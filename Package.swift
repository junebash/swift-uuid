// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "swift-uuid",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
    .tvOS(.v16),
    .watchOS(.v9),
    .macCatalyst(.v16)
  ],
  products: [
    .library(
      name: "UUID",
      targets: ["UUID"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/junebash/swift-lock", branch: "main")
  ],
  targets: [
    .target(
      name: "UUID",
      dependencies: [
        .product(name: "Lock", package: "swift-lock")
      ]
    ),
    .testTarget(
      name: "UUIDTests",
      dependencies: [
        "UUID"
      ]
    )
  ]
)
