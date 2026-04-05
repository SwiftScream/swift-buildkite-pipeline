import Foundation

/// A command step.
public struct CommandStep: Equatable, Sendable, PipelineFragmentConvertible, StepModelBackedStep {
    var model: StepModel

    /// Returns this value as a composable fragment.
    public var pipelineFragment: PipelineFragment {
        pipelineFragmentValue
    }
}

/// Creates a command step using the result-builder DSL.
public func Step(_ label: String? = nil, @CommandStepBuilder _ content: () -> [CommandStepAttribute]) -> CommandStep {
    var step = commandStepModel(from: content())
    step.label = label
    return CommandStep(model: .command(step))
}

/// Creates a command step using direct parameters.
public func Step(
    label: String? = nil,
    command: String? = nil,
    key: String? = nil,
    plugins: [Plugin]? = nil,
    agents: [String: JSONValue]? = nil,
    env: [String: String]? = nil,
    artifactPaths: [String]? = nil,
    branches: String? = nil,
    concurrency: StepConcurrency? = nil,
    dependsOn: [StepDependency]? = nil,
    condition: String? = nil,
    softFail: SoftFailPolicy? = nil,
    retry: RetryPolicy? = nil,
    timeoutInMinutes: Int? = nil,
    matrix: MatrixConfiguration? = nil,
    notify: [CommandStepNotificationRule]? = nil,
    priority: Int? = nil,
    allowDependencyFailure: Bool? = nil,
    parallelism: Int? = nil,
) -> CommandStep {
    makeCommandStep(
        label: label,
        command: command.map(CommandValue.single),
        key: key,
        plugins: plugins,
        agents: agents,
        env: env,
        artifactPaths: artifactPaths,
        branches: branches,
        concurrency: concurrency,
        dependsOn: dependsOn,
        condition: condition,
        softFail: softFail,
        retry: retry,
        timeoutInMinutes: timeoutInMinutes,
        matrix: matrix,
        notify: notify,
        priority: priority,
        allowDependencyFailure: allowDependencyFailure,
        parallelism: parallelism,
    )
}

/// Creates a command step using direct parameters with a typed step key.
public func Step(
    label: String? = nil,
    command: String? = nil,
    key: StepKey,
    plugins: [Plugin]? = nil,
    agents: [String: JSONValue]? = nil,
    env: [String: String]? = nil,
    artifactPaths: [String]? = nil,
    branches: String? = nil,
    concurrency: StepConcurrency? = nil,
    dependsOn: [StepDependency]? = nil,
    condition: String? = nil,
    softFail: SoftFailPolicy? = nil,
    retry: RetryPolicy? = nil,
    timeoutInMinutes: Int? = nil,
    matrix: MatrixConfiguration? = nil,
    notify: [CommandStepNotificationRule]? = nil,
    priority: Int? = nil,
    allowDependencyFailure: Bool? = nil,
    parallelism: Int? = nil,
) -> CommandStep {
    Step(
        label: label,
        command: command,
        key: key.rawValue,
        plugins: plugins,
        agents: agents,
        env: env,
        artifactPaths: artifactPaths,
        branches: branches,
        concurrency: concurrency,
        dependsOn: dependsOn,
        condition: condition,
        softFail: softFail,
        retry: retry,
        timeoutInMinutes: timeoutInMinutes,
        matrix: matrix,
        notify: notify,
        priority: priority,
        allowDependencyFailure: allowDependencyFailure,
        parallelism: parallelism,
    )
}

