import Core
import Foundation

public struct Product: Decodable {
	let names: [Language : String]
	let brand: String?
	let barcode: String
	let nutriments: BaseNutriments
	var quantity: Quantity?
	var servingSize: Quantity?
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let dynamicKeyContainer = try decoder.container(keyedBy: DynamicKey.self)
		var names: [Language : String] = [:]
		for language in Language.allCases {
			guard let dynamicKey = DynamicKey(stringValue: "product_name\(language.nameKeySuffix)") else {
				throw ProductDecodingError.dynamicKeyFailed
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
			throw ProductDecodingError.missingUnit
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
}

extension Language {
	var nameKeySuffix: String {
		switch self {
		case .german:
			return "_de"
		case .english:
			return ""
		}
	}
}

extension Product: SmallProductConvertable {
	public func getNames() -> [Core.Language : String] {
		names
	}
	
	public func getBrand() -> String? {
		brand
	}
	
	public func getId() -> String {
		barcode
	}
	
	public func getEnergy() -> Int {
		nutriments.energyKcal
	}
	
	public func getQuantity() -> String? {
		quantity?.rawValue
	}
	
	public func getServing() -> String? {
		servingSize?.rawValue
	}
}
