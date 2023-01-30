import Foundation

struct Product: Decodable {
	let name: String
	let brand: String?
	let barcode: String
	let energyKcal: Double
	var quantity: Quantity?
	var servingSize: Quantity?
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		guard let dynamicKey = DynamicKey(stringValue: "product_name") else {
			throw DynamicKeyError()
		}
		let dynamicKeyContainer = try decoder.container(keyedBy: DynamicKey.self)
		guard let name = try dynamicKeyContainer.decodeIfPresent(String.self, forKey: dynamicKey), !name.isEmpty else {
			throw MissingNameError()
		}
		self.name = name
		self.barcode = try container.decode(String.self, forKey: .barcode)
		
		if let brandsStr = try container.decodeIfPresent(String.self, forKey: .brands) {
			self.brand = brandsStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }.first
		} else {
			self.brand = nil
		}
		
		let energyKey = try DynamicKey.generate(from: "\(BaseNutrimentsKey.energy)_100g")
		
		self.energyKcal = try JSONDecoderHelper.parseJSONKeyToDouble(container: dynamicKeyContainer, forKey: energyKey)
		
		try Self.verifyExistenceOfBaseNutriments(in: dynamicKeyContainer)
		
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
}