/// Creates a command step using direct parameters with multiple commands.
public func Step(
    label: String? = nil,
    command: [String],
    key: String? = nil,
    plugins: [Plugin]? = nil,
    agents: [String: JSONValue]? = nil,
    env: [String: String]? = nil,
    artifactPaths: [String]? = nil,
    branches: String? = nil,
    concurrency: StepConcurrency? = nil,
    dependsOn: [StepDependency]? = nil,
    condition: String? = nil,
    softFail: SoftFailPolicy? = nil,
    retry: RetryPolicy? = nil,
    timeoutInMinutes: Int? = nil,
    matrix: MatrixConfiguration? = nil,
    notify: [CommandStepNotificationRule]? = nil,
    priority: Int? = nil,
    allowDependencyFailure: Bool? = nil,
    parallelism: Int? = nil,
) -> CommandStep {
    makeCommandStep(
        label: label,
        command: .init(command),
        key: key,
        plugins: plugins,
        agents: agents,
        env: env,
        artifactPaths: artifactPaths,
        branches: branches,
        concurrency: concurrency,
        dependsOn: dependsOn,
        condition: condition,
        softFail: softFail,
        retry: retry,
        timeoutInMinutes: timeoutInMinutes,
        matrix: matrix,
        notify: notify,
        priority: priority,
        allowDependencyFailure: allowDependencyFailure,
        parallelism: parallelism,
    )
}

/// Creates a command step using direct parameters with multiple commands and a typed step key.
public func Step(
    label: String? = nil,
    command: [String],
    key: StepKey,
    plugins: [Plugin]? = nil,
    agents: [String: JSONValue]? = nil,
    env: [String: String]? = nil,
    artifactPaths: [String]? = nil,
    branches: String? = nil,
    concurrency: StepConcurrency? = nil,
    dependsOn: [StepDependency]? = nil,
    condition: String? = nil,
    softFail: SoftFailPolicy? = nil,
    retry: RetryPolicy? = nil,
    timeoutInMinutes: Int? = nil,
    matrix: MatrixConfiguration? = nil,
    notify: [CommandStepNotificationRule]? = nil,
    priority: Int? = nil,
    allowDependencyFailure: Bool? = nil,
    parallelism: Int? = nil,
) -> CommandStep {
    Step(
        label: label,
        command: command,
        key: key.rawValue,
        plugins: plugins,
        agents: agents,
        env: env,
        artifactPaths: artifactPaths,
        branches: branches,
        concurrency: concurrency,
        dependsOn: dependsOn,
        condition: condition,
        softFail: softFail,
        retry: retry,
        timeoutInMinutes: timeoutInMinutes,
        matrix: matrix,
        notify: notify,
        priority: priority,
        allowDependencyFailure: allowDependencyFailure,
        parallelism: parallelism,
    )
}

/// Creates a command step using direct parameters with multiple commands.
public func Step(
    label: String? = nil,
    command: String...,
    key: String? = nil,
    plugins: [Plugin]? = nil,
    agents: [String: JSONValue]? = nil,
    env: [String: String]? = nil,
    artifactPaths: [String]? = nil,
    branches: String? = nil,
    concurrency: StepConcurrency? = nil,
    dependsOn: [StepDependency]? = nil,
    condition: String? = nil,
    softFail: SoftFailPolicy? = nil,
    retry: RetryPolicy? = nil,
    timeoutInMinutes: Int? = nil,
    matrix: MatrixConfiguration? = nil,
    notify: [CommandStepNotificationRule]? = nil,
    priority: Int? = nil,
    allowDependencyFailure: Bool? = nil,
    parallelism: Int? = nil,
) -> CommandStep {
    makeCommandStep(
        label: label,
        command: .init(command),
        key: key,
        plugins: plugins,
        agents: agents,
        env: env,
        artifactPaths: artifactPaths,
        branches: branches,
        concurrency: concurrency,
        dependsOn: dependsOn,
        condition: condition,
        softFail: softFail,
        retry: retry,
        timeoutInMinutes: timeoutInMinutes,
        matrix: matrix,
        notify: notify,
        priority: priority,
        allowDependencyFailure: allowDependencyFailure,
        parallelism: parallelism,
    )
}

