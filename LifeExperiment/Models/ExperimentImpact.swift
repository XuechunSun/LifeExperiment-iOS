import Foundation

// MARK: - Dynamic Coding Key for ExperimentImpact

struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }

    init(_ s: String) {
        self.stringValue = s
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }
}

// MARK: - Experiment Impact

struct ExperimentImpact: Codable, Hashable {
    var primary: Dimension
    var secondary: Dimension?
    var tertiary: Dimension?

    // Computed helper for backward compatibility with array-based code
    var additionalDimensions: [Dimension] {
        [secondary, tertiary].compactMap { $0 }
    }

    init(primary: Dimension, secondary: Dimension? = nil, tertiary: Dimension? = nil) {
        self.primary = primary
        self.secondary = secondary
        self.tertiary = tertiary

        // Debug assertions
        #if DEBUG
        assert(secondary != primary, "Secondary dimension must differ from primary")
        assert(tertiary != primary, "Tertiary dimension must differ from primary")
        if let sec = secondary, let ter = tertiary {
            assert(sec != ter, "Secondary and tertiary dimensions must differ")
        }
        #endif
    }

    // Custom decoder for backward compatibility with old array format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        // Decode primary (required)
        primary = try container.decode(Dimension.self, forKey: AnyCodingKey("primary"))

        // Try to decode secondary as Dimension? (new format)
        if let sec = try? container.decodeIfPresent(Dimension.self, forKey: AnyCodingKey("secondary")) {
            secondary = sec
            tertiary = try? container.decodeIfPresent(Dimension.self, forKey: AnyCodingKey("tertiary"))
        } else {
            // Fall back to old array format
            if let array = try? container.decodeIfPresent([Dimension].self, forKey: AnyCodingKey("secondary")) {
                secondary = array.first
                tertiary = array.count > 1 ? array[1] : nil
            } else {
                secondary = nil
                tertiary = nil
            }
        }
    }

    // Custom encoder - always use new format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        try container.encode(primary, forKey: AnyCodingKey("primary"))
        try container.encodeIfPresent(secondary, forKey: AnyCodingKey("secondary"))
        try container.encodeIfPresent(tertiary, forKey: AnyCodingKey("tertiary"))
    }
}

