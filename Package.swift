// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Ember",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Ember",
            path: "Ember",
            exclude: [
                "Info.plist",
                "Ember.entitlements",
            ],
            resources: [
                .process("Resources/Assets.xcassets")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AVKit"),
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("Cocoa"),
            ]
        )
    ]
)
