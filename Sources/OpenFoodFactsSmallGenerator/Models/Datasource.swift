import Foundation

/// Use int instead of string to reduce the file size
enum Datasource: Int, Codable {
	case openFoodFacts
	case nutritionPrivacy
}
