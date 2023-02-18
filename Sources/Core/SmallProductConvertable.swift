import Foundation

public protocol SmallProductConvertable {
	func getNames() -> [Language: String]
	func getBrand() -> String?
	func getId() -> String
	func getEnergy() -> Int
	func getQuantity() -> String?
	func getServing() -> String?
}
