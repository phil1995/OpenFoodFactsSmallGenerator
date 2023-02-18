import Foundation
class ResourceLoader {
	static func getTestData(forResource name: String, withExtension ext: String) throws -> Data {
		guard let fileURL = Bundle.module.url(forResource: name, withExtension: ext) else {
			throw MissingResourceError()
		}
		return try Data(contentsOf: fileURL)
	}
}

struct MissingResourceError: Error {}
