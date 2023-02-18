public struct Serving: Codable, Hashable {

    public enum Name: String, Codable, CaseIterable {
        case portion = "portion"
        case slice = "slice"
        case cup = "cup"
    }
    public var name: Name
    public var underlyingQuantity: Quantity

    public init(name: Name, underlyingQuantity: Quantity) {
        self.name = name
        self.underlyingQuantity = underlyingQuantity
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case underlyingQuantity
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(underlyingQuantity, forKey: .underlyingQuantity)
    }
}

