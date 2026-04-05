import Foundation

/// Internal step representation aligned with Buildkite's schema.
enum StepModel: Encodable, Equatable, Sendable {
    case command(CommandStepModel)
    case wait(WaitStepModel)
    case block(BlockStepModel)
    case trigger(TriggerStepModel)
    case group(GroupStepModel)

    func encode(to encoder: Encoder) throws {
        switch self {
        case .command(let step):
            try step.encode(to: encoder)
        case .wait(let step):
            try step.encode(to: encoder)
        case .block(let step):
            try step.encode(to: encoder)
        case .trigger(let step):
            try step.encode(to: encoder)
        case .group(let step):
            try step.encode(to: encoder)
        }
    }
}

/// A command step (`command` / `commands`).
struct CommandStepModel: Encodable, Equatable, Sendable {
    var label: String?
    var command: CommandValue?
    var key: String?
    var plugins: [Plugin]?
    var orderedAgents: OrderedKeyValuePairs<JSONValue>?
    var orderedEnv: OrderedKeyValuePairs<String>?
    var agents: [String: JSONValue]? {
        get { orderedAgents?.dictionary }
        set { orderedAgents = newValue.map(OrderedKeyValuePairs<JSONValue>.init) }
    }

    var env: [String: String]? {
        get { orderedEnv?.dictionary }
        set { orderedEnv = newValue.map(OrderedKeyValuePairs<String>.init) }
    }

    var artifactPaths: ArtifactPaths?
    var branches: String?
    var concurrency: Int?
    var concurrencyGroup: String?
    var concurrencyMethod: ConcurrencyMethod?
    var dependsOn: DependencyCondition?
    var condition: String?
    var softFail: SoftFailPolicy?
    var retry: RetryPolicy?
    var timeoutInMinutes: Int?
    var matrix: MatrixConfiguration?
    var notify: [CommandStepNotificationRule]?
    var priority: Int?
    var allowDependencyFailure: Bool?
    var parallelism: Int?

    init(
        label: String? = nil,
        command: CommandValue? = nil,
        key: String? = nil,
        plugins: [Plugin]? = nil,
        agents: [String: JSONValue]? = nil,
        env: [String: String]? = nil,
        artifactPaths: ArtifactPaths? = nil,
        branches: String? = nil,
        concurrency: Int? = nil,
        concurrencyGroup: String? = nil,
        concurrencyMethod: ConcurrencyMethod? = nil,
        dependsOn: DependencyCondition? = nil,
        condition: String? = nil,
        softFail: SoftFailPolicy? = nil,
        retry: RetryPolicy? = nil,
        timeoutInMinutes: Int? = nil,
        matrix: MatrixConfiguration? = nil,
        notify: [CommandStepNotificationRule]? = nil,
        priority: Int? = nil,
        allowDependencyFailure: Bool? = nil,
        parallelism: Int? = nil,
    ) {
        self.label = label
        self.command = command
        self.key = key
        self.plugins = plugins
        orderedAgents = agents.map(OrderedKeyValuePairs<JSONValue>.init)
        orderedEnv = env.map(OrderedKeyValuePairs<String>.init)
        self.artifactPaths = artifactPaths
        self.branches = branches
        self.concurrency = concurrency
        self.concurrencyGroup = concurrencyGroup
        self.concurrencyMethod = concurrencyMethod
        self.dependsOn = dependsOn
        self.condition = condition
        self.softFail = softFail
        self.retry = retry
        self.timeoutInMinutes = timeoutInMinutes
        self.matrix = matrix
        self.notify = notify
        self.priority = priority
        self.allowDependencyFailure = allowDependencyFailure
        self.parallelism = parallelism
    }

