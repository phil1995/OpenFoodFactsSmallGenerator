import Foundation
import Core

struct OpenFoodFactsProductsResponse: Decodable {
	let totalProducts: Int
	let page: Int
	let pageSize: Int
	let products: [Product]
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.totalProducts = try JSONDecoderHelper.parseJSONKeyToInt(container: container, forKey: .totalProducts)
		self.page = try JSONDecoderHelper.parseJSONKeyToInt(container: container, forKey: .page)
		self.pageSize = try JSONDecoderHelper.parseJSONKeyToInt(container: container, forKey: .pageSize)
		self.products = try container
			.decode([FailableDecodable<Product>].self, forKey: .products)
			.compactMap { $0.base }
	}

	enum CodingKeys: String, CodingKey {
		case totalProducts = "count"
		case page
		case pageSize = "page_size"
		case products
	}
}
