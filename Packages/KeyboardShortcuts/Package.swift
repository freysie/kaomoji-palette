// swift-tools-version:5.7
import PackageDescription

let package = Package(
	name: "KeyboardShortcuts",
	platforms: [
		.macOS(.v10_13)
	],
	products: [
		.library(
			name: "KeyboardShortcuts",
			targets: [
				"KeyboardShortcuts"
			]
		)
	],
	targets: [
		.target(
			name: "KeyboardShortcuts"
		)
	]
)
