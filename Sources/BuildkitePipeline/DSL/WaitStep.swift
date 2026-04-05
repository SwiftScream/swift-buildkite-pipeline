import Foundation

/// A wait step (`wait`).
public struct WaitStep: Equatable, Sendable, PipelineFragmentConvertible {
    var model: WaitStepModel

    /// Returns this value as a composable fragment.
    public var pipelineFragment: PipelineFragment {
        PipelineFragment(.wait(model))
    }
}

/// Creates a wait step.
public func Wait(
    key: String? = nil,
    continueOnFailure: Bool? = nil,
    dependsOn: [StepDependency]? = nil,
    allowDependencyFailure: Bool? = nil,
    condition: String? = nil,
    branches: String? = nil,
) -> WaitStep {
    WaitStep(model: WaitStepModel(
        key: key,
        continueOnFailure: continueOnFailure,
        dependsOn: dependencyCondition(from: dependsOn),
        allowDependencyFailure: allowDependencyFailure,
        condition: condition,
        branches: branches,
    ))
}

/// Creates a wait step with a typed step key.
public func Wait(
    key: StepKey,
    continueOnFailure: Bool? = nil,
    dependsOn: [StepDependency]? = nil,
    allowDependencyFailure: Bool? = nil,
    condition: String? = nil,
    branches: String? = nil,
) -> WaitStep {
    Wait(
        key: key.rawValue,
        continueOnFailure: continueOnFailure,
        dependsOn: dependsOn,
        allowDependencyFailure: allowDependencyFailure,
        condition: condition,
        branches: branches,
    )
}

public extension WaitStep {
    /// Sets the step key.
    func key(_ value: String) -> WaitStep {
        map { $0.key = value }
    }

    /// Sets the step key.
    func key(_ value: StepKey) -> WaitStep {
        key(value.rawValue)
    }

    /// Sets the Buildkite `if` condition.
    func condition(_ value: String) -> WaitStep {
        map { $0.condition = value }
    }

    /// Sets branch filters for the step.
    func branches(_ value: String) -> WaitStep {
        map { $0.branches = value }
    }

    /// Sets dependencies for the step.
    func dependsOn(_ dependencies: [StepDependency]) -> WaitStep {
        map { $0.dependsOn = dependencyCondition(from: dependencies) }
    }

    /// Sets dependencies for the step.
    func dependsOn(_ dependencies: any StepDependencyConvertible...) -> WaitStep {
        dependsOn(dependencies.map(\.stepDependency))
    }

    /// Sets dependencies for the step.
    func dependsOn(keys: [StepKey]) -> WaitStep {
        dependsOn(keys.map { StepDependency($0) })
    }

    /// Controls whether failed dependencies are allowed.
    func allowDependencyFailure(_ value: Bool = true) -> WaitStep {
        map { $0.allowDependencyFailure = value }
    }

    /// Controls whether downstream steps continue after failures.
    func continueOnFailure(_ value: Bool = true) -> WaitStep {
        map { $0.continueOnFailure = value }
    }

    private func map(_ update: (inout WaitStepModel) -> Void) -> WaitStep {
        var copy = model
        update(&copy)
        return WaitStep(model: copy)
    }
}