/// Creates a command step using direct parameters with multiple commands and a typed step key.
public func Step(
    label: String? = nil,
    command: String...,
    key: StepKey,
    plugins: [Plugin]? = nil,
    agents: [String: JSONValue]? = nil,
    env: [String: String]? = nil,
    artifactPaths: [String]? = nil,
    branches: String? = nil,
    concurrency: StepConcurrency? = nil,
    dependsOn: [StepDependency]? = nil,
    condition: String? = nil,
    softFail: SoftFailPolicy? = nil,
    retry: RetryPolicy? = nil,
    timeoutInMinutes: Int? = nil,
    matrix: MatrixConfiguration? = nil,
    notify: [CommandStepNotificationRule]? = nil,
    priority: Int? = nil,
    allowDependencyFailure: Bool? = nil,
    parallelism: Int? = nil,
) -> CommandStep {
    Step(
        label: label,
        command: command,
        key: key.rawValue,
        plugins: plugins,
        agents: agents,
        env: env,
        artifactPaths: artifactPaths,
        branches: branches,
        concurrency: concurrency,
        dependsOn: dependsOn,
        condition: condition,
        softFail: softFail,
        retry: retry,
        timeoutInMinutes: timeoutInMinutes,
        matrix: matrix,
        notify: notify,
        priority: priority,
        allowDependencyFailure: allowDependencyFailure,
        parallelism: parallelism,
    )
}

private func makeCommandStep(
    label: String? = nil,
    command: CommandValue? = nil,
    key: String? = nil,
    plugins: [Plugin]? = nil,
    agents: [String: JSONValue]? = nil,
    env: [String: String]? = nil,
    artifactPaths: [String]? = nil,
    branches: String? = nil,
    concurrency: StepConcurrency? = nil,
    dependsOn: [StepDependency]? = nil,
    condition: String? = nil,
    softFail: SoftFailPolicy? = nil,
    retry: RetryPolicy? = nil,
    timeoutInMinutes: Int? = nil,
    matrix: MatrixConfiguration? = nil,
    notify: [CommandStepNotificationRule]? = nil,
    priority: Int? = nil,
    allowDependencyFailure: Bool? = nil,
    parallelism: Int? = nil,
) -> CommandStep {
    let step = CommandStepModel(
        label: label,
        command: command,
        plugins: plugins,
        agents: agents,
        env: env,
        artifactPaths: artifactPaths.map(ArtifactPaths.init),
        concurrency: concurrency?.limit,
        concurrencyGroup: concurrency?.group,
        concurrencyMethod: concurrency?.method,
        softFail: softFail,
        retry: retry,
        timeoutInMinutes: timeoutInMinutes,
        matrix: matrix,
        notify: notify,
        priority: priority,
        parallelism: parallelism,
    )

    return CommandStep(model: .command(
        step,
        key: key,
        dependsOn: dependencyCondition(from: dependsOn),
        allowDependencyFailure: allowDependencyFailure,
        condition: condition,
        branches: branches,
    ))
}

// swiftlint:disable:next cyclomatic_complexity
func commandStepModel(from attributes: [CommandStepAttribute]) -> CommandStepModel {
    var step = CommandStepModel()
    var collectedCommands: [String] = []

    for attribute in attributes {
        switch attribute {
        case .command(let command):
            collectedCommands.append(contentsOf: command.values)
        case .artifactPath(let path):
            appendArtifactPath(path, to: &step)
        case .plugin(let plugin):
            var plugins = step.plugins ?? []
            plugins.append(plugin)
            step.plugins = plugins
        case .agent(let agent):
            var agents = step.orderedAgents ?? OrderedKeyValuePairs<JSONValue>()
            agents[agent.key] = agent.value
            step.orderedAgents = agents
        case .environmentVariable(let variable):
            var env = step.orderedEnv ?? OrderedKeyValuePairs<String>()
            env[variable.key] = variable.value
            step.orderedEnv = env
        case .matrix(let matrix):
            step.matrix = matrix
        case .notification(let notification):
            var notify = step.notify ?? []
            notify.append(notification)
            step.notify = notify
        }
    }

    switch collectedCommands.count {
    case 0:
        step.command = nil
    case 1:
        step.command = .single(collectedCommands[0])
    default:
        step.command = .multiple(collectedCommands)
    }

    return step
}

private func appendArtifactPath(_ path: String, to step: inout CommandStepModel) {
    guard var artifactPaths = step.artifactPaths else {
        step.artifactPaths = ArtifactPaths(path)
        return
    }

    artifactPaths.append(path)
    step.artifactPaths = artifactPaths
}

