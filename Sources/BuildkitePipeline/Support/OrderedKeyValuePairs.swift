import Foundation

/// An ordered key-value map that preserves insertion order when encoding.
///
/// Reassigning an existing key updates the value without changing key order.
struct OrderedKeyValuePairs<Value: Encodable & Equatable & Sendable>: Encodable, Equatable, Sendable {
    struct Entry: Encodable, Equatable, Sendable {
        var key: String
        var value: Value
    }

    private var entries: [Entry]

    init() {
        entries = []
    }

    /// Builds an ordered map from a dictionary in deterministic (sorted-key) order.
    init(_ dictionary: [String: Value]) {
        entries = dictionary.keys.sorted().map { Entry(key: $0, value: dictionary[$0]!) }
    }

    init(_ pairs: KeyValuePairs<String, Value>) {
        entries = []
        for (key, value) in pairs {
            self[key] = value
        }
    }

    init(entries: [Entry]) {
        self.entries = []
        for entry in entries {
            self[entry.key] = entry.value
        }
    }

    var isEmpty: Bool {
        entries.isEmpty
    }

    var allEntries: [Entry] {
        entries
    }

    var dictionary: [String: Value] {
        var output: [String: Value] = [:]
        output.reserveCapacity(entries.count)
        for entry in entries {
            output[entry.key] = entry.value
        }
        return output
    }

    subscript(key: String) -> Value? {
        get {
            entries.first(where: { $0.key == key })?.value
        }
        set {
            if let index = entries.firstIndex(where: { $0.key == key }) {
                if let newValue {
                    entries[index].value = newValue
                } else {
                    entries.remove(at: index)
                }
                return
            }

            if let newValue {
                entries.append(Entry(key: key, value: newValue))
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        for entry in entries {
            guard let key = DynamicCodingKey(stringValue: entry.key) else {
                throw EncodingError.invalidValue(
                    entry.key,
                    EncodingError.Context(
                        codingPath: encoder.codingPath,
                        debugDescription: "Invalid key for ordered key-value encoding",
                    ),
                )
            }
            try container.encode(entry.value, forKey: key)
        }
    }
}
