import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


struct ProductDownloader {
	let session: URLSession
	let language: Language
	let downloadDirectory: URL
	
	func start() async throws {
		var nextPage = 1
		var products: [SmallProduct] = []
		let destination = downloadDirectory.appendingPathComponent("\(language)_small.json")
		var crawledProducts = 0
		guard FileManager.default.fileExists(atPath: downloadDirectory.path) else {
			throw DestinationError.missingParentDirectory
		}
		guard !FileManager.default.fileExists(atPath: destination.path) else {
			throw DestinationError.existingFileAtTargetPath
		}
		var urlComponents = URLComponents(string: "https://\(language.rawValue).openfoodfacts.org/api/v2/search")!
		var parameters = [
			"fields": "code,product_name,energy_100g,proteins_100g,carbohydrates_100g,fat_100g,quantity,serving_size",
			"page_size": "1000"
		]
		let decoder = JSONDecoder()
		var maxPages = Int.max
		repeat {
			var queryItems = [URLQueryItem]()
			parameters["page"] = String(nextPage)
			for (key, value) in parameters {
					queryItems.append(URLQueryItem(name: key, value: value))
				}
			urlComponents.queryItems = queryItems
			let url = urlComponents.url!
			let data = try await Task.retrying {
				return try await session.data(from: url, expectedStatusCode: 200)
			}.value
			
			let offResponse = try decoder.decode(OpenFoodFactsProductsResponse.self, from: data)
			nextPage += 1
			maxPages = offResponse.totalProducts / offResponse.pageSize
			
			products.append(contentsOf: offResponse.products.map { .init(from: $0) })
			crawledProducts += offResponse.pageSize
			print("Progress: crawled \(crawledProducts) / \(offResponse.totalProducts) products -> saving: \(products.count) products")
		} while nextPage <= maxPages
		let data = try JSONEncoder().encode(products)
		try data.write(to: destination)
		print("Finished export to: \(destination.path)")
	}
	
	enum Language: String {
		case german = "de"
		case english = "en"
	}
}

extension URLSession {
	func data(from url: URL) async throws -> (Data, URLResponse) {
			try await withCheckedThrowingContinuation { continuation in
				let task = self.dataTask(with: url) { data, response, error in
					guard let data = data, let response = response else {
						let error = error ?? URLError(.badServerResponse)
						return continuation.resume(throwing: error)
					}
					
					continuation.resume(returning: (data, response))
				}
				
				task.resume()
			}
		}
	
	func data(from url: URL, expectedStatusCode: Int) async throws -> Data {
		let (data, response) = try await data(from: url)
		guard (response as? HTTPURLResponse)?.statusCode == expectedStatusCode else {
			throw URLError(.badServerResponse)
		}
		return data
	}
}

