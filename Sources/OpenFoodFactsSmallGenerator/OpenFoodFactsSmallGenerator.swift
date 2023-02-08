import Foundation
@main
public struct OpenFoodFactsSmallGenerator {
    public static func main() async throws{
		do {
			try await ProductExtractor().start(source: .init(fileURLWithPath: "openfoodfacts-products.jsonl"), target: .init(fileURLWithPath: "./public"))
		} catch {
			print("Download failed with error: \(error)")
		}
		
    }
}
