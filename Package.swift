// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SmallProductsGenerator",
	platforms: [.macOS(.v12)],
    dependencies: [
		.package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "3.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "SmallProductsGenerator",
			dependencies: [
				.product(name: "Crypto", package: "swift-crypto"),
				.target(name: "NutritionPrivacyModels"),
				.target(name: "OpenFoodFactsModels"),
				.target(name: "Core")
			]
		),
        .testTarget(
            name: "SmallProductsGeneratorTests",
            dependencies: ["SmallProductsGenerator"]
		),
		.executableTarget(name: "ProductsDownloader"),
		.target(
			name: "NutritionPrivacyModels",
			dependencies: ["Core"]
		),
		.target(
			name: "OpenFoodFactsModels",
			dependencies: ["Core"]
		),
		.testTarget(
			name: "OpenFoodFactsModelsTests",
			dependencies: ["OpenFoodFactsModels"],
			resources: [.process("Resources")]
		),
		.target(name: "Core")
    ]
)
