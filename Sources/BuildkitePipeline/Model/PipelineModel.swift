import Foundation

/// The root object for a Buildkite pipeline.
struct PipelineModel: Encodable, Equatable, Sendable {
    var orderedEnv: OrderedKeyValuePairs<String>?
    var orderedAgents: OrderedKeyValuePairs<JSONValue>?
    var orderedMetadata: OrderedKeyValuePairs<String>?
    var notify: [NotificationRule]?
    var priority: Int?
    var steps: [StepModel]

    init(
        orderedEnv: OrderedKeyValuePairs<String>? = nil,
        orderedAgents: OrderedKeyValuePairs<JSONValue>? = nil,
        orderedMetadata: OrderedKeyValuePairs<String>? = nil,
        notify: [NotificationRule]? = nil,
        priority: Int? = nil,
        steps: [StepModel],
    ) {
        self.orderedEnv = orderedEnv
        self.orderedAgents = orderedAgents
        self.orderedMetadata = orderedMetadata
        self.notify = notify
        self.priority = priority
        self.steps = steps
    }

    enum CodingKeys: String, CodingKey {
        case env
        case agents
        case notify
        case metadata = "meta_data"
        case priority
        case steps
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(orderedEnv, forKey: .env)
        try container.encodeIfPresent(orderedAgents, forKey: .agents)
        try container.encodeIfPresent(notify, forKey: .notify)
        try container.encodeIfPresent(orderedMetadata, forKey: .metadata)
        try container.encodeIfPresent(priority, forKey: .priority)
        try container.encode(steps, forKey: .steps)
    }
}
