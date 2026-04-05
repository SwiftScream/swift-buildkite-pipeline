import Foundation

/// A command value that can be encoded as either a single command or multiple commands.
public enum CommandValue: Encodable, Equatable, Sendable {
    /// The `single` case.
    case single(String)
    /// The `multiple` case.
    case multiple([String])

    /// Creates a new instance.
    public init(_ command: String) {
        self = .single(command)
    }

    /// Creates a new instance.
    public init(_ commands: [String]) {
        if commands.count == 1, let first = commands.first {
            self = .single(first)
        } else {
            self = .multiple(commands)
        }
    }

    /// The `values` value.
    public var values: [String] {
        switch self {
        case .single(let command):
            [command]
        case .multiple(let commands):
            commands
        }
    }

    /// Encodes this value.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let command):
            try container.encode(command)
        case .multiple(let commands):
            try container.encode(commands)
        }
    }
}

/// Buildkite artifact path globs.
///
/// This value is canonically encoded as a single semicolon-separated string
/// to match Buildkite's expected `artifact_paths` representation.
struct ArtifactPaths: Encodable, Equatable, Sendable {
    /// The `paths` value.
    var paths: [String]

    /// Creates a new instance.
    init(_ path: String) {
        paths = [path]
    }

    /// Creates a new instance.
    init(_ paths: [String]) {
        self.paths = paths
    }

    /// Appends an artifact path glob.
    mutating func append(_ path: String) {
        paths.append(path)
    }

    /// The `joined` value.
    var joined: String {
        paths.joined(separator: ";")
    }

    /// Encodes this value.
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(joined)
    }
}

/// Buildkite concurrency resolution behavior for command steps.
public enum ConcurrencyMethod: String, Encodable, Equatable, Sendable {
    /// The `ordered` case.
    case ordered
    /// The `eager` case.
    case eager
}

/// Coupled concurrency settings for command steps.
public struct StepConcurrency: Encodable, Equatable, Sendable {
    /// The `limit` value.
    public var limit: Int
    /// The `group` value.
    public var group: String
    /// The `method` value.
    public var method: ConcurrencyMethod?

    /// Creates a new instance.
    public init(limit: Int, group: String, method: ConcurrencyMethod? = nil) {
        self.limit = limit
        self.group = group
        self.method = method
    }
}

/// A typed Buildkite step key used for wiring dependencies safely.
public struct StepKey: RawRepresentable, Hashable, Encodable, Sendable {
    /// The `rawValue` value.
    public let rawValue: String

    /// Creates a new instance.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a new instance.
    public init(_ value: String) {
        rawValue = value
    }
}

/// A type that can be converted into a step dependency.
public protocol StepDependencyConvertible: Sendable {
    /// The `stepDependency` value.
    var stepDependency: StepDependency { get }
}

extension StepKey: StepDependencyConvertible {
    /// The `stepDependency` value.
    public var stepDependency: StepDependency {
        StepDependency(self)
    }
}

/// A typed dependency entry that references another step key.
public struct StepDependency: Equatable, Sendable, StepDependencyConvertible {
    /// The `key` value.
    public var key: StepKey
    /// The `allowFailure` value.
    public var allowFailure: Bool?

    /// Creates a new instance.
    public init(_ key: StepKey, allowFailure: Bool? = nil) {
        self.key = key
        self.allowFailure = allowFailure
    }

    /// Creates a new instance.
    public init(key: StepKey, allowFailure: Bool? = nil) {
        self.init(key, allowFailure: allowFailure)
    }

    /// The `stepDependency` value.
    public var stepDependency: StepDependency {
        self
    }

    var reference: DependencyReference {
        guard let allowFailure else {
            return .key(key.rawValue)
        }

        return .detailed(Dependency(step: key.rawValue, allowFailure: allowFailure))
    }
}

/// A dependency reference supported by Buildkite's `depends_on` field.
enum DependencyReference: Encodable, Equatable, Sendable {
    case key(String)
    case detailed(Dependency)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .key(let key):
            try container.encode(key)
        case .detailed(let dependency):
            try container.encode(dependency)
        }
    }
}

/// A single dependency object inside `depends_on`.
struct Dependency: Encodable, Equatable, Sendable {
    var step: String
    var allowFailure: Bool?

    init(step: String, allowFailure: Bool? = nil) {
        self.step = step
        self.allowFailure = allowFailure
    }

    enum CodingKeys: String, CodingKey {
        case step
        case allowFailure = "allow_failure"
    }
}

/// A `depends_on` value that may be encoded as one dependency or many.
enum DependencyCondition: Encodable, Equatable, Sendable {
    case single(DependencyReference)
    case multiple([DependencyReference])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let dependency):
            try container.encode(dependency)
        case .multiple(let dependencies):
            try container.encode(dependencies)
        }
    }
}

