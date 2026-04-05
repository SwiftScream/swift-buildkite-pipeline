import Foundation

protocol StepModelBackedStep: PipelineFragmentConvertible {
    var model: StepModel { get }
    init(model: StepModel)
}

extension StepModelBackedStep {
    var pipelineFragmentValue: PipelineFragment {
        PipelineFragment(model)
    }

    func map(_ update: (inout StepModel) -> Void) -> Self {
        var copy = model
        update(&copy)
        return Self(model: copy)
    }

    func mapCommand(_ update: (inout CommandStepModel) -> Void) -> Self {
        map { $0.updateCommand(update) }
    }

    func mapWait(_ update: (inout WaitStepModel) -> Void) -> Self {
        map { $0.updateWait(update) }
    }

    func mapBlock(_ update: (inout BlockStepModel) -> Void) -> Self {
        map { $0.updateBlock(update) }
    }

    func mapTrigger(_ update: (inout TriggerStepModel) -> Void) -> Self {
        map { $0.updateTrigger(update) }
    }

    func mapGroup(_ update: (inout GroupStepModel) -> Void) -> Self {
        map { $0.updateGroup(update) }
    }

    func withKey(_ value: String) -> Self {
        map { $0.key = value }
    }

    func withCondition(_ value: String) -> Self {
        map { $0.condition = value }
    }

    func withBranches(_ value: String) -> Self {
        map { $0.branches = value }
    }

    func withDependsOn(_ dependencies: [StepDependency]) -> Self {
        map { $0.dependsOn = dependencyCondition(from: dependencies) }
    }

    func withAllowDependencyFailure(_ value: Bool) -> Self {
        map { $0.allowDependencyFailure = value }
    }
}
