// swift-tools-version:5.3

import PackageDescription

let package = Package(
	name: "LNPropertyListEditor",
	platforms: [
		.macOS(.v10_13)
	],
	products: [
		.library(
			name: "LNPropertyListEditor",
			type: .dynamic,
			targets: ["LNPropertyListEditor"]),
		.library(
			name: "LNPropertyListEditor-Static",
			type: .static,
			targets: ["LNPropertyListEditor"]),
	],
	dependencies: [],
	targets: [
		.target(
			name: "LNPropertyListEditor",
			dependencies: [],
			path: "LNPropertyListEditor",
			exclude: [
				"LNPropertyListEditorExample",
				"Supplements",
				"LNPropertyListEditor/Info.plist"
			],
			resources: [
				.process("LNPropertyListEditor/Assets.xcassets"),
				.process("LNPropertyListEditor/Views/LNPropertyListEditorOutline.xib")
			],
			publicHeadersPath: "include",
			cSettings: [
				.headerSearchPath("."),
				.headerSearchPath("LNPropertyListEditor"),
			]),
	]
)