func dependencyCondition(from dependencies: [StepDependency]?) -> DependencyCondition? {
    guard let dependencies, !dependencies.isEmpty else {
        return nil
    }

    let references = dependencies.map(\.reference)
    if references.count == 1, let first = references.first {
        return .single(first)
    }

    return .multiple(references)
}

func dependencies(from condition: DependencyCondition?) -> [StepDependency] {
    guard let condition else {
        return []
    }

    switch condition {
    case .single(let reference):
        return [stepDependency(from: reference)]
    case .multiple(let references):
        return references.map(stepDependency(from:))
    }
}

private func stepDependency(from reference: DependencyReference) -> StepDependency {
    switch reference {
    case .key(let key):
        StepDependency(StepKey(key))
    case .detailed(let dependency):
        StepDependency(StepKey(dependency.step), allowFailure: dependency.allowFailure)
    }
}

/// Flexible plugin declaration with optional configuration.
public struct Plugin: Encodable, Equatable, Sendable {
    /// The `source` value.
    public var source: String
    var orderedOptions: OrderedKeyValuePairs<JSONValue>?
    /// The `options` value.
    public var options: [String: JSONValue]? {
        get { orderedOptions?.dictionary }
        set { orderedOptions = newValue.map(OrderedKeyValuePairs<JSONValue>.init) }
    }

    /// Creates a new instance.
    public init(_ source: String, options: KeyValuePairs<String, JSONValue>? = nil) {
        self.source = source
        orderedOptions = options.map(OrderedKeyValuePairs<JSONValue>.init)
    }

    /// Creates a plugin specifier from a base source and ref (tag, branch, or SHA).
    ///
    /// For example:
    /// - `Plugin("docker", ref: "v5.9.0")` -> `docker#v5.9.0`
    /// - `Plugin("my/plugin", ref: "main")` -> `my/plugin#main`
    public init(_ source: String, ref: String, options: KeyValuePairs<String, JSONValue>? = nil) {
        self.source = "\(source)#\(ref)"
        orderedOptions = options.map(OrderedKeyValuePairs<JSONValue>.init)
    }

    /// Encodes this value.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        guard let sourceKey = DynamicCodingKey(stringValue: source) else {
            throw EncodingError.invalidValue(
                source,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Plugin source is not a valid coding key",
                ),
            )
        }

        if let orderedOptions {
            var optionsContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: sourceKey)
            for entry in orderedOptions.allEntries {
                guard let optionKey = DynamicCodingKey(stringValue: entry.key) else {
                    throw EncodingError.invalidValue(
                        entry.key,
                        EncodingError.Context(
                            codingPath: encoder.codingPath,
                            debugDescription: "Plugin option key is not a valid coding key",
                        ),
                    )
                }
                try optionsContainer.encode(entry.value, forKey: optionKey)
            }
        } else {
            try container.encodeNil(forKey: sourceKey)
        }
    }
}

/// Exit status predicate used by `soft_fail`.
public struct SoftFailCondition: Encodable, Equatable, Sendable {
    /// The `exitStatus` value.
    public var exitStatus: Int

    /// Creates a new instance.
    public init(exitStatus: Int) {
        self.exitStatus = exitStatus
    }

    enum CodingKeys: String, CodingKey {
        case exitStatus = "exit_status"
    }
}

/// Buildkite soft-fail behavior.
public enum SoftFailPolicy: Encodable, Equatable, Sendable {
    /// The `enabled` case.
    case enabled(Bool)
    /// The `conditions` case.
    case conditions([SoftFailCondition])

    /// Encodes this value.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .enabled(let value):
            try container.encode(value)
        case .conditions(let conditions):
            try container.encode(conditions)
        }
    }
}

/// Automatic retry rule.
public struct RetryAutomaticRule: Encodable, Equatable, Sendable {
    /// The `exitStatus` value.
    public var exitStatus: Int?
    /// The `signalReason` value.
    public var signalReason: String?
    /// The `signal` value.
    public var signal: String?
    /// The `limit` value.
    public var limit: Int?

    /// Creates a new instance.
    public init(
        exitStatus: Int? = nil,
        signalReason: String? = nil,
        signal: String? = nil,
        limit: Int? = nil,
    ) {
        self.exitStatus = exitStatus
        self.signalReason = signalReason
        self.signal = signal
        self.limit = limit
    }

    enum CodingKeys: String, CodingKey {
        case exitStatus = "exit_status"
        case signalReason = "signal_reason"
        case signal
        case limit
    }
}

/// Automatic retry configuration.
public enum RetryAutomatic: Encodable, Equatable, Sendable {
    /// The `enabled` case.
    case enabled(Bool)
    /// The `limit` case.
    case limit(Int)
    /// The `rules` case.
    case rules([RetryAutomaticRule])

