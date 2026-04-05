import Foundation

/// Reusable defaults that can be applied to command steps in a `Steps(template:)` block.
///
/// Template attributes and modifiers are applied as if they were placed at the top of
/// each command step. Step-local attributes and modifiers therefore take precedence.
public struct StepTemplate: Equatable, Sendable {
    var attributes: [CommandStepAttribute]
    var condition: String?
    var branches: String?
    var softFail: SoftFailPolicy?
    var retry: RetryPolicy?
    var timeoutInMinutes: Int?
    var priority: Int?
    var parallelism: Int?
    var concurrency: StepConcurrency?
    var allowDependencyFailure: Bool?

    /// Creates a command-step template.
    public init(
        condition: String? = nil,
        branches: String? = nil,
        softFail: SoftFailPolicy? = nil,
        retry: RetryPolicy? = nil,
        timeoutInMinutes: Int? = nil,
        priority: Int? = nil,
        parallelism: Int? = nil,
        concurrency: StepConcurrency? = nil,
        allowDependencyFailure: Bool? = nil,
        @CommandStepBuilder _ content: () -> [CommandStepAttribute] = { [] },
    ) {
        attributes = content()
        self.condition = condition
        self.branches = branches
        self.softFail = softFail
        self.retry = retry
        self.timeoutInMinutes = timeoutInMinutes
        self.priority = priority
        self.parallelism = parallelism
        self.concurrency = concurrency
        self.allowDependencyFailure = allowDependencyFailure
    }
}

/// Creates a reusable collection of steps with a shared command-step template.
///
/// The template is applied first, then each step's own values are applied. This means
/// per-step values override template values for conflicts (for example duplicate env keys).
public func Steps(
    template: StepTemplate = StepTemplate(),
    @PipelineFragmentBuilder _ content: () -> PipelineFragment,
) -> PipelineFragment {
    content().mapStepModels(template.applying(to:))
}

public extension StepTemplate {
    /// Sets the Buildkite `if` condition.
    func condition(_ value: String) -> StepTemplate {
        map { $0.condition = value }
    }

    /// Sets branch filters.
    func branches(_ value: String) -> StepTemplate {
        map { $0.branches = value }
    }

    /// Enables or disables soft-fail behavior.
    func softFail(_ enabled: Bool = true) -> StepTemplate {
        map { $0.softFail = .enabled(enabled) }
    }

    /// Sets soft-fail behavior for specific exit statuses.
    func softFail(exitStatuses: [Int]) -> StepTemplate {
        map { $0.softFail = .conditions(exitStatuses.map { SoftFailCondition(exitStatus: $0) }) }
    }

    /// Sets the retry policy.
    func retry(_ policy: RetryPolicy?) -> StepTemplate {
        map { $0.retry = policy }
    }

    /// Enables or disables automatic retry.
    func automaticallyRetry(_ enabled: Bool = true) -> StepTemplate {
        map {
            var retry = $0.retry ?? RetryPolicy()
            retry.automatic = .enabled(enabled)
            $0.retry = retry
        }
    }

    /// Sets an automatic retry limit.
    func automaticallyRetry(limit: Int) -> StepTemplate {
        map {
            var retry = $0.retry ?? RetryPolicy()
            retry.automatic = .limit(limit)
            $0.retry = retry
        }
    }

    /// Sets explicit automatic retry rules.
    func automaticallyRetry(rules: [RetryAutomaticRule]) -> StepTemplate {
        map {
            var retry = $0.retry ?? RetryPolicy()
            retry.automatic = .rules(rules)
            $0.retry = retry
        }
    }

    /// Configures manual retry behavior.
    func manualRetry(allowed: Bool? = nil, permitOnPassed: Bool?, reason: String? = nil) -> StepTemplate {
        map {
            var retry = $0.retry ?? RetryPolicy()
            retry.manual = RetryManual(allowed: allowed, permitOnPassed: permitOnPassed, reason: reason)
            $0.retry = retry
        }
    }

