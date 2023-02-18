import Foundation

public struct LocalizedValue: Codable, Hashable {

	public var value: String?
	/** BCP 47 Code language code */
	public var languageCode: String?

	public init(value: String? = nil, languageCode: String? = nil) {
		self.value = value
		self.languageCode = languageCode
	}

	public enum CodingKeys: String, CodingKey, CaseIterable {
		case value
		case languageCode
	}

	// Encodable protocol methods

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encodeIfPresent(value, forKey: .value)
		try container.encodeIfPresent(languageCode, forKey: .languageCode)
	}
}
