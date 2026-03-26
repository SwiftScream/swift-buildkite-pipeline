import Foundation

/// A top-level environment variable declaration for a pipeline.
public struct GlobalEnvironmentVariable: Equatable, Sendable {
    /// The environment variable name.
    public let key: String
    /// The environment variable value.
    public let value: String

    /// Creates a top-level environment variable entry.
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

/// A top-level default agent declaration for a pipeline.
public struct DefaultAgentEntry: Equatable, Sendable {
    /// The agent attribute key.
    public let key: String
    /// The agent attribute value.
    public let value: JSONValue

    /// Creates a top-level default agent entry.
    public init(key: String, value: JSONValue) {
        self.key = key
        self.value = value
    }
}

/// A top-level metadata declaration for a pipeline.
public struct MetadataEntry: Equatable, Sendable {
    /// The metadata key.
    public let key: String
    /// The metadata value.
    public let value: String

    /// Creates a metadata entry.
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

/// Adds a top-level environment variable in `Pipeline { ... }`.
public func GlobalEnv(_ key: String, _ value: String) -> GlobalEnvironmentVariable {
    GlobalEnvironmentVariable(key: key, value: value)
}

/// Expands an ordered collection of top-level environment variables.
public func GlobalEnv(_ entries: KeyValuePairs<String, String>) -> [GlobalEnvironmentVariable] {
    entries.map { GlobalEnvironmentVariable(key: $0.0, value: $0.1) }
}

/// Expands an ordered collection of optional top-level environment variables.
///
/// Entries with `nil` values are omitted.
public func GlobalEnv(_ entries: KeyValuePairs<String, String?>) -> [GlobalEnvironmentVariable] {
    entries.compactMap { key, value in
        guard let value else {
            return nil
        }
        return GlobalEnvironmentVariable(key: key, value: value)
    }
}

/// Adds a top-level default queue target in `Pipeline { ... }`.
public func DefaultAgent(queue value: String) -> DefaultAgentEntry {
    DefaultAgentEntry(key: "queue", value: .string(value))
}

/// Adds a top-level default agent constraint in `Pipeline { ... }`.
public func DefaultAgent(_ key: String, _ value: JSONValue) -> DefaultAgentEntry {
    DefaultAgentEntry(key: key, value: value)
}

/// Expands an ordered collection of top-level default agents.
public func DefaultAgent(_ entries: KeyValuePairs<String, JSONValue>) -> [DefaultAgentEntry] {
    entries.map { DefaultAgentEntry(key: $0.0, value: $0.1) }
}

/// Expands an ordered collection of optional top-level default agents.
///
/// Entries with `nil` values are omitted.
public func DefaultAgent(_ entries: KeyValuePairs<String, JSONValue?>) -> [DefaultAgentEntry] {
    entries.compactMap { key, value in
        guard let value else {
            return nil
        }
        return DefaultAgentEntry(key: key, value: value)
    }
}

/// Adds a top-level metadata value in `Pipeline { ... }`.
public func Metadata(_ key: String, _ value: String) -> MetadataEntry {
    MetadataEntry(key: key, value: value)
}

/// Expands an ordered collection of metadata into top-level entries.
public func Metadata(_ entries: KeyValuePairs<String, String>) -> [MetadataEntry] {
    entries.map { MetadataEntry(key: $0.0, value: $0.1) }
}

/// Expands an ordered collection of optional metadata into top-level entries.
///
/// Entries with `nil` values are omitted.
public func Metadata(_ entries: KeyValuePairs<String, String?>) -> [MetadataEntry] {
    entries.compactMap { key, value in
        guard let value else {
            return nil
        }
        return MetadataEntry(key: key, value: value)
    }
}
