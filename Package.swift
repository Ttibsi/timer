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
            exclude: [
                "./rawterm/examples",
                "./rawterm/tests",
            ],
            sources: [
                "./rawterm/rawterm/color.cpp",
                "./rawterm/rawterm/core.cpp",
                "./rawterm/rawterm/cursor.cpp",
                "./rawterm/rawterm/screen.cpp",
                "./rawterm/rawterm/text.cpp",
            ],
            publicHeadersPath: "./rawterm",
            cxxSettings: [
                .headerSearchPath("./rawterm/"),
            ],
        ),
    ],
    swiftLanguageModes: [.v6],
    cxxLanguageStandard: .cxx20,
)
