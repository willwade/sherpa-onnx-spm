// swift-tools-version: 5.9

import PackageDescription

let version = "1.13.5"
let checksumCombined = "66fbec263ff19b26343a28a1e30be58ae642d2feb6c306fdaa3d6df9e5257bfd"

let package = Package(
    name: "SherpaOnnx",
    platforms: [
        .iOS(.v13),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "SherpaOnnx",
            targets: ["SherpaOnnx"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "sherpa-onnx",
            url: "https://github.com/willwade/sherpa-onnx-spm/releases/download/\(version)/sherpa-onnx.xcframework.zip",
            checksum: checksumCombined
        ),
        .target(
            name: "SherpaOnnx",
            dependencies: ["sherpa-onnx"],
            path: "Sources/SherpaOnnx",
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedFramework("Accelerate"),
            ]
        ),
    ]
)
