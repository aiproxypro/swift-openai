// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AIProxy_OpenAI",
    platforms: [
         .iOS(.v15),
         .macOS(.v13),
         .visionOS(.v1),
         .watchOS(.v9)
    ],
    products: [
        .library(
            name: "AIProxy_OpenAI",
            targets: ["AIProxy_OpenAI"]),
    ],
    targets: [
        .target(
            name: "AIProxy_OpenAI",
            resources: [
                .process("Resources/PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
