import Foundation
import Core

public struct ProductPreview: Codable, Hashable {

	public var id: UUID
	public var names: [LocalizedValue]
	public var brands: [LocalizedValue]?
	public var servings: [Serving]?
	public var totalQuantity: Quantity?
	/** Calories per 100g / 100ml measured in kcal */
	public var calories: Int
	public var verified: Bool?

	public init(id: UUID, names: [LocalizedValue], brands: [LocalizedValue]? = nil, servings: [Serving]? = nil, totalQuantity: Quantity? = nil, calories: Int, verified: Bool? = nil) {
		self.id = id
		self.names = names
		self.brands = brands
		self.servings = servings
		self.totalQuantity = totalQuantity
		self.calories = calories
		self.verified = verified
	}

	public enum CodingKeys: String, CodingKey, CaseIterable {
		case id
		case names
		case brands
		case servings
		case totalQuantity
		case calories
		case verified
	}

	// Encodable protocol methods

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id, forKey: .id)
		try container.encode(names, forKey: .names)
		try container.encodeIfPresent(brands, forKey: .brands)
		try container.encodeIfPresent(servings, forKey: .servings)
		try container.encodeIfPresent(totalQuantity, forKey: .totalQuantity)
		try container.encode(calories, forKey: .calories)
		try container.encodeIfPresent(verified, forKey: .verified)
	}
}

extension ProductPreview: SmallProductConvertable {
	public func getNames() -> [Language : String] {
		var convertedNames: [Language : String] = [:]
		for name in names {
			guard let languageCode = name.languageCode, let value = name.value, let language = Language(bcp47: languageCode) else { continue }
			convertedNames[language] = value
		}
		return convertedNames
	}
	
	public func getBrand() -> String? {
		brands?.first?.value
	}
	
	public func getId() -> String {
		id.uuidString
	}
	
	public func getEnergy() -> Int {
		calories
	}
	
	public func getQuantity() -> String? {
		guard let totalQuantity else { return nil }
		return "\(totalQuantity.value) \(totalQuantity.unit.rawValue)"
	}
	
	public func getServing() -> String? {
		// TODO: Add implementation for serving support
		return nil
	}
}

extension Language {
	init?(bcp47: String) {
		switch bcp47 {
		case "de_CH":
			self = .german
		case "de_DE":
			self = .german
		case "en_EN":
			self = .english
		case "en_US":
			self = .english
		default:
			return nil
		}
	}
}
