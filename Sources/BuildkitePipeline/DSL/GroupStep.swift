import Foundation

/// A group step (`group`).
public struct GroupStep: Equatable, Sendable, PipelineStepConvertible {
    var model: GroupStepModel

    /// Returns this value as an erased pipeline step.
    public var pipelineStep: PipelineStep {
        PipelineStep(.group(model))
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
    @PipelineStepsBuilder _ content: () -> [PipelineStep],
) -> GroupStep {
    let steps = content().map(\.model)
    let group = GroupStepModel(
        group: label,
        key: key,
        condition: condition,
        branches: branches,
        dependsOn: dependencyCondition(from: dependsOn),
        allowDependencyFailure: allowDependencyFailure,
        steps: steps,
        notify: notify,
    )

    return GroupStep(model: group)
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
    @PipelineStepsBuilder _ content: () -> [PipelineStep],
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
        map { $0.key = value }
    }

    /// Sets the step key.
    func key(_ value: StepKey) -> GroupStep {
        key(value.rawValue)
    }

    /// Sets the Buildkite `if` condition.
    func condition(_ value: String) -> GroupStep {
        map { $0.condition = value }
    }

    /// Sets branch filters for the step.
    func branches(_ value: String) -> GroupStep {
        map { $0.branches = value }
    }

    /// Sets dependencies for the step.
    func dependsOn(_ dependencies: [StepDependency]) -> GroupStep {
        map { $0.dependsOn = dependencyCondition(from: dependencies) }
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
        map { $0.allowDependencyFailure = value }
    }

    /// Sets notification rules for the step.
    func notify(@NotifyBuilder _ content: () -> [NotificationRule]) -> GroupStep {
        map { $0.notify = content() }
    }

    private func map(_ update: (inout GroupStepModel) -> Void) -> GroupStep {
        var copy = model
        update(&copy)
        return GroupStep(model: copy)
    }
}