    /// Encodes this value.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .enabled(let value):
            try container.encode(value)
        case .limit(let limit):
            try container.encode(RetryAutomaticRule(limit: limit))
        case .rules(let rules):
            try container.encode(rules)
        }
    }
}

/// Manual retry configuration.
public struct RetryManual: Encodable, Equatable, Sendable {
    /// The `allowed` value.
    public var allowed: Bool?
    /// The `permitOnPassed` value.
    public var permitOnPassed: Bool?
    /// The `reason` value.
    public var reason: String?

    /// Creates a new instance.
    public init(allowed: Bool? = nil, permitOnPassed: Bool?, reason: String? = nil) {
        self.allowed = allowed
        self.permitOnPassed = permitOnPassed
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey {
        case allowed
        case permitOnPassed = "permit_on_passed"
        case reason
    }
}

/// Buildkite retry settings.
public struct RetryPolicy: Encodable, Equatable, Sendable {
    /// The `automatic` value.
    public var automatic: RetryAutomatic?
    /// The `manual` value.
    public var manual: RetryManual?

    /// Creates a new instance.
    public init(automatic: RetryAutomatic? = nil, manual: RetryManual? = nil) {
        self.automatic = automatic
        self.manual = manual
    }

    enum CodingKeys: String, CodingKey {
        case automatic
        case manual
    }
}

/// A matrix adjustment entry.
public struct MatrixAdjustment: Encodable, Equatable, Sendable {
    /// The `with` value.
    public var with: [String: String]
    /// The `softFail` value.
    public var softFail: Bool?
    /// The `skip` value.
    public var skip: Bool?

    /// Creates a new instance.
    public init(with: [String: String], softFail: Bool? = nil, skip: Bool? = nil) {
        self.with = with
        self.softFail = softFail
        self.skip = skip
    }

    enum CodingKeys: String, CodingKey {
        case with
        case softFail = "soft_fail"
        case skip
    }

    /// Encodes this value.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var withContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .with)
        for key in with.keys.sorted() {
            guard let codingKey = DynamicCodingKey(stringValue: key), let value = with[key] else {
                throw EncodingError.invalidValue(
                    key,
                    EncodingError.Context(
                        codingPath: encoder.codingPath,
                        debugDescription: "Matrix adjustment key is not encodable",
                    ),
                )
            }
            try withContainer.encode(value, forKey: codingKey)
        }
        try container.encodeIfPresent(softFail, forKey: .softFail)
        try container.encodeIfPresent(skip, forKey: .skip)
    }
}

/// Buildkite matrix configuration.
public struct MatrixConfiguration: Encodable, Equatable, Sendable {
    /// The `setup` value.
    public var setup: [String: [String]]
    /// The `adjustments` value.
    public var adjustments: [MatrixAdjustment]?

    /// Creates a new instance.
    public init(setup: [String: [String]], adjustments: [MatrixAdjustment]? = nil) {
        self.setup = setup
        self.adjustments = adjustments
    }

    enum CodingKeys: String, CodingKey {
        case setup
        case adjustments
    }

    /// Encodes this value.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var setupContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .setup)
        for key in setup.keys.sorted() {
            guard let codingKey = DynamicCodingKey(stringValue: key), let value = setup[key] else {
                throw EncodingError.invalidValue(
                    key,
                    EncodingError.Context(
                        codingPath: encoder.codingPath,
                        debugDescription: "Matrix setup key is not encodable",
                    ),
                )
            }
            try setupContainer.encode(value, forKey: codingKey)
        }
        try container.encodeIfPresent(adjustments, forKey: .adjustments)
    }
}

/// A block/input text field.
public struct TextBlockField: Encodable, Equatable, Sendable {
    /// The `key` value.
    public var key: String
    /// The `text` value.
    public var text: String
    /// The `hint` value.
    public var hint: String?
    /// The `required` value.
    public var required: Bool?
    /// The `defaultValue` value.
    public var defaultValue: String?

    /// Creates a new instance.
    public init(
        key: String,
        text: String,
        hint: String? = nil,
        required: Bool? = nil,
        defaultValue: String? = nil,
    ) {
        self.key = key
        self.text = text
        self.hint = hint
        self.required = required
        self.defaultValue = defaultValue
    }

    enum CodingKeys: String, CodingKey {
        case key
        case text
        case hint
        case required
        case defaultValue = "default"
    }
}

/// A selectable option in block/input select fields.
public struct SelectOption: Encodable, Equatable, Sendable {
    /// The `label` value.
    public var label: String
    /// The `value` value.
    public var value: String

