import Foundation

struct ProductExtractor {

	func start(source: URL, target: URL, languages: [JSONProduct.Language] = JSONProduct.Language.allCases, showProgress: Bool = true) async throws {
		let streamReader = try StreamReader(url: source)
		try "[".write(to: target, atomically: false, encoding: .utf8)
		let fileHandle = try FileHandle(forWritingTo: target)
		let decoder = JSONDecoder()
		let encoder = JSONEncoder()
		var line: String?
		var count = 0
		repeat {
			try customAutoreleasepool {
				line = streamReader.nextLine()
				guard let data = line?.data(using: .utf8) else {
					return
				}
				let product: JSONProduct
				do {
					product = try decoder.decode(JSONProduct.self, from: data)
				} catch {
					return
				}
				count += 1
				let productLanguages = product.names.keys
				for (language, name) in product.names where languages.contains(language) {
					let smallProduct = SmallProduct(name: name,
													brand: product.brand,
													barcode: product.barcode,
													energy: Int(product.nutriments.energyKcal),
													quantity: product.quantity?.rawValue,
													serving: product.servingSize?.rawValue)
					fileHandle.write(try encoder.encode(smallProduct))
					fileHandle.write("\n".data(using: .utf8)!)
				}
				if showProgress && count % 10000 == 0 {
					print("Processed products: \(count)")
				}
			}
			
		} while line != nil
		fileHandle.write("]".data(using: .utf8)!)
		try fileHandle.close()
	}
}

public func customAutoreleasepool<Result>(invoking body: () throws -> Result) rethrows -> Result {
	#if !os(Linux)
	return try autoreleasepool(invoking: body)
	#else
	return try body()
	#endif
}

struct BaseNutriments {
	let energyKcal: Int
	let proteins: Int
	let fats: Double
	let carbohydrates: Double
}

extension BaseNutriments: Decodable {
	init(from decoder: Decoder) throws {
		let dynamicKeyContainer = try decoder.container(keyedBy: DynamicKey.self)
		let energyKey = try DynamicKey.generate(from: "\(Key.energy.rawValue)_100g")
		let fatKey = try DynamicKey.generate(from: "\(Key.fat.rawValue)_100g")
		let proteinsKey = try DynamicKey.generate(from: "\(Key.proteins.rawValue)_100g")
		let carbohydratesKey = try DynamicKey.generate(from: "\(Key.carbohydrates.rawValue)_100g")
		
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


class StreamReader {
	let encoding: String.Encoding
	let chunkSize: Int
	let fileHandle: FileHandle
	var buffer: Data
	let delimiterPattern : Data
	var isAtEOF: Bool = false
	
	init(url: URL, delimiter: String = "\n", encoding: String.Encoding = .utf8, chunkSize: Int = 4096) throws
	{
		print("StreamReader init path:\(url.path)")
		let fileHandle = try FileHandle(forReadingFrom: url)
		self.fileHandle = fileHandle
		self.chunkSize = chunkSize
		self.encoding = encoding
		buffer = Data(capacity: chunkSize)
		delimiterPattern = delimiter.data(using: .utf8)!
	}
	
	deinit {
		fileHandle.closeFile()
	}
	
	func rewind() {
		fileHandle.seek(toFileOffset: 0)
		buffer.removeAll(keepingCapacity: true)
		isAtEOF = false
	}
	
	func nextLine() -> String? {
		if isAtEOF { return nil }
		
		repeat {
			if let range = buffer.range(of: delimiterPattern, options: [], in: buffer.startIndex..<buffer.endIndex) {
				let subData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
				let line = String(data: subData, encoding: encoding)
				buffer.replaceSubrange(buffer.startIndex..<range.upperBound, with: [])
				return line
			} else {
				let tempData = fileHandle.readData(ofLength: chunkSize)
				if tempData.count == 0 {
					isAtEOF = true
					return (buffer.count > 0) ? String(data: buffer, encoding: encoding) : nil
				}
				buffer.append(tempData)
			}
		} while true
	}
}

struct JSONProduct: Decodable {
	let names: [Language : String]
	let brand: String?
	let barcode: String
	let nutriments: BaseNutriments
	var quantity: Quantity?
	var servingSize: Quantity?
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let dynamicKeyContainer = try decoder.container(keyedBy: DynamicKey.self)
		var names: [Language : String] = [:]
		for language in Language.allCases {
			guard let dynamicKey = DynamicKey(stringValue: "product_name\(language.nameKeySuffix)") else {
				throw DynamicKeyError()
			}
			guard let name = try dynamicKeyContainer.decodeIfPresent(String.self, forKey: dynamicKey), !name.isEmpty else {
				continue
			}
			names[language] = name
		}
		
		self.names = names
		
		if let brandsStr = try container.decodeIfPresent(String.self, forKey: .brands) {
			self.brand = brandsStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }.first
		} else {
			self.brand = nil
		}
		
		self.barcode = try container.decode(String.self, forKey: .barcode)
		
		self.nutriments = try container.decode(BaseNutriments.self, forKey: .nutriments)
		
		if let quantityStr = try container.decodeIfPresent(String.self, forKey: .quantity) {
			self.quantity = Quantity(rawValue: quantityStr)
		}
		if let servingSizeStr = try container.decodeIfPresent(String.self, forKey: .servingSize) {
			self.servingSize = Quantity(rawValue: servingSizeStr)
		}
		
		guard quantity != nil || servingSize != nil else {
			throw MissingUnitError()
		}
	}
	
	private static func verifyExistenceOfBaseNutriments(in dynamicKeyContainer: KeyedDecodingContainer<DynamicKey>) throws {
		let fatKey = try DynamicKey.generate(from: "\(BaseNutrimentsKey.fat)_100g")
		let proteinsKey = try DynamicKey.generate(from: "\(BaseNutrimentsKey.proteins)_100g")
		let carbohydratesKey = try DynamicKey.generate(from: "\(BaseNutrimentsKey.carbohydrates)_100g")
		
		_ = try JSONDecoderHelper.parseJSONKeyToDouble(container: dynamicKeyContainer, forKey: proteinsKey)
		_ = try JSONDecoderHelper.parseJSONKeyToDouble(container: dynamicKeyContainer, forKey: fatKey)
		_ = try JSONDecoderHelper.parseJSONKeyToDouble(container: dynamicKeyContainer, forKey: carbohydratesKey)
	}
	
	
	enum CodingKeys: String, CodingKey {
		case names = "product_name"
		case brands
		case languageCodes = "languages_codes"
		case barcode = "code"
		case nutriments
		case servingSize = "serving_size"
		case quantity
	}
	
	enum BaseNutrimentsKey: String {
		case energy = "energy-kcal"
		case fat
		case proteins
		case carbohydrates
	}
	
	enum Language: CaseIterable {
		case english
		case german
		
		var nameKeySuffix: String {
			switch self {
			case .german:
				return "_de"
			case .english:
				return ""
			}
		}
	}
}
