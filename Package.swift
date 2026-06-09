// swift-tools-version: 5.9

import PackageDescription

let version = "1.13.3"
let checksumCombined = "2a7e9e38d93253da8deee07849e94c50a3a9b46db26566526c895f851ee7b942"

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
