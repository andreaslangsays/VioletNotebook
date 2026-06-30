import Foundation

public struct DynamicCodingKeys: CodingKey {
    public var stringValue: String
    public init?(stringValue: String) {
        self.stringValue = stringValue
    }
    public var intValue: Int?
    public init?(intValue: Int) { return nil }
}

public enum YAMLValue: Codable, Equatable {
    case string(String)
    case integer(Int)
    case number(Double)
    case bool(Bool)
    case array([YAMLValue])
    case object([String: YAMLValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .integer(i)
        } else if let d = try? container.decode(Double.self) {
            self = .number(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let arr = try? container.decode([YAMLValue].self) {
            self = .array(arr)
        } else if let obj = try? container.decode([String: YAMLValue].self) {
            self = .object(obj)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode YAMLValue")
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .string(let s):
            var container = encoder.singleValueContainer()
            try container.encode(s)
        case .integer(let i):
            var container = encoder.singleValueContainer()
            try container.encode(i)
        case .number(let d):
            var container = encoder.singleValueContainer()
            try container.encode(d)
        case .bool(let b):
            var container = encoder.singleValueContainer()
            try container.encode(b)
        case .array(let arr):
            var container = encoder.singleValueContainer()
            try container.encode(arr)
        case .object(let obj):
            var objContainer = encoder.container(keyedBy: DynamicCodingKeys.self)
            for (key, val) in obj.sorted(by: { $0.key < $1.key }) {
                try objContainer.encode(val, forKey: DynamicCodingKeys(stringValue: key)!)
            }
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

public struct DayData: Codable, Equatable {
    public var text: String
    public var extraCategories: [String: YAMLValue]?
    
    public init(text: String, extraCategories: [String: YAMLValue]? = nil) {
        self.text = text
        self.extraCategories = extraCategories
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        self.text = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys(stringValue: "text")!) ?? ""
        
        var extra: [String: YAMLValue] = [:]
        for key in container.allKeys {
            if key.stringValue != "text" {
                if try container.decodeNil(forKey: key) {
                    extra[key.stringValue] = .null
                } else if let val = try? container.decode(YAMLValue.self, forKey: key) {
                    extra[key.stringValue] = val
                }
            }
        }
        self.extraCategories = extra.isEmpty ? nil : extra
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        try container.encode(text, forKey: DynamicCodingKeys(stringValue: "text")!)
        
        if let extra = extraCategories {
            let sortedKeys = extra.keys.sorted()
            for category in sortedKeys {
                if let value = extra[category] {
                    try container.encode(value, forKey: DynamicCodingKeys(stringValue: category)!)
                }
            }
        }
    }
}
