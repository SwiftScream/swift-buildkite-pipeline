import Foundation

/// A trigger step (`trigger`).
public struct TriggerStep: Equatable, Sendable, PipelineFragmentConvertible, StepModelBackedStep {
    var model: StepModel

    /// Returns this value as a composable fragment.
    public var pipelineFragment: PipelineFragment {
        pipelineFragmentValue
    }
}

/// Creates a trigger step.
public func Trigger(_ pipeline: String) -> TriggerStep {
    TriggerStep(model: .trigger(TriggerStepModel(trigger: pipeline)))
}

public extension TriggerStep {
    /// Sets the step label.
    func label(_ value: String) -> TriggerStep {
        mapTrigger { $0.label = value }
    }

    /// Sets the step key.
    func key(_ value: String) -> TriggerStep {
        withKey(value)
    }

    /// Sets the step key.
    func key(_ value: StepKey) -> TriggerStep {
        key(value.rawValue)
    }

    /// Sets the Buildkite `if` condition.
    func condition(_ value: String) -> TriggerStep {
        withCondition(value)
    }

    /// Sets branch filters for the step.
    func branches(_ value: String) -> TriggerStep {
        withBranches(value)
    }

    /// Sets dependencies for the step.
    func dependsOn(_ dependencies: [StepDependency]) -> TriggerStep {
        withDependsOn(dependencies)
    }

    /// Sets dependencies for the step.
    func dependsOn(_ dependencies: any StepDependencyConvertible...) -> TriggerStep {
        dependsOn(dependencies.map(\.stepDependency))
    }

    /// Sets dependencies for the step.
    func dependsOn(keys: [StepKey]) -> TriggerStep {
        dependsOn(keys.map { StepDependency($0) })
    }

    /// Controls whether failed dependencies are allowed.
    func allowDependencyFailure(_ value: Bool = true) -> TriggerStep {
        withAllowDependencyFailure(value)
    }

    /// Controls whether the trigger waits for completion.
    func asynchronous(_ value: Bool = true) -> TriggerStep {
        mapTrigger { $0.async = value }
    }

    /// Enables or disables soft-fail behavior.
    func softFail(_ enabled: Bool = true) -> TriggerStep {
        mapTrigger { $0.softFail = .enabled(enabled) }
    }

    /// Sets soft-fail behavior for specific exit statuses.
    func softFail(exitStatuses: [Int]) -> TriggerStep {
        mapTrigger { $0.softFail = .conditions(exitStatuses.map { SoftFailCondition(exitStatus: $0) }) }
    }

    /// Sets the retry policy.
    func retry(_ policy: RetryPolicy?) -> TriggerStep {
        mapTrigger { $0.retry = policy }
    }

    /// Enables or disables automatic retry.
    func automaticallyRetry(_ enabled: Bool = true) -> TriggerStep {
        mapTrigger {
            var retry = $0.retry ?? RetryPolicy()
            retry.automatic = .enabled(enabled)
            $0.retry = retry
        }
    }

    /// Sets an automatic retry limit.
    func automaticallyRetry(limit: Int) -> TriggerStep {
        mapTrigger {
            var retry = $0.retry ?? RetryPolicy()
            retry.automatic = .limit(limit)
            $0.retry = retry
        }
    }

    /// Sets explicit automatic retry rules.
    func automaticallyRetry(rules: [RetryAutomaticRule]) -> TriggerStep {
        mapTrigger {
            var retry = $0.retry ?? RetryPolicy()
            retry.automatic = .rules(rules)
            $0.retry = retry
        }
    }

    /// Configures manual retry behavior.
    func manualRetry(allowed: Bool? = nil, permitOnPassed: Bool?, reason: String? = nil) -> TriggerStep {
        mapTrigger {
            var retry = $0.retry ?? RetryPolicy()
            retry.manual = RetryManual(allowed: allowed, permitOnPassed: permitOnPassed, reason: reason)
            $0.retry = retry
        }
    }

    /// Sets the nested trigger build payload.
    func build(_ build: TriggerBuild) -> TriggerStep {
        mapTrigger { $0.build = build }
    }

    /// Builds and sets the nested trigger build payload.
    func build(
        branch: String? = nil,
        commit: String? = nil,
        message: String? = nil,
        env: [String: String]? = nil,
        metadata: [String: String]? = nil,
    ) -> TriggerStep {
        build(TriggerBuild(branch: branch, commit: commit, message: message, env: env, metadata: metadata))
    }
}
