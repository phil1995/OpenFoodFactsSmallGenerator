import Foundation

public struct DynamicKey: CodingKey {
	public var stringValue: String
	public init?(stringValue: String) {
		self.stringValue = stringValue
	}

	public var intValue: Int?
	public init?(intValue _: Int) {
		return nil
	}
	
	public static func generate(from stringValue: String) throws -> DynamicKey {
		guard let dynamicKey = DynamicKey(stringValue: stringValue) else {
			throw ProductDecodingError.dynamicKeyFailed
		}
		return dynamicKey
	}
}