    /// Sets the timeout in minutes.
    func timeoutInMinutes(_ value: Int) -> StepTemplate {
        map { $0.timeoutInMinutes = value }
    }

    /// Sets the step priority.
    func priority(_ value: Int) -> StepTemplate {
        map { $0.priority = value }
    }

    /// Sets the step parallelism.
    func parallelism(_ value: Int) -> StepTemplate {
        map { $0.parallelism = value }
    }

    /// Sets concurrency settings using discrete values.
    func concurrency(limit: Int, group: String, method: ConcurrencyMethod? = nil) -> StepTemplate {
        map { $0.concurrency = StepConcurrency(limit: limit, group: group, method: method) }
    }

    /// Sets concurrency settings from `StepConcurrency`.
    func concurrency(_ value: StepConcurrency) -> StepTemplate {
        map { $0.concurrency = value }
    }

    /// Controls whether failed dependencies are allowed.
    func allowDependencyFailure(_ value: Bool = true) -> StepTemplate {
        map { $0.allowDependencyFailure = value }
    }
}

private extension StepTemplate {
    func applying(to model: StepModel) -> StepModel {
        switch model.payload {
        case .command(var command):
            var step = model
            apply(to: &step, command: &command)
            step.payload = .command(command)
            return step
        case .group(var group):
            group.steps = group.steps.map(applying(to:))
            var step = model
            step.payload = .group(group)
            return step
        case .wait, .block, .trigger:
            return model
        }
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func apply(to step: inout StepModel, command: inout CommandStepModel) {
        let defaultsFromAttributes = commandStepModel(from: attributes)

        if command.command == nil {
            command.command = defaultsFromAttributes.command
        }

        if let templatePaths = defaultsFromAttributes.artifactPaths?.paths, !templatePaths.isEmpty {
            let existing = command.artifactPaths?.paths ?? []
            command.artifactPaths = ArtifactPaths(templatePaths + existing)
        }

        if let templatePlugins = defaultsFromAttributes.plugins, !templatePlugins.isEmpty {
            command.plugins = templatePlugins + (command.plugins ?? [])
        }

        if let templateAgents = defaultsFromAttributes.orderedAgents, !templateAgents.isEmpty {
            var mergedAgents = templateAgents
            if let existingAgents = command.orderedAgents {
                for entry in existingAgents.allEntries {
                    mergedAgents[entry.key] = entry.value
                }
            }
            command.orderedAgents = mergedAgents
        }

        if let templateEnv = defaultsFromAttributes.orderedEnv, !templateEnv.isEmpty {
            var mergedEnv = templateEnv
            if let existingEnv = command.orderedEnv {
                for entry in existingEnv.allEntries {
                    mergedEnv[entry.key] = entry.value
                }
            }
            command.orderedEnv = mergedEnv
        }

        if command.matrix == nil {
            command.matrix = defaultsFromAttributes.matrix
        }

        if let templateNotify = defaultsFromAttributes.notify, !templateNotify.isEmpty {
            command.notify = templateNotify + (command.notify ?? [])
        }

        if step.condition == nil {
            step.condition = condition
        }

        if step.branches == nil {
            step.branches = branches
        }

        if command.softFail == nil {
            command.softFail = softFail
        }

        if command.retry == nil {
            command.retry = retry
        }

        if command.timeoutInMinutes == nil {
            command.timeoutInMinutes = timeoutInMinutes
        }

        if command.priority == nil {
            command.priority = priority
        }

        if command.parallelism == nil {
            command.parallelism = parallelism
        }

        if step.allowDependencyFailure == nil {
            step.allowDependencyFailure = allowDependencyFailure
        }

        if command.concurrency == nil, command.concurrencyGroup == nil, let concurrency {
            command.concurrency = concurrency.limit
            command.concurrencyGroup = concurrency.group
            if command.concurrencyMethod == nil {
                command.concurrencyMethod = concurrency.method
            }
        }
    }

    func map(_ update: (inout StepTemplate) -> Void) -> StepTemplate {
        var copy = self
        update(&copy)
        return copy
    }
}
