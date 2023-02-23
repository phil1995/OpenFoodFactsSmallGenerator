import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
		do {
			let (url, response) = try await URLSession.shared.downloadFile(from: downloadURL)
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

// use custom async implementation since FoundationNetworking has it not yet implemented
extension URLSession {
	func downloadFile(from url: URL) async throws -> (URL, URLResponse) {
		try await withCheckedThrowingContinuation { continuation in
			let task = downloadTask(with: .init(url: url)) { url, response, error in
				if let error {
					continuation.resume(throwing: error)
					return
				}
				guard let url, let response else {
					continuation.resume(throwing: URLError(.unknown))
					return
				}
				do {
					let tempFilePath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
					try FileManager.default.moveItem(at: url, to: tempFilePath)
					continuation.resume(returning: (tempFilePath, response))
				} catch {
					continuation.resume(throwing: error)
				}
			}
			task.resume()
		}
	}
}
