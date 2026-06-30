import Foundation

public struct DayData: Codable, Equatable {
    public var text: String
    public var extraCategories: [String: [String: String?]]?
    
    public init(text: String, extraCategories: [String: [String: String?]]? = nil) {
        self.text = text
        self.extraCategories = extraCategories
    }
    
    struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        var intValue: Int?
        init?(intValue: Int) { return nil }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        self.text = try container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "text")!)
        
        var extra: [String: [String: String?]] = [:]
        for key in container.allKeys {
            if key.stringValue != "text" {
                if let dict = try? container.decode([String: String?].self, forKey: key) {
                    extra[key.stringValue] = dict
                } else if let isNull = try? container.decodeNil(forKey: key), isNull {
                    extra[key.stringValue] = [:]
                }
            }
        }
        self.extraCategories = extra.isEmpty ? nil : extra
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        try container.encode(text, forKey: DynamicCodingKeys(stringValue: "text")!)
        
        if let extra = extraCategories {
            for (category, subEntries) in extra {
                try container.encode(subEntries, forKey: DynamicCodingKeys(stringValue: category)!)
            }
        }
    }
}
