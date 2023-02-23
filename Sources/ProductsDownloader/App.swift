import Foundation

@main
public struct App {
	private enum Endpoints {
		static let openFoodFacts = URL(string: "https://static.openfoodfacts.org/data/openfoodfacts-products.jsonl.gz")!
		static let nutritionPrivacy = URL(string: "https://api.nutritionprivacy.de/productPreviews")!
	}
	
	private enum DownloadedFileLocation {
		static let openFoodFacts = downloadFolder.appendingPathComponent("openfoodfacts-products.jsonl.gz")
		static let nutritionPrivacy = downloadFolder.appendingPathComponent("nutritionprivacy-products.jsonl")
		static let downloadFolder = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
	}
	
	public static func main() async throws {
		
		try await downloadProducts(from: Endpoints.nutritionPrivacy, to: DownloadedFileLocation.nutritionPrivacy)
		try await downloadProducts(from: Endpoints.openFoodFacts, to: DownloadedFileLocation.openFoodFacts)
	}
	
	private static func downloadProducts(from downloadURL: URL, to localURL: URL) async throws {
		guard !FileManager.default.fileExists(atPath: localURL.path) else {
			print("Found cached file: \(localURL.path)")
			return
		}
		var configuration = URLSessionConfiguration.default
		configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
		let session = URLSession(configuration: configuration)
		do {
			let (url, response) = try await session.download(from: downloadURL)
			guard (response as? HTTPURLResponse)?.statusCode == 200 else {
				print("Download from \(downloadURL) failed with response: \(response)")
				throw URLError(.badServerResponse)
			}
			try FileManager.default.moveItem(at: url, to: localURL)
		} catch {
			print("Download from \(downloadURL) failed with error: \(error)")
			throw error
		}
	}
}