    /// Creates a new instance.
    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

/// A block/input select field.
public struct SelectBlockField: Encodable, Equatable, Sendable {
    /// The `key` value.
    public var key: String
    /// The `select` value.
    public var select: String
    /// The `options` value.
    public var options: [SelectOption]
    /// The `hint` value.
    public var hint: String?
    /// The `required` value.
    public var required: Bool?
    /// The `multiple` value.
    public var multiple: Bool?
    /// The `defaultValue` value.
    public var defaultValue: String?

    /// Creates a new instance.
    public init(
        key: String,
        select: String,
        options: [SelectOption],
        hint: String? = nil,
        required: Bool? = nil,
        multiple: Bool? = nil,
        defaultValue: String? = nil,
    ) {
        self.key = key
        self.select = select
        self.options = options
        self.hint = hint
        self.required = required
        self.multiple = multiple
        self.defaultValue = defaultValue
    }

    enum CodingKeys: String, CodingKey {
        case key
        case select
        case options
        case hint
        case required
        case multiple
        case defaultValue = "default"
    }
}

/// Buildkite block/input field representation.
public enum BlockField: Encodable, Equatable, Sendable {
    /// The `text` case.
    case text(TextBlockField)
    /// The `select` case.
    case select(SelectBlockField)

    /// Encodes this value.
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let field):
            try field.encode(to: encoder)
        case .select(let field):
            try field.encode(to: encoder)
        }
    }
}

/// Trigger build payload.
public struct TriggerBuild: Encodable, Equatable, Sendable {
    /// The `branch` value.
    public var branch: String?
    /// The `commit` value.
    public var commit: String?
    /// The `message` value.
    public var message: String?
    /// The `env` value.
    public var env: [String: String]?
    /// The `metadata` value.
    public var metadata: [String: String]?

    /// Creates a new instance.
    public init(
        branch: String? = nil,
        commit: String? = nil,
        message: String? = nil,
        env: [String: String]? = nil,
        metadata: [String: String]? = nil,
    ) {
        self.branch = branch
        self.commit = commit
        self.message = message
        self.env = env
        self.metadata = metadata
    }

    enum CodingKeys: String, CodingKey {
        case branch
        case commit
        case message
        case env
        case metadata = "meta_data"
    }
}

/// Build notifications.
public enum NotificationRule: Encodable, Equatable, Sendable {
    // swiftlint:disable:next todo
    // TODO: Add support for additional Buildkite notification backends and richer payload variants.
    /// The `email` case.
    case email(EmailNotification)
    /// The `slack` case.
    case slack(SlackNotification)
    /// The `webhook` case.
    case webhook(WebhookNotification)

    /// Encodes this value.
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .email(let value):
            try value.encode(to: encoder)
        case .slack(let value):
            try value.encode(to: encoder)
        case .webhook(let value):
            try value.encode(to: encoder)
        }
    }
}

/// Command-step notification rules (`command.notify`).
///
/// These are intentionally narrower than build-level notifications.
public enum CommandStepNotificationRule: Encodable, Equatable, Sendable {
    /// Sends a Slack notification for the step.
    case slack(SlackNotification)
    /// Emits the simple `github_check` notification selector.
    case githubCheck
    /// Emits the simple `github_commit_status` notification selector.
    case githubCommitStatus

    /// Encodes this value.
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .slack(let value):
            try value.encode(to: encoder)
        case .githubCheck:
            var container = encoder.singleValueContainer()
            try container.encode("github_check")
        case .githubCommitStatus:
            var container = encoder.singleValueContainer()
            try container.encode("github_commit_status")
        }
    }
}

/// `EmailNotification`.
public struct EmailNotification: Encodable, Equatable, Sendable {
    /// The `email` value.
    public var email: String
    /// The `condition` value.
    public var condition: String?

    /// Creates a new instance.
    public init(email: String, condition: String? = nil) {
        self.email = email
        self.condition = condition
    }

    enum CodingKeys: String, CodingKey {
        case email
        case condition = "if"
    }
}

/// `SlackNotification`.
public struct SlackNotification: Encodable, Equatable, Sendable {
    /// The `slack` value.
    public var slack: String
    /// The `condition` value.
    public var condition: String?

    /// Creates a new instance.
    public init(slack: String, condition: String? = nil) {
        self.slack = slack
        self.condition = condition
    }

    enum CodingKeys: String, CodingKey {
        case slack
        case condition = "if"
    }
}

/// `WebhookNotification`.
public struct WebhookNotification: Encodable, Equatable, Sendable {
    /// The `webhook` value.
    public var webhook: URL
    /// The `condition` value.
    public var condition: String?

    /// Creates a new instance.
    public init(webhook: URL, condition: String? = nil) {
        self.webhook = webhook
        self.condition = condition
    }

    enum CodingKeys: String, CodingKey {
        case webhook
        case condition = "if"
    }
}
