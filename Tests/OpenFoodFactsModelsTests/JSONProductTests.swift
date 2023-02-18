import XCTest
@testable import OpenFoodFactsModels

final class JSONProductTests: XCTestCase {

    func test_decode_onlyEnglishName() throws {
		// GIVEN
		// The test resource has been loaded
		let data = try ResourceLoader.getTestData(forResource: "Products-1", withExtension: "jsonl")
		
		// WHEN
		// The data gets decoded to a JSONProduct
		let product = try JSONDecoder().decode(Product.self, from: data)
		
		// THEN
		// All expected values have been set
		XCTAssertEqual(product.names[.english], "Suppengemüse, 10 Sorten")
		XCTAssertEqual(product.names.count, 1) // Only english name <- although the name is not really english for this product…
		XCTAssertEqual(product.barcode, "0000000000")
		XCTAssertEqual(product.brand, "Panera Bread") // The first brand
		XCTAssertEqual(product.quantity?.rawValue, "1200g")
		XCTAssertNil(product.servingSize)
		let nutriments = product.nutriments
		XCTAssertEqual(nutriments.energyKcal, 114)
		XCTAssertEqual(nutriments.carbohydrates, 12.9)
		XCTAssertEqual(nutriments.fats, 3.3)
		XCTAssertEqual(nutriments.proteins, 7.3)
    }
}
