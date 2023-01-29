import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct Product: Decodable {
	let name: String
	let barcode: String
	let energyKcal: Double
	var quantity: Quantity?
	var servingSize: Quantity?
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		guard let dynamicKey = DynamicKey(stringValue: "product_name") else {
//			print("Missing dynamic key for name error")
			throw DynamicKeyError()
		}
		let dynamicKeyContainer = try decoder.container(keyedBy: DynamicKey.self)
		guard let name = try dynamicKeyContainer.decodeIfPresent(String.self, forKey: dynamicKey), !name.isEmpty else {
//			print("Missing name")
			throw MissingNameError()
		}
		self.name = name
		self.barcode = try container.decode(String.self, forKey: .barcode)
		let energyKey = try DynamicKey.generate(from: "\(BaseNutriments.Key.energy)_100g")
		let fatKey = try DynamicKey.generate(from: "\(BaseNutriments.Key.fat)_100g")
		let proteinsKey = try DynamicKey.generate(from: "\(BaseNutriments.Key.proteins)_100g")
		let carbohydratesKey = try DynamicKey.generate(from: "\(BaseNutriments.Key.carbohydrates)_100g")
		
		self.energyKcal = try JSONDecoderHelper.parseJSONKeyToDouble(container: dynamicKeyContainer, forKey: energyKey)
		let proteins = try JSONDecoderHelper.parseJSONKeyToDouble(container: dynamicKeyContainer, forKey: proteinsKey)
		let fats = try JSONDecoderHelper.parseJSONKeyToDouble(container: dynamicKeyContainer, forKey: fatKey)
		let carbohydrates = try JSONDecoderHelper.parseJSONKeyToDouble(container: dynamicKeyContainer, forKey: carbohydratesKey)
		if let quantityStr = try container.decodeIfPresent(String.self, forKey: .quantity) {
			self.quantity = Quantity(rawValue: quantityStr)
		}
		if let servingSizeStr = try container.decodeIfPresent(String.self, forKey: .servingSize) {
			self.servingSize = Quantity(rawValue: servingSizeStr)
		}
		
		guard quantity != nil || servingSize != nil else {
//			print("Missing unit")
			throw MissingUnitError()
		}
	}
	
	
	enum CodingKeys: String, CodingKey {
		case names = "product_name"
		case languageCodes = "languages_codes"
		case barcode = "code"
		case nutriments
		case servingSize = "serving_size"
		case quantity
	}
}

struct SmallProduct: Codable {
	let name: String
	let barcode: String
	let energy: Int
	let quantity: String?
	let serving: String?
}
extension SmallProduct {
	init(from product: Product) {
		self.init(name: product.name,
				  barcode: product.barcode,
				  energy: Int(product.energyKcal),
				  quantity: product.quantity?.rawValue,
				  serving: product.servingSize?.rawValue)
	}
}

struct DynamicKeyError: Error {}
struct MissingNameError: Error {}
struct MissingUnitError: Error {}

struct BaseNutriments {
	let energyKcal: Int
	let proteins: Int
	let fats: Double
	let carbohydrates: Double
}

extension BaseNutriments: Decodable {
	init(from decoder: Decoder) throws {
		let dynamicKeyContainer = try decoder.container(keyedBy: DynamicKey.self)
		let energyKey = try DynamicKey.generate(from: "\(Key.energy)_100g")
		let fatKey = try DynamicKey.generate(from: "\(Key.fat)_100g")
		let proteinsKey = try DynamicKey.generate(from: "\(Key.proteins)_100g")
		let carbohydratesKey = try DynamicKey.generate(from: "\(Key.carbohydrates)_100g")
		
		energyKcal = try JSONDecoderHelper.parseJSONKeyToInt(container: dynamicKeyContainer, forKey: energyKey)
		proteins = try JSONDecoderHelper.parseJSONKeyToInt(container: dynamicKeyContainer, forKey: proteinsKey)
		fats = try JSONDecoderHelper.parseJSONKeyToDouble(container: dynamicKeyContainer, forKey: fatKey)
		carbohydrates = try JSONDecoderHelper.parseJSONKeyToDouble(container: dynamicKeyContainer, forKey: carbohydratesKey)
	}
}

extension BaseNutriments {
	enum Key: String {
		case energy = "energy-kcal"
		case fat
		case proteins
		case carbohydrates
	}
}



public struct DynamicKey: CodingKey {
	public var stringValue: String
	public init?(stringValue: String) {
		self.stringValue = stringValue
	}

	public var intValue: Int?
	public init?(intValue _: Int) {
		return nil
	}
	
	public static func generate(from stringValue: String) throws -> DynamicKey {
		guard let dynamicKey = DynamicKey(stringValue: stringValue) else {
			throw DynamicKeyError()
		}
		return dynamicKey
	}
}




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

struct Quantity: RawRepresentable {
	typealias RawValue = String

	let unit: WeightUnit
	let amount: Double

	init(amount: Double, unit: WeightUnit) {
		self.amount = amount
		self.unit = unit
	}

	init?(rawValue: String) {
		guard let firstNonNumericIndex = rawValue.firstIndex(where: { !$0.isNumber }) else {
			return nil
		}
		let numberString = String(rawValue[..<firstNonNumericIndex])
		guard let amount = Double(numberString) else {
			return nil
		}
		self.amount = amount
		switch rawValue {
		case _ where rawValue.lowercased().contains("ml"):
			self.unit = .milliliter
		case _ where rawValue.lowercased().contains("g"):
			self.unit = .gramm
		case _ where rawValue.lowercased().contains("l"):
			self.unit = .liter
		case _ where rawValue.lowercased().contains("kg"):
			self.unit = .kilogramm
		default:
			return nil
		}
	}

	var rawValue: String {
		return "\(Int(amount).description)\(unit.rawValue)"
	}
}

public enum WeightUnit: String, Codable {
	case milliliter = "ml"
	case liter = "l"
	case gramm = "g"
	case kilogramm = "kg"
}

enum DestinationError: Error {
	case existingFileAtTargetPath
	case missingParentDirectory
}

extension Task where Failure == Error {
	@discardableResult
	static func retrying(
		priority: TaskPriority? = nil,
		maxRetryCount: Int = 3,
		operation: @Sendable @escaping () async throws -> Success
	) -> Task {
		Task(priority: priority) {
			let exponentialBackoffBase: UInt = 2
			let exponentialBackoffScale = 0.5
			for attempt in 0..<maxRetryCount {
				do {
					return try await operation()
				} catch {
					let jitter = Double.random(in: 0 ..< 0.5)
					let oneSecond = TimeInterval(1_000_000_000)
					let retryCount = attempt + 1
					let retryDelay = pow(Double(exponentialBackoffBase), Double(retryCount)) * exponentialBackoffScale + jitter
					let delay = UInt64(oneSecond * retryDelay)
					try await Task<Never, Never>.sleep(nanoseconds: delay)
					
					continue
				}
			}
			
			try Task<Never, Never>.checkCancellation()
			return try await operation()
		}
	}
}
