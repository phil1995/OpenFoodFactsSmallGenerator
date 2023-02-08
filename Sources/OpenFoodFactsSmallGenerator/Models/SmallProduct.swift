import Foundation

struct SmallProduct: Codable {
	let name: String
	let brand: String?
	let barcode: String
	let energy: Int
	let quantity: String?
	let serving: String?
	let source: Datasource
}
extension SmallProduct {
	init(from product: Product, source: Datasource) {
		self.init(name: product.name,
				  brand: product.brand,
				  barcode: product.barcode,
				  energy: Int(product.energyKcal),
				  quantity: product.quantity?.rawValue,
				  serving: product.servingSize?.rawValue,
				  source: source)
	}
}
