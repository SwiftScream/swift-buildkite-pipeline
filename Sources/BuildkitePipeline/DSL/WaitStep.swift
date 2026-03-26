import Foundation

/// A wait step (`wait`).
public struct WaitStep: Equatable, Sendable, PipelineStepConvertible {
    var model: WaitStepModel

    /// Returns this value as an erased pipeline step.
    public var pipelineStep: PipelineStep {
        PipelineStep(.wait(model))
    }
}

/// Creates a wait step.
public func Wait(
    continueOnFailure: Bool? = nil,
    dependsOn: [StepDependency]? = nil,
    allowDependencyFailure: Bool? = nil,
    condition: String? = nil,
    branches: String? = nil,
) -> WaitStep {
    WaitStep(model: WaitStepModel(
        continueOnFailure: continueOnFailure,
        dependsOn: dependencyCondition(from: dependsOn),
        allowDependencyFailure: allowDependencyFailure,
        condition: condition,
        branches: branches,
    ))
}

public extension WaitStep {
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
