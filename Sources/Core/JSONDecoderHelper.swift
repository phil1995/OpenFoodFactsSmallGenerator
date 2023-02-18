import Foundation

public enum JSONDecoderHelper {
	public static func parseJSONKeyToDouble<K>(container: KeyedDecodingContainer<K>, forKey key: KeyedDecodingContainer<K>.Key) throws -> Double {
		do {
			return try container.decode(Double.self, forKey: key)
		} catch DecodingError.typeMismatch {}
		if let str = try? container.decode(String.self, forKey: key), let double = Double(str) {
			return double
		} else {
			let context = DecodingError.Context(codingPath: container.codingPath + [key], debugDescription: "Could not parse json key to a Double object")
			throw DecodingError.dataCorrupted(context)
		}
	}
	
	public static func parseJSONKeyToInt<K>(container: KeyedDecodingContainer<K>, forKey key: KeyedDecodingContainer<K>.Key) throws -> Int {
		do {
			return try container.decode(Int.self, forKey: key)
		} catch DecodingError.typeMismatch {}
		if let str = try? container.decode(String.self, forKey: key), let double = Int(str) {
			return double
		} else {
			let context = DecodingError.Context(codingPath: container.codingPath + [key], debugDescription: "Could not parse json key to a int object")
			throw DecodingError.dataCorrupted(context)
		}
	}
}
