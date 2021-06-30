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
            checksum: "a05c827038833513d73c375860e146d06ba41954ac1be0112e183e3a1fc7e0ea"
        )
    ]
)
