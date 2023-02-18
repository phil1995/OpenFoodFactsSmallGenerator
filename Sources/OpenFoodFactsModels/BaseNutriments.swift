import Foundation
import Core

struct BaseNutriments {
	let energyKcal: Int
	let proteins: Double
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
		proteins = try JSONDecoderHelper.parseJSONKeyToDouble(container: dynamicKeyContainer, forKey: proteinsKey)
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
