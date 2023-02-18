import Foundation
import OpenFoodFactsModels
import NutritionPrivacyModels

@main
public struct OpenFoodFactsSmallGenerator {
    public static func main() async throws{
		do {
			let nutritionPrivacyExtractor = ProductExtractor<NutritionPrivacyModels.ProductPreview>()
			let nutritionPrivacyPackages = try await nutritionPrivacyExtractor.start(source: .init(fileURLWithPath: "openfoodfacts-products.jsonl"),
																				target: .init(fileURLWithPath: "./public"),
																				datasource: .nutritionPrivacy)
			
			let openFoodFactsExtractor = ProductExtractor<OpenFoodFactsModels.Product>()
			let openFoodFactsPackages = try await openFoodFactsExtractor.start(source: .init(fileURLWithPath: "openfoodfacts-products.jsonl"),
																				target: .init(fileURLWithPath: "./public"),
																				datasource: .openFoodFacts)
		} catch {
			print("Download failed with error: \(error)")
		}
		
    }
}
