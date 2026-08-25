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
            exclude: [
                "./rawterm/examples",
                "./rawterm/rawterm/extras",
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
