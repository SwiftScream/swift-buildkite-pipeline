import Foundation

/// A group step (`group`).
public struct GroupStep: Equatable, Sendable, PipelineFragmentConvertible, StepModelBackedStep {
    var model: StepModel

    /// Returns this value as a composable fragment.
    public var pipelineFragment: PipelineFragment {
        pipelineFragmentValue
    }
}

/// Creates a group step with nested child steps.
public func Group(
    _ label: String,
    key: String? = nil,
    condition: String? = nil,
    branches: String? = nil,
    dependsOn: [StepDependency]? = nil,
    allowDependencyFailure: Bool? = nil,
    notify: [NotificationRule]? = nil,
    @PipelineFragmentBuilder _ content: () -> PipelineFragment,
) -> GroupStep {
    let steps = content().materializedModels()
    let group = GroupStepModel(
        group: label,
        steps: steps,
        notify: notify,
    )

    return GroupStep(model: .group(
        group,
        key: key,
        dependsOn: dependencyCondition(from: dependsOn),
        allowDependencyFailure: allowDependencyFailure,
        condition: condition,
        branches: branches,
    ))
}

/// Creates a group step with nested child steps and a typed step key.
public func Group(
    _ label: String,
    key: StepKey,
    condition: String? = nil,
    branches: String? = nil,
    dependsOn: [StepDependency]? = nil,
    allowDependencyFailure: Bool? = nil,
    notify: [NotificationRule]? = nil,
    @PipelineFragmentBuilder _ content: () -> PipelineFragment,
) -> GroupStep {
    Group(
        label,
        key: key.rawValue,
        condition: condition,
        branches: branches,
        dependsOn: dependsOn,
        allowDependencyFailure: allowDependencyFailure,
        notify: notify,
        content,
    )
}

public extension GroupStep {
    /// Sets the step key.
    func key(_ value: String) -> GroupStep {
        withKey(value)
    }

    /// Sets the step key.
    func key(_ value: StepKey) -> GroupStep {
        key(value.rawValue)
    }

    /// Sets the Buildkite `if` condition.
    func condition(_ value: String) -> GroupStep {
        withCondition(value)
    }

    /// Sets branch filters for the step.
    func branches(_ value: String) -> GroupStep {
        withBranches(value)
    }

    /// Sets dependencies for the step.
    func dependsOn(_ dependencies: [StepDependency]) -> GroupStep {
        withDependsOn(dependencies)
    }

    /// Sets dependencies for the step.
    func dependsOn(_ dependencies: any StepDependencyConvertible...) -> GroupStep {
        dependsOn(dependencies.map(\.stepDependency))
    }

    /// Sets dependencies for the step.
    func dependsOn(keys: [StepKey]) -> GroupStep {
        dependsOn(keys.map { StepDependency($0) })
    }

    /// Controls whether failed dependencies are allowed.
    func allowDependencyFailure(_ value: Bool = true) -> GroupStep {
        withAllowDependencyFailure(value)
    }

    /// Sets notification rules for the step.
    func notify(@NotifyBuilder _ content: () -> [NotificationRule]) -> GroupStep {
        mapGroup { $0.notify = content() }
    }
}
