import Foundation

/// A wait step (`wait`).
public struct WaitStep: Equatable, Sendable, PipelineFragmentConvertible, StepModelBackedStep {
    var model: StepModel

    /// Returns this value as a composable fragment.
    public var pipelineFragment: PipelineFragment {
        pipelineFragmentValue
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
    WaitStep(model: .wait(
        WaitStepModel(continueOnFailure: continueOnFailure),
        key: key,
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
        withKey(value)
    }

    /// Sets the step key.
    func key(_ value: StepKey) -> WaitStep {
        key(value.rawValue)
    }

    /// Sets the Buildkite `if` condition.
    func condition(_ value: String) -> WaitStep {
        withCondition(value)
    }

    /// Sets branch filters for the step.
    func branches(_ value: String) -> WaitStep {
        withBranches(value)
    }

    /// Sets dependencies for the step.
    func dependsOn(_ dependencies: [StepDependency]) -> WaitStep {
        withDependsOn(dependencies)
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
        withAllowDependencyFailure(value)
    }

    /// Controls whether downstream steps continue after failures.
    func continueOnFailure(_ value: Bool = true) -> WaitStep {
        mapWait { $0.continueOnFailure = value }
    }
}
