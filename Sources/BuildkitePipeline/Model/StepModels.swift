import Foundation

/// Internal step representation aligned with Buildkite's schema.
struct StepModel: Encodable, Equatable, Sendable {
    enum Payload: Equatable, Sendable {
        case command(CommandStepModel)
        case wait(WaitStepModel)
        case block(BlockStepModel)
        case trigger(TriggerStepModel)
        case group(GroupStepModel)
    }

    var key: String?
    var dependsOn: DependencyCondition?
    var allowDependencyFailure: Bool?
    var condition: String?
    var branches: String?
    var payload: Payload

    init(
        key: String? = nil,
        dependsOn: DependencyCondition? = nil,
        allowDependencyFailure: Bool? = nil,
        condition: String? = nil,
        branches: String? = nil,
        payload: Payload,
    ) {
        self.key = key
        self.dependsOn = dependsOn
        self.allowDependencyFailure = allowDependencyFailure
        self.condition = condition
        self.branches = branches
        self.payload = payload
    }

    static func command(
        _ payload: CommandStepModel,
        key: String? = nil,
        dependsOn: DependencyCondition? = nil,
        allowDependencyFailure: Bool? = nil,
        condition: String? = nil,
        branches: String? = nil,
    ) -> StepModel {
        StepModel(
            key: key,
            dependsOn: dependsOn,
            allowDependencyFailure: allowDependencyFailure,
            condition: condition,
            branches: branches,
            payload: .command(payload),
        )
    }

    static func wait(
        _ payload: WaitStepModel,
        key: String? = nil,
        dependsOn: DependencyCondition? = nil,
        allowDependencyFailure: Bool? = nil,
        condition: String? = nil,
        branches: String? = nil,
    ) -> StepModel {
        StepModel(
            key: key,
            dependsOn: dependsOn,
            allowDependencyFailure: allowDependencyFailure,
            condition: condition,
            branches: branches,
            payload: .wait(payload),
        )
    }

    static func block(
        _ payload: BlockStepModel,
        key: String? = nil,
        dependsOn: DependencyCondition? = nil,
        allowDependencyFailure: Bool? = nil,
        condition: String? = nil,
        branches: String? = nil,
    ) -> StepModel {
        StepModel(
            key: key,
            dependsOn: dependsOn,
            allowDependencyFailure: allowDependencyFailure,
            condition: condition,
            branches: branches,
            payload: .block(payload),
        )
    }

    static func trigger(
        _ payload: TriggerStepModel,
        key: String? = nil,
        dependsOn: DependencyCondition? = nil,
        allowDependencyFailure: Bool? = nil,
        condition: String? = nil,
        branches: String? = nil,
    ) -> StepModel {
        StepModel(
            key: key,
            dependsOn: dependsOn,
            allowDependencyFailure: allowDependencyFailure,
            condition: condition,
            branches: branches,
            payload: .trigger(payload),
        )
    }

    static func group(
        _ payload: GroupStepModel,
        key: String? = nil,
        dependsOn: DependencyCondition? = nil,
        allowDependencyFailure: Bool? = nil,
        condition: String? = nil,
        branches: String? = nil,
    ) -> StepModel {
        StepModel(
            key: key,
            dependsOn: dependsOn,
            allowDependencyFailure: allowDependencyFailure,
            condition: condition,
            branches: branches,
            payload: .group(payload),
        )
    }

    var command: CommandStepModel? {
        guard case .command(let step) = payload else {
            return nil
        }

        return step
    }

    var wait: WaitStepModel? {
        guard case .wait(let step) = payload else {
            return nil
        }

        return step
    }

    var block: BlockStepModel? {
        guard case .block(let step) = payload else {
            return nil
        }

        return step
    }

    var trigger: TriggerStepModel? {
        guard case .trigger(let step) = payload else {
            return nil
        }

        return step
    }

    var group: GroupStepModel? {
        guard case .group(let step) = payload else {
            return nil
        }

        return step
    }

    mutating func updateCommand(_ update: (inout CommandStepModel) -> Void) {
        guard case .command(var step) = payload else {
            return
        }

        update(&step)
        payload = .command(step)
    }

    mutating func updateWait(_ update: (inout WaitStepModel) -> Void) {
        guard case .wait(var step) = payload else {
            return
        }

        update(&step)
        payload = .wait(step)
    }

    mutating func updateBlock(_ update: (inout BlockStepModel) -> Void) {
        guard case .block(var step) = payload else {
            return
        }

        update(&step)
        payload = .block(step)
    }

