// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "lg2",
    platforms: [
	.iOS(.v13),
	.tvOS(.v13),
	.watchOS(.v6),
	.macCatalyst(.v13),
	.visionOS(.v1)
    ],
    products: [
	.library(
	    name: "lg2",
	    type: .dynamic, targets: ["examples", "examples-swift", "git"],
	),
    ],
    dependencies: [
	.package(id: "pyto.apple-git2", from: "1.9.0"),
	.package(id: "pyto.apple-ssh2", from: "1.11.1"),
	.package(id: "pyto.apple-ios_system", from: "3.0.0"),
	.package(url: "https://github.com/xxlabaza/SshConfig.git", from: "1.0.1")
    ],
    targets: [
	.target(
	    name: "git",
	    dependencies: [
		.product(name: "git2", package: "pyto.apple-git2"),
		.product(name: "ssh2", package: "pyto.apple-ssh2"),
	    ],
	    publicHeadersPath: "include"
	),
	.target(
	    name: "examples",
	    dependencies: [
		.product(name: "git2", package: "pyto.apple-git2"),
		.product(name: "ssh2", package: "pyto.apple-ssh2"),
		.target(name: "examples-swift")
	    ],
	    publicHeadersPath: "include"
	),
	.target(
	    name: "examples-swift",
	    dependencies: [
		.product(name: "ios_system", package: "pyto.apple-ios_system"),
		.product(name: "SshConfig", package: "SshConfig"),
		.target(name: "git")
	    ],
	),
    ]
)

