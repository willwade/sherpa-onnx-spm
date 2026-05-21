// swift-tools-version: 5.9

import PackageDescription

let version = "1.13.2"
let checksumSherpaOnnx = "6d30b7d890d6df356b9a7fbf236893a63539973dcc32caabd248f21b6b0ae50a"
let checksumOnnxRuntime = "5bd675cb4f149130dcb3ac370418079681d90f50969f10e256523218b054acfd"

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
            checksum: checksumSherpaOnnx
        ),
        .binaryTarget(
            name: "onnxruntime",
            url: "https://github.com/willwade/sherpa-onnx-spm/releases/download/\(version)/onnxruntime.xcframework.zip",
            checksum: checksumOnnxRuntime
        ),
        .target(
            name: "SherpaOnnx",
            dependencies: ["sherpa-onnx", "onnxruntime"],
            path: "Sources/SherpaOnnx",
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedFramework("Accelerate"),
            ]
        ),
    ]
)