    mutating func updateTrigger(_ update: (inout TriggerStepModel) -> Void) {
        guard case .trigger(var step) = payload else {
            return
        }

        update(&step)
        payload = .trigger(step)
    }

    mutating func updateGroup(_ update: (inout GroupStepModel) -> Void) {
        guard case .group(var step) = payload else {
            return
        }

        update(&step)
        payload = .group(step)
    }

    func encode(to encoder: Encoder) throws {
        switch payload {
        case .command(let step):
            try step.encode(sharedFieldsFrom: self, to: encoder)
        case .wait(let step):
            try step.encode(sharedFieldsFrom: self, to: encoder)
        case .block(let step):
            try step.encode(sharedFieldsFrom: self, to: encoder)
        case .trigger(let step):
            try step.encode(sharedFieldsFrom: self, to: encoder)
        case .group(let step):
            try step.encode(sharedFieldsFrom: self, to: encoder)
        }
    }
}

/// A command step (`command` / `commands`).
struct CommandStepModel: Equatable, Sendable {
    var label: String?
    var command: CommandValue?
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
    var concurrency: Int?
    var concurrencyGroup: String?
    var concurrencyMethod: ConcurrencyMethod?
    var softFail: SoftFailPolicy?
    var retry: RetryPolicy?
    var timeoutInMinutes: Int?
    var matrix: MatrixConfiguration?
    var notify: [CommandStepNotificationRule]?
    var priority: Int?
    var parallelism: Int?

    init(
        label: String? = nil,
        command: CommandValue? = nil,
        plugins: [Plugin]? = nil,
        agents: [String: JSONValue]? = nil,
        env: [String: String]? = nil,
        artifactPaths: ArtifactPaths? = nil,
        concurrency: Int? = nil,
        concurrencyGroup: String? = nil,
        concurrencyMethod: ConcurrencyMethod? = nil,
        softFail: SoftFailPolicy? = nil,
        retry: RetryPolicy? = nil,
        timeoutInMinutes: Int? = nil,
        matrix: MatrixConfiguration? = nil,
        notify: [CommandStepNotificationRule]? = nil,
        priority: Int? = nil,
        parallelism: Int? = nil,
    ) {
        self.label = label
        self.command = command
        self.plugins = plugins
        orderedAgents = agents.map(OrderedKeyValuePairs<JSONValue>.init)
        orderedEnv = env.map(OrderedKeyValuePairs<String>.init)
        self.artifactPaths = artifactPaths
        self.concurrency = concurrency
        self.concurrencyGroup = concurrencyGroup
        self.concurrencyMethod = concurrencyMethod
        self.softFail = softFail
        self.retry = retry
        self.timeoutInMinutes = timeoutInMinutes
        self.matrix = matrix
        self.notify = notify
        self.priority = priority
        self.parallelism = parallelism
    }
}

private extension CommandStepModel {
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

