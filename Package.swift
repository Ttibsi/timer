// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "timer",
    targets: [
        .executableTarget(
            name: "timer",
            dependencies: ["CRawterm"],
            swiftSettings: [.interoperabilityMode(.Cxx)],
        ),
        .testTarget(
            name: "timerTests",
            dependencies: ["timer"]
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
