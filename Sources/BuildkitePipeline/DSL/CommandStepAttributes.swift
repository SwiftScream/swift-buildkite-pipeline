import Foundation

/// A single attribute used by command-step builders.
public enum CommandStepAttribute: Equatable, Sendable {
    /// Sets the command payload for the step.
    case command(CommandValue)
    /// Appends an artifact path glob to `artifact_paths`.
    case artifactPath(String)
    /// Adds a plugin declaration to the step.
    case plugin(Plugin)
    /// Adds an agent constraint to the step.
    case agent(AgentEntry)
    /// Adds an environment variable to the step.
    case environmentVariable(EnvironmentVariable)
    /// Configures matrix expansion for the step.
    case matrix(MatrixConfiguration)
    /// Adds a notification rule to the step.
    case notification(CommandStepNotificationRule)
}

/// A single command-step agent entry.
public struct AgentEntry: Equatable, Sendable {
    /// The agent attribute key.
    public let key: String
    /// The agent attribute value.
    public let value: JSONValue

    /// Creates an agent entry.
    public init(key: String, value: JSONValue) {
        self.key = key
        self.value = value
    }
}

/// A single command-step environment variable.
public struct EnvironmentVariable: Equatable, Sendable {
    /// The environment variable name.
    public let key: String
    /// The environment variable value.
    public let value: String

    /// Creates an environment variable entry.
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

/// A single matrix component used by `Matrix`.
public enum MatrixComponent: Equatable, Sendable {
    /// Adds a dimension and its allowed values.
    case dimension(name: String, values: [String])
    /// Adds a matrix adjustment rule.
    case adjustment(MatrixAdjustment)
}

/// Creates a command attribute from a single shell command.
public func Command(_ command: String) -> CommandStepAttribute {
    .command(.single(command))
}

/// Creates a command attribute from multiple shell commands.
public func Command(_ commands: [String]) -> CommandStepAttribute {
    .command(.multiple(commands))
}

/// Creates a command attribute from variadic shell commands.
public func Command(_ commands: String...) -> CommandStepAttribute {
    Command(commands)
}

/// Creates an artifact-path attribute for a command step.
public func ArtifactPath(_ path: String) -> CommandStepAttribute {
    .artifactPath(path)
}

/// Creates an environment variable entry for a command step.
public func Env(_ key: String, _ value: String) -> EnvironmentVariable {
    EnvironmentVariable(key: key, value: value)
}

/// Expands an ordered collection of environment variables into step entries.
///
/// Useful for reusing environment chunks across multiple steps while preserving
/// declaration order.
public func Env(_ entries: KeyValuePairs<String, String>) -> [EnvironmentVariable] {
    entries.map { EnvironmentVariable(key: $0.0, value: $0.1) }
}

/// Expands an ordered collection of optional environment variables into step entries.
///
/// Entries with `nil` values are omitted.
public func Env(_ entries: KeyValuePairs<String, String?>) -> [EnvironmentVariable] {
    entries.compactMap { key, value in
        guard let value else {
            return nil
        }
        return EnvironmentVariable(key: key, value: value)
    }
}

/// Creates a queue agent entry for a command step.
public func Agent(queue value: String) -> AgentEntry {
    AgentEntry(key: "queue", value: .string(value))
}

/// Creates a key-value agent entry for a command step.
public func Agent(_ key: String, _ value: JSONValue) -> AgentEntry {
    AgentEntry(key: key, value: value)
}

/// Creates a dependency that allows failure from the referenced step.
public func allowingFailure(_ key: StepKey) -> StepDependency {
    StepDependency(key, allowFailure: true)
}

/// Creates an automatic retry rule.
public func RetryRule(
    exitStatus: Int? = nil,
    signalReason: String? = nil,
    signal: String? = nil,
    limit: Int? = nil,
) -> RetryAutomaticRule {
    RetryAutomaticRule(
        exitStatus: exitStatus,
        signalReason: signalReason,
        signal: signal,
        limit: limit,
    )
}

/// Creates a matrix attribute from `MatrixBuilder` content.
public func Matrix(@MatrixBuilder _ content: () -> [MatrixComponent]) -> CommandStepAttribute {
    var setup: [String: [String]] = [:]
    var adjustments: [MatrixAdjustment] = []

    for component in content() {
        switch component {
        case .dimension(let name, let values):
            setup[name] = values
        case .adjustment(let adjustment):
            adjustments.append(adjustment)
        }
    }

    let matrix = MatrixConfiguration(setup: setup, adjustments: adjustments.isEmpty ? nil : adjustments)
    return .matrix(matrix)
}

/// Creates a matrix dimension component.
public func Dimension(_ name: String, values: [String]) -> MatrixComponent {
    .dimension(name: name, values: values)
}

/// Creates a matrix adjustment component.
public func Adjustment(with values: [String: String], softFail: Bool? = nil, skip: Bool? = nil) -> MatrixComponent {
    .adjustment(MatrixAdjustment(with: values, softFail: softFail, skip: skip))
}
