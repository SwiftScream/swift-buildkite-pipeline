import Foundation

/// A value that can be converted into a composable pipeline fragment.
public protocol PipelineFragmentConvertible: Sendable {
    /// Returns the fragment representation.
    var pipelineFragment: PipelineFragment { get }
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
    /// The composed pipeline fragment.
    public let fragment: PipelineFragment

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
        fragment = PipelineFragment.concatenating(built.fragments)
    }

    /// Creates a pipeline from direct values.
    public init(
        env: [String: String]? = nil,
        agents: [String: JSONValue]? = nil,
        notify: [NotificationRule]? = nil,
        metadata: [String: String]? = nil,
        priority: Int? = nil,
        fragment: PipelineFragment,
    ) {
        orderedEnv = env.map(OrderedKeyValuePairs<String>.init)
        orderedAgents = agents.map(OrderedKeyValuePairs<JSONValue>.init)
        orderedMetadata = metadata.map(OrderedKeyValuePairs<String>.init)
        self.notify = notify
        self.priority = priority
        self.fragment = fragment
    }

    init(
        orderedEnv: OrderedKeyValuePairs<String>? = nil,
        orderedAgents: OrderedKeyValuePairs<JSONValue>? = nil,
        orderedMetadata: OrderedKeyValuePairs<String>? = nil,
        notify: [NotificationRule]? = nil,
        priority: Int? = nil,
        fragment: PipelineFragment,
    ) {
        self.orderedEnv = orderedEnv
        self.orderedAgents = orderedAgents
        self.orderedMetadata = orderedMetadata
        self.notify = notify
        self.priority = priority
        self.fragment = fragment
    }

    var materializedStepModels: [StepModel] {
        fragment.materializedModels()
    }

    /// The underlying serializable model used for serialization.
    var serializableModel: PipelineModel {
        PipelineModel(
            orderedEnv: orderedEnv,
            orderedAgents: orderedAgents,
            orderedMetadata: orderedMetadata,
            notify: notify,
            priority: priority,
            steps: materializedStepModels,
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
            fragment: fragment,
        )
    }
}
