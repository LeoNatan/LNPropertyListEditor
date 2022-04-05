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
			name: "LNPropertyListEditor_HexFiend",
			dependencies: [],
			path: "HexFiendFramework",
			exclude: [
				
			],
			resources: [],
			publicHeadersPath: "include",
			cSettings: [
				.unsafeFlags(["-w"]),
				.define("HF_NO_PRIVILEGED_FILE_OPERATIONS", to: "1"),
				.headerSearchPath("include"),
				.headerSearchPath("src"),
			]),
		.target(
			name: "LNPropertyListEditor",
			dependencies: [
				"LNPropertyListEditor_HexFiend"
			],
			path: "LNPropertyListEditor",
			exclude: [
				"LNPropertyListEditor/Info.plist"
			],
			resources: [
				.process("LNPropertyListEditor/Assets.xcassets"),
				.process("LNPropertyListEditor/Implementation/LNPropertyListEditorOutline.xib")
			],
			publicHeadersPath: "include",
			cSettings: [
				.headerSearchPath("."),
				.headerSearchPath("LNPropertyListEditor"),
			]),
	]
)
