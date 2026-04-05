import Foundation

/// A composable fragment of pipeline steps.
public struct PipelineFragment: Equatable, Sendable {
    private var models: [StepModel]

    init(_ step: StepModel) {
        models = [step]
    }

    init(_ steps: [StepModel]) {
        models = steps
    }

    static var empty: PipelineFragment {
        PipelineFragment([])
    }

    static func concatenating(_ fragments: [PipelineFragment]) -> PipelineFragment {
        fragments.reduce(.empty, +)
    }

    func materializedModels() -> [StepModel] {
        models
    }

    func mapStepModels(_ transform: (StepModel) -> StepModel) -> PipelineFragment {
        PipelineFragment(models.map(transform))
    }

    static func + (lhs: PipelineFragment, rhs: PipelineFragment) -> PipelineFragment {
        PipelineFragment(lhs.models + rhs.models)
    }
}
