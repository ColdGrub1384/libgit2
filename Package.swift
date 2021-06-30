// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "lg2",
    products: [
        .library(name: "lg2", targets: ["lg2"])
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "lg2",
            url: "https://github.com/holzschu/libgit2/releases/download/1.0/lg2.xcframework.zip",
            checksum: "0305194675e6907f014cc06e7bf1198c904ed123fc2cf01b3e3390eef09847b4"
        )
    ]
)
