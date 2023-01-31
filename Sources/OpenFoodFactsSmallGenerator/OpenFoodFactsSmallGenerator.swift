import Foundation
@main
public struct OpenFoodFactsSmallGenerator {
    public static func main() async throws{
		let downloader = ProductDownloader(session: .shared, language: .german, downloadDirectory: FileManager.default.temporaryDirectory)
		do {
//			try await downloader.start()
			try await ProductExtractor().start(source: .init(fileURLWithPath: "openfoodfacts-products.jsonl"), target: .init(fileURLWithPath: "./public"))
		} catch {
			print("Download failed with error: \(error)")
		}
		
    }
}
