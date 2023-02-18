import Foundation

public struct SmallProduct: Codable {
	public let name: String
	public let brand: String?
	public let barcode: String
	public let energy: Int
	public let quantity: String?
	public let serving: String?
	public let source: Datasource
	
	public init(name: String, brand: String?, barcode: String, energy: Int, quantity: String?, serving: String?, source: Datasource) {
		self.name = name
		self.brand = brand
		self.barcode = barcode
		self.energy = energy
		self.quantity = quantity
		self.serving = serving
		self.source = source
	}
}
//extension SmallProduct {
//	init(from product: Product, source: Datasource) {
//		self.init(name: product.name,
//				  brand: product.brand,
//				  barcode: product.barcode,
//				  energy: Int(product.energyKcal),
//				  quantity: product.quantity?.rawValue,
//				  serving: product.servingSize?.rawValue,
//				  source: source)
//	}
//}
