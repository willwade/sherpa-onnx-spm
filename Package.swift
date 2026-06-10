// swift-tools-version: 5.9

import PackageDescription

let version = "1.13.4"
let checksumCombined = "a7d1bba822da9ac044271041b0cd579337e028a8b7c5d0971de2368d3233f7ae"

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
