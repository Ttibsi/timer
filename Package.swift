// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "timer",
    targets: [
        .executableTarget(
            name: "timer",
            dependencies: ["CRawterm", "CRawtermBridge"],
            swiftSettings: [.interoperabilityMode(.Cxx)],
        ),
        .testTarget(
            name: "timerTests",
            dependencies: ["timer"]
        ),
        
        .target(
            name: "CRawtermBridge",
            dependencies: ["CRawterm"],
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath("../CRawterm/rawterm"),
            ],
        ),

        .target(
            name: "CRawterm",
            dependencies: [],
            path: "Sources/CRawterm",
            sources: [
                "./rawterm/color.cpp",
                "./rawterm/core.cpp",
                "./rawterm/cursor.cpp",
                "./rawterm/screen.cpp",
                "./rawterm/text.cpp",
            ],
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath("."),
            ],
        ),
    ],
    swiftLanguageModes: [.v6],
    cxxLanguageStandard: .cxx20,
)
