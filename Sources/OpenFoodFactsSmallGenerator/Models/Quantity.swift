import Foundation

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
