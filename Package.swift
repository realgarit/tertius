// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "tertius",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "Tertius", targets: ["App"]),
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Application", targets: ["Application"]),
        .library(name: "Infrastructure", targets: ["Infrastructure"]),
    ],
    targets: [
        // Pure decision logic. Imports only Foundation.
        .target(name: "Domain"),

        // Use cases + Ports (protocols). Depends on Domain only.
        .target(
            name: "Application",
            dependencies: ["Domain"]
        ),

        // Adapters: event tap, CGEvent poster, UserDefaults, AX, SMAppService, GitHub.
        .target(
            name: "Infrastructure",
            dependencies: ["Application", "Domain"]
        ),

        // Composition root: MenuBarExtra app + Settings UI.
        // The asset catalog is compiled into the .app by actool at packaging
        // time (scripts/package-app.sh), not by SwiftPM, so it is excluded here.
        .executableTarget(
            name: "App",
            dependencies: ["Application", "Infrastructure", "Domain"],
            exclude: ["Resources/Assets.xcassets"]
        ),

        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "ApplicationTests", dependencies: ["Application", "Domain"]),
        .testTarget(name: "InfrastructureTests", dependencies: ["Infrastructure", "Application", "Domain"]),
    ]
)
