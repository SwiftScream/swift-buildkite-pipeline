import Foundation

/// A type-erased pipeline step used for serialization and storage.
public struct PipelineStep: Equatable, Sendable, PipelineStepConvertible {
    let model: StepModel

    init(_ model: StepModel) {
        self.model = model
    }

    /// Returns this value unchanged as a pipeline step.
    public var pipelineStep: PipelineStep {
        self
    }
}

/// A value that can be converted into an erased `PipelineStep`.
public protocol PipelineStepConvertible: Sendable {
    /// Returns the erased pipeline step representation.
    var pipelineStep: PipelineStep { get }
}

/// A Buildkite pipeline built with a Swift DSL.
public struct Pipeline: Equatable, Sendable {
    private let orderedEnv: OrderedKeyValuePairs<String>?
    private let orderedAgents: OrderedKeyValuePairs<JSONValue>?
    private let orderedMetadata: OrderedKeyValuePairs<String>?
    /// The top-level environment variables.
    public var env: [String: String]? {
        orderedEnv?.dictionary
    }

    /// The top-level default agent constraints.
    public var agents: [String: JSONValue]? {
        orderedAgents?.dictionary
    }

    /// The top-level pipeline metadata entries.
    public var metadata: [String: String]? {
        orderedMetadata?.dictionary
    }

    /// The top-level notification rules.
    public let notify: [NotificationRule]?
    /// The default priority for steps without an explicit step priority.
    public let priority: Int?
    /// The ordered list of pipeline steps.
    public let steps: [PipelineStep]

    /// Creates a pipeline from a step builder.
    public init(
        @PipelineBuilder _ content: () -> PipelineContent,
    ) {
        let built = content()
        let envEntries = built.globalEnv.map { OrderedKeyValuePairs<String>.Entry(key: $0.key, value: $0.value) }
        orderedEnv = envEntries.isEmpty ? nil : .init(entries: envEntries)

        let agentEntries = built.defaultAgents.map { OrderedKeyValuePairs<JSONValue>.Entry(key: $0.key, value: $0.value) }
        orderedAgents = agentEntries.isEmpty ? nil : .init(entries: agentEntries)

        let metadataEntries = built.metadata.map { OrderedKeyValuePairs<String>.Entry(key: $0.key, value: $0.value) }
        orderedMetadata = metadataEntries.isEmpty ? nil : .init(entries: metadataEntries)

        notify = built.notify.isEmpty ? nil : built.notify
        priority = nil
        steps = built.steps
    }

    /// Creates a pipeline from direct values.
    public init(
        env: [String: String]? = nil,
        agents: [String: JSONValue]? = nil,
        notify: [NotificationRule]? = nil,
        metadata: [String: String]? = nil,
        priority: Int? = nil,
        steps: [PipelineStep],
    ) {
        orderedEnv = env.map(OrderedKeyValuePairs<String>.init)
        orderedAgents = agents.map(OrderedKeyValuePairs<JSONValue>.init)
        orderedMetadata = metadata.map(OrderedKeyValuePairs<String>.init)
        self.notify = notify
        self.priority = priority
        self.steps = steps
    }

    init(
        orderedEnv: OrderedKeyValuePairs<String>? = nil,
        orderedAgents: OrderedKeyValuePairs<JSONValue>? = nil,
        orderedMetadata: OrderedKeyValuePairs<String>? = nil,
        notify: [NotificationRule]? = nil,
        priority: Int? = nil,
        steps: [PipelineStep],
    ) {
        self.orderedEnv = orderedEnv
        self.orderedAgents = orderedAgents
        self.orderedMetadata = orderedMetadata
        self.notify = notify
        self.priority = priority
        self.steps = steps
    }

    /// The underlying serializable model used for serialization.
    var serializableModel: PipelineModel {
        PipelineModel(
            orderedEnv: orderedEnv,
            orderedAgents: orderedAgents,
            orderedMetadata: orderedMetadata,
            notify: notify,
            priority: priority,
            steps: steps.map(\.model),
        )
    }

    /// Encodes the pipeline as Buildkite-compatible YAML.
    public func toYAML() throws -> String {
        try PipelineRenderer.renderYAML(serializableModel)
    }

    /// Encodes the pipeline as JSON, useful for debugging schema mapping.
    public func toJSON(prettyPrinted: Bool = true) throws -> String {
        try PipelineRenderer.renderJSON(serializableModel, prettyPrinted: prettyPrinted)
    }

    /// Encodes the pipeline as Buildkite-compatible YAML.
    public var yamlString: String {
        get throws {
            try toYAML()
        }
    }

    /// Encodes the pipeline as JSON.
    public var jsonString: String {
        get throws {
            try toJSON()
        }
    }
}

public extension Pipeline {
    /// Sets the top-level default job priority for steps without an explicit step priority.
    func priority(_ value: Int) -> Pipeline {
        Pipeline(
            orderedEnv: orderedEnv,
            orderedAgents: orderedAgents,
            orderedMetadata: orderedMetadata,
            notify: notify,
            priority: value,
            steps: steps,
        )
    }
}
