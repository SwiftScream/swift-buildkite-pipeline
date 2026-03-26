import Foundation

/// A lightweight encodable representation for JSON-like values used by flexible Buildkite fields.
public enum JSONValue: Encodable, Equatable, Sendable {
    /// The `string` case.
    case string(String)
    /// The `int` case.
    case int(Int)
    /// The `double` case.
    case double(Double)
    /// The `bool` case.
    case bool(Bool)
    /// The `array` case.
    case array([JSONValue])
    /// The `object` case.
    case object([String: JSONValue])
    /// The `null` case.
    case null

    /// Encodes this value.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

public extension JSONValue {
    /// Creates a new instance.
    init(_ value: String) {
        self = .string(value)
    }
}

extension JSONValue: ExpressibleByStringLiteral {
    /// Creates a new instance.
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension JSONValue: ExpressibleByIntegerLiteral {
    /// Creates a new instance.
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension JSONValue: ExpressibleByFloatLiteral {
    /// Creates a new instance.
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension JSONValue: ExpressibleByBooleanLiteral {
    /// Creates a new instance.
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension JSONValue: ExpressibleByNilLiteral {
    /// Creates a new instance.
    public init(nilLiteral _: ()) {
        self = .null
    }
}

extension JSONValue: ExpressibleByArrayLiteral {
    /// Creates a new instance.
    public init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }
}

extension JSONValue: ExpressibleByDictionaryLiteral {
    /// Creates a new instance.
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        let dictionary = Dictionary(uniqueKeysWithValues: elements)
        self = .object(dictionary)
    }
}