    enum CodingKeys: String, CodingKey {
        case label
        case key
        case dependsOn = "depends_on"
        case command
        case agents
        case env
        case plugins
        case allowDependencyFailure = "allow_dependency_failure"
        case artifactPaths = "artifact_paths"
        case branches
        case concurrency
        case concurrencyGroup = "concurrency_group"
        case concurrencyMethod = "concurrency_method"
        case condition = "if"
        case matrix
        case notify
        case parallelism
        case priority
        case retry
        case softFail = "soft_fail"
        case timeoutInMinutes = "timeout_in_minutes"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Pin common readability keys at the top.
        try container.encodeIfPresent(label, forKey: .label)
        try container.encodeIfPresent(key, forKey: .key)
        try container.encodeIfPresent(dependsOn, forKey: .dependsOn)
        try container.encodeIfPresent(command, forKey: .command)
        try container.encodeIfPresent(orderedAgents, forKey: .agents)
        try container.encodeIfPresent(orderedEnv, forKey: .env)
        try container.encodeIfPresent(plugins, forKey: .plugins)

        // Remaining keys stay alphabetically ordered by Buildkite field name.
        try container.encodeIfPresent(allowDependencyFailure, forKey: .allowDependencyFailure)
        try container.encodeIfPresent(artifactPaths, forKey: .artifactPaths)
        try container.encodeIfPresent(branches, forKey: .branches)
        try container.encodeIfPresent(concurrency, forKey: .concurrency)
        try container.encodeIfPresent(concurrencyGroup, forKey: .concurrencyGroup)
        try container.encodeIfPresent(concurrencyMethod, forKey: .concurrencyMethod)
        try container.encodeIfPresent(condition, forKey: .condition)
        try container.encodeIfPresent(matrix, forKey: .matrix)
        try container.encodeIfPresent(notify, forKey: .notify)
        try container.encodeIfPresent(parallelism, forKey: .parallelism)
        try container.encodeIfPresent(priority, forKey: .priority)
        try container.encodeIfPresent(retry, forKey: .retry)
        try container.encodeIfPresent(softFail, forKey: .softFail)
        try container.encodeIfPresent(timeoutInMinutes, forKey: .timeoutInMinutes)
    }
}

/// A wait step (`wait`).
struct WaitStepModel: Encodable, Equatable, Sendable {
    var key: String?
    var continueOnFailure: Bool?
    var dependsOn: DependencyCondition?
    var allowDependencyFailure: Bool?
    var condition: String?
    var branches: String?

    init(
        key: String? = nil,
        continueOnFailure: Bool? = nil,
        dependsOn: DependencyCondition? = nil,
        allowDependencyFailure: Bool? = nil,
        condition: String? = nil,
        branches: String? = nil,
    ) {
        self.key = key
        self.continueOnFailure = continueOnFailure
        self.dependsOn = dependsOn
        self.allowDependencyFailure = allowDependencyFailure
        self.condition = condition
        self.branches = branches
    }

    enum CodingKeys: String, CodingKey {
        case wait
        case key
        case continueOnFailure = "continue_on_failure"
        case dependsOn = "depends_on"
        case allowDependencyFailure = "allow_dependency_failure"
        case condition = "if"
        case branches
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeNil(forKey: .wait)
        try container.encodeIfPresent(key, forKey: .key)
        try container.encodeIfPresent(continueOnFailure, forKey: .continueOnFailure)
        try container.encodeIfPresent(dependsOn, forKey: .dependsOn)
        try container.encodeIfPresent(allowDependencyFailure, forKey: .allowDependencyFailure)
        try container.encodeIfPresent(condition, forKey: .condition)
        try container.encodeIfPresent(branches, forKey: .branches)
    }
}

/// A block or input step (`block` or `input`).
struct BlockStepModel: Encodable, Equatable, Sendable {
    var block: String?
    var input: String?
    var key: String?
    var fields: [BlockField]?
    var prompt: String?
    var branches: String?
    var dependsOn: DependencyCondition?
    var allowDependencyFailure: Bool?
    var condition: String?

    init(
        block: String? = nil,
        input: String? = nil,
        key: String? = nil,
        fields: [BlockField]? = nil,
        prompt: String? = nil,
        branches: String? = nil,
        dependsOn: DependencyCondition? = nil,
        allowDependencyFailure: Bool? = nil,
        condition: String? = nil,
    ) {
        self.block = block
        self.input = input
        self.key = key
        self.fields = fields
        self.prompt = prompt
        self.branches = branches
        self.dependsOn = dependsOn
        self.allowDependencyFailure = allowDependencyFailure
        self.condition = condition
    }