    func encode(sharedFieldsFrom step: StepModel, to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Pin common readability keys at the top.
        try container.encodeIfPresent(label, forKey: .label)
        try container.encodeIfPresent(step.key, forKey: .key)
        try container.encodeIfPresent(step.dependsOn, forKey: .dependsOn)
        try container.encodeIfPresent(command, forKey: .command)
        try container.encodeIfPresent(orderedAgents, forKey: .agents)
        try container.encodeIfPresent(orderedEnv, forKey: .env)
        try container.encodeIfPresent(plugins, forKey: .plugins)

        // Remaining keys stay alphabetically ordered by Buildkite field name.
        try container.encodeIfPresent(step.allowDependencyFailure, forKey: .allowDependencyFailure)
        try container.encodeIfPresent(artifactPaths, forKey: .artifactPaths)
        try container.encodeIfPresent(step.branches, forKey: .branches)
        try container.encodeIfPresent(concurrency, forKey: .concurrency)
        try container.encodeIfPresent(concurrencyGroup, forKey: .concurrencyGroup)
        try container.encodeIfPresent(concurrencyMethod, forKey: .concurrencyMethod)
        try container.encodeIfPresent(step.condition, forKey: .condition)
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
struct WaitStepModel: Equatable, Sendable {
    var continueOnFailure: Bool?

    init(continueOnFailure: Bool? = nil) {
        self.continueOnFailure = continueOnFailure
    }
}

private extension WaitStepModel {
    enum CodingKeys: String, CodingKey {
        case wait
        case key
        case continueOnFailure = "continue_on_failure"
        case dependsOn = "depends_on"
        case allowDependencyFailure = "allow_dependency_failure"
        case condition = "if"
        case branches
    }

    func encode(sharedFieldsFrom step: StepModel, to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeNil(forKey: .wait)
        try container.encodeIfPresent(step.key, forKey: .key)
        try container.encodeIfPresent(continueOnFailure, forKey: .continueOnFailure)
        try container.encodeIfPresent(step.dependsOn, forKey: .dependsOn)
        try container.encodeIfPresent(step.allowDependencyFailure, forKey: .allowDependencyFailure)
        try container.encodeIfPresent(step.condition, forKey: .condition)
        try container.encodeIfPresent(step.branches, forKey: .branches)
    }
}

/// A block or input step (`block` or `input`).
struct BlockStepModel: Equatable, Sendable {
    var block: String?
    var input: String?
    var fields: [BlockField]?
    var prompt: String?

    init(
        block: String? = nil,
        input: String? = nil,
        fields: [BlockField]? = nil,
        prompt: String? = nil,
    ) {
        self.block = block
        self.input = input
        self.fields = fields
        self.prompt = prompt
    }
}

private extension BlockStepModel {
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

    func encode(sharedFieldsFrom step: StepModel, to encoder: Encoder) throws {
        if shouldEncodeAsBareBlockMarker(sharedFieldsFrom: step) {
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

        try container.encodeIfPresent(step.key, forKey: .key)
        try container.encodeIfPresent(fields, forKey: .fields)
        try container.encodeIfPresent(prompt, forKey: .prompt)
        try container.encodeIfPresent(step.branches, forKey: .branches)
        try container.encodeIfPresent(step.dependsOn, forKey: .dependsOn)
        try container.encodeIfPresent(step.allowDependencyFailure, forKey: .allowDependencyFailure)
        try container.encodeIfPresent(step.condition, forKey: .condition)
    }

    func shouldEncodeAsBareBlockMarker(sharedFieldsFrom step: StepModel) -> Bool {
        block == nil &&
            input == nil &&
            step.key == nil &&
            fields == nil &&
            prompt == nil &&
            step.branches == nil &&
            step.dependsOn == nil &&
            step.allowDependencyFailure == nil &&
            step.condition == nil
    }
}

/// A trigger step (`trigger`).
struct TriggerStepModel: Equatable, Sendable {
    // swiftlint:disable:next todo
    // TODO: Extend trigger coverage for additional schema properties (e.g. strategy).
    var trigger: String
    var label: String?
    var async: Bool?
    var softFail: SoftFailPolicy?
    var retry: RetryPolicy?
    var build: TriggerBuild?

    init(
        trigger: String,
        label: String? = nil,
        async: Bool? = nil,
        softFail: SoftFailPolicy? = nil,
        retry: RetryPolicy? = nil,
        build: TriggerBuild? = nil,
    ) {
        self.trigger = trigger
        self.label = label
        self.async = async
        self.softFail = softFail
        self.retry = retry
        self.build = build
    }
}

private extension TriggerStepModel {
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

    func encode(sharedFieldsFrom step: StepModel, to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trigger, forKey: .trigger)
        try container.encodeIfPresent(label, forKey: .label)
        try container.encodeIfPresent(step.key, forKey: .key)
        try container.encodeIfPresent(step.condition, forKey: .condition)
        try container.encodeIfPresent(step.branches, forKey: .branches)
        try container.encodeIfPresent(step.dependsOn, forKey: .dependsOn)
        try container.encodeIfPresent(step.allowDependencyFailure, forKey: .allowDependencyFailure)
        try container.encodeIfPresent(async, forKey: .async)
        try container.encodeIfPresent(softFail, forKey: .softFail)
        try container.encodeIfPresent(retry, forKey: .retry)
        try container.encodeIfPresent(build, forKey: .build)
    }
}

/// A group step with nested child steps (`group`).
struct GroupStepModel: Equatable, Sendable {
    var group: String
    var steps: [StepModel]
    var notify: [NotificationRule]?

    init(group: String, steps: [StepModel], notify: [NotificationRule]? = nil) {
        self.group = group
        self.steps = steps
        self.notify = notify
    }
}

private extension GroupStepModel {
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

    func encode(sharedFieldsFrom step: StepModel, to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(group, forKey: .group)
        try container.encodeIfPresent(step.key, forKey: .key)
        try container.encodeIfPresent(step.condition, forKey: .condition)
        try container.encodeIfPresent(step.branches, forKey: .branches)
        try container.encodeIfPresent(step.dependsOn, forKey: .dependsOn)
        try container.encodeIfPresent(step.allowDependencyFailure, forKey: .allowDependencyFailure)
        try container.encode(steps, forKey: .steps)
        try container.encodeIfPresent(notify, forKey: .notify)
    }
}
