// swift-tools-version: 5.9

import PackageDescription

let version = "1.13.2"
let checksumSherpaOnnx = "cdacade0f053821a74d557b3aa98bad33d79b3e7be6fc194215775e5501c66a8"
let checksumOnnxRuntime = "e4df27a40ecb6c05304d26142ef32f107843a531ca308e1a860aa87d851c4817"

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