    enum CodingKeys: String, CodingKey {
        case block
        case input
        case key
        case fields
        case prompt
        case branches
        case dependsOn = "depends_on"
        case allowDependencyFailure = "allow_dependency_failure"
        case condition = "if"
    }

    func encode(to encoder: Encoder) throws {
        if shouldEncodeAsBareBlockMarker {
            var single = encoder.singleValueContainer()
            try single.encode("block")
            return
        }

        var container = encoder.container(keyedBy: CodingKeys.self)

        if let input {
            try container.encode(input, forKey: .input)
        } else if let block {
            try container.encode(block, forKey: .block)
        } else {
            // Nameless block with additional attributes retains explicit block identity.
            // Buildkite expects `block` to be a string in object form.
            try container.encode("", forKey: .block)
        }

        try container.encodeIfPresent(key, forKey: .key)
        try container.encodeIfPresent(fields, forKey: .fields)
        try container.encodeIfPresent(prompt, forKey: .prompt)
        try container.encodeIfPresent(branches, forKey: .branches)
        try container.encodeIfPresent(dependsOn, forKey: .dependsOn)
        try container.encodeIfPresent(allowDependencyFailure, forKey: .allowDependencyFailure)
        try container.encodeIfPresent(condition, forKey: .condition)
    }

    private var shouldEncodeAsBareBlockMarker: Bool {
        block == nil &&
            input == nil &&
            key == nil &&
            fields == nil &&
            prompt == nil &&
            branches == nil &&
            dependsOn == nil &&
            allowDependencyFailure == nil &&
            condition == nil
    }
}

/// A trigger step (`trigger`).
struct TriggerStepModel: Encodable, Equatable, Sendable {
    // swiftlint:disable:next todo
    // TODO: Extend trigger coverage for additional schema properties (e.g. strategy).
    var trigger: String
    var label: String?
    var key: String?
    var condition: String?
    var branches: String?
    var dependsOn: DependencyCondition?
    var allowDependencyFailure: Bool?
    var async: Bool?
    var softFail: SoftFailPolicy?
    var retry: RetryPolicy?
    var build: TriggerBuild?

    init(
        trigger: String,
        label: String? = nil,
        key: String? = nil,
        condition: String? = nil,
        branches: String? = nil,
        dependsOn: DependencyCondition? = nil,
        allowDependencyFailure: Bool? = nil,
        async: Bool? = nil,
        softFail: SoftFailPolicy? = nil,
        retry: RetryPolicy? = nil,
        build: TriggerBuild? = nil,
    ) {
        self.trigger = trigger
        self.label = label
        self.key = key
        self.condition = condition
        self.branches = branches
        self.dependsOn = dependsOn
        self.allowDependencyFailure = allowDependencyFailure
        self.async = async
        self.softFail = softFail
        self.retry = retry
        self.build = build
    }

    enum CodingKeys: String, CodingKey {
        case trigger
        case label
        case key
        case condition = "if"
        case branches
        case dependsOn = "depends_on"
        case allowDependencyFailure = "allow_dependency_failure"
        case async
        case softFail = "soft_fail"
        case retry
        case build
    }
}

/// A group step with nested child steps (`group`).
struct GroupStepModel: Encodable, Equatable, Sendable {
    var group: String
    var key: String?
    var condition: String?
    var branches: String?
    var dependsOn: DependencyCondition?
    var allowDependencyFailure: Bool?
    var steps: [StepModel]
    var notify: [NotificationRule]?

    init(
        group: String,
        key: String? = nil,
        condition: String? = nil,
        branches: String? = nil,
        dependsOn: DependencyCondition? = nil,
        allowDependencyFailure: Bool? = nil,
        steps: [StepModel],
        notify: [NotificationRule]? = nil,
    ) {
        self.group = group
        self.key = key
        self.condition = condition
        self.branches = branches
        self.dependsOn = dependsOn
        self.allowDependencyFailure = allowDependencyFailure
        self.steps = steps
        self.notify = notify
    }

    enum CodingKeys: String, CodingKey {
        case group
        case key
        case condition = "if"
        case branches
        case dependsOn = "depends_on"
        case allowDependencyFailure = "allow_dependency_failure"
        case steps
        case notify
    }
}
