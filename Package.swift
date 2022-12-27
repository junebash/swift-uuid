// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "swift-uuid",
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
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warn-concurrency"])]
    ),
    .testTarget(
      name: "UUIDTests",
      dependencies: [
        "UUID"
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warn-concurrency"])]
    )
  ]
)
