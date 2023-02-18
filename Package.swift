// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SmallProductsGenerator",
	platforms: [.macOS(.v10_15)],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "3.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
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