public extension CommandStep {
    /// Sets the step label.
    func label(_ value: String) -> CommandStep {
        mapCommand { $0.label = value }
    }

    /// Sets the step key.
    func key(_ value: String) -> CommandStep {
        withKey(value)
    }

    /// Sets the step key.
    func key(_ value: StepKey) -> CommandStep {
        key(value.rawValue)
    }

    /// Sets the Buildkite `if` condition.
    func condition(_ value: String) -> CommandStep {
        withCondition(value)
    }

    /// Sets branch filters for the step.
    func branches(_ value: String) -> CommandStep {
        withBranches(value)
    }

    /// Sets dependencies for the step.
    func dependsOn(_ dependencies: [StepDependency]) -> CommandStep {
        withDependsOn(dependencies)
    }

    /// Sets dependencies for the step.
    func dependsOn(_ dependencies: any StepDependencyConvertible...) -> CommandStep {
        dependsOn(dependencies.map(\.stepDependency))
    }

    /// Sets dependencies for the step.
    func dependsOn(keys: [StepKey]) -> CommandStep {
        dependsOn(keys.map { StepDependency($0) })
    }

    /// Controls whether failed dependencies are allowed.
    func allowDependencyFailure(_ value: Bool = true) -> CommandStep {
        withAllowDependencyFailure(value)
    }

    /// Sets concurrency settings using discrete values.
    func concurrency(limit: Int, group: String, method: ConcurrencyMethod? = nil) -> CommandStep {
        mapCommand {
            $0.concurrency = limit
            $0.concurrencyGroup = group
            $0.concurrencyMethod = method
        }
    }

    /// Sets concurrency settings from `StepConcurrency`.
    func concurrency(_ value: StepConcurrency) -> CommandStep {
        concurrency(limit: value.limit, group: value.group, method: value.method)
    }

    /// Enables or disables soft-fail behavior.
    func softFail(_ enabled: Bool = true) -> CommandStep {
        mapCommand { $0.softFail = .enabled(enabled) }
    }

    /// Sets soft-fail behavior for specific exit statuses.
    func softFail(exitStatuses: [Int]) -> CommandStep {
        mapCommand { $0.softFail = .conditions(exitStatuses.map { SoftFailCondition(exitStatus: $0) }) }
    }

    /// Sets the retry policy.
    func retry(_ policy: RetryPolicy?) -> CommandStep {
        mapCommand { $0.retry = policy }
    }

    /// Enables or disables automatic retry.
    func automaticallyRetry(_ enabled: Bool = true) -> CommandStep {
        mapCommand {
            var retry = $0.retry ?? RetryPolicy()
            retry.automatic = .enabled(enabled)
            $0.retry = retry
        }
    }

    /// Sets an automatic retry limit.
    func automaticallyRetry(limit: Int) -> CommandStep {
        mapCommand {
            var retry = $0.retry ?? RetryPolicy()
            retry.automatic = .limit(limit)
            $0.retry = retry
        }
    }

    /// Sets explicit automatic retry rules.
    func automaticallyRetry(rules: [RetryAutomaticRule]) -> CommandStep {
        mapCommand {
            var retry = $0.retry ?? RetryPolicy()
            retry.automatic = .rules(rules)
            $0.retry = retry
        }
    }

    /// Configures manual retry behavior.
    func manualRetry(allowed: Bool? = nil, permitOnPassed: Bool?, reason: String? = nil) -> CommandStep {
        mapCommand {
            var retry = $0.retry ?? RetryPolicy()
            retry.manual = RetryManual(allowed: allowed, permitOnPassed: permitOnPassed, reason: reason)
            $0.retry = retry
        }
    }

    /// Sets the timeout in minutes.
    func timeoutInMinutes(_ value: Int) -> CommandStep {
        mapCommand { $0.timeoutInMinutes = value }
    }

    /// Sets the step priority.
    func priority(_ value: Int) -> CommandStep {
        mapCommand { $0.priority = value }
    }

    /// Sets the step parallelism.
    func parallelism(_ value: Int) -> CommandStep {
        mapCommand { $0.parallelism = value }
    }
}
