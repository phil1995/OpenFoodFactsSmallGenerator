public struct Quantity: Codable, Hashable {

    public enum Unit: String, Codable, CaseIterable {
        case ml = "ml"
        case l = "l"
        case microgram = "microgram"
        case mg = "mg"
        case g = "g"
        case kg = "kg"
    }
    public var unit: Unit
    public var value: Int64

    public init(unit: Unit, value: Int64) {
        self.unit = unit
        self.value = value
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case unit
        case value
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(unit, forKey: .unit)
        try container.encode(value, forKey: .value)
    }
}

