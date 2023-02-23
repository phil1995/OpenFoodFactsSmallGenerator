import Foundation
import OpenFoodFactsModels
import NutritionPrivacyModels

@main
public struct OpenFoodFactsSmallGenerator {
    public static func main() async throws{
		let target = URL(fileURLWithPath: "./public")
		var packages = [LanguagePackage]()
		let nutritionPrivacyExtractor = ProductExtractor<NutritionPrivacyModels.ProductPreview>()
		let nutritionPrivacyPackages = try await nutritionPrivacyExtractor.start(source: .init(fileURLWithPath: "nutritionprivacy-products.jsonl"),
																				target: target,
																				datasource: .nutritionPrivacy)
		let openFoodFactsExtractor = ProductExtractor<OpenFoodFactsModels.Product>()
		let openFoodFactsPackages = try await openFoodFactsExtractor.start(source: .init(fileURLWithPath: "openfoodfacts-products.jsonl"),
																				target: target,	
																				 datasource: .openFoodFacts)
		packages.append(contentsOf: nutritionPrivacyPackages)
		packages.append(contentsOf: openFoodFactsPackages)
		let data = try JSONEncoder().encode(packages)
		try data.write(to: target.appendingPathComponent("overview.json"))
    }
}
