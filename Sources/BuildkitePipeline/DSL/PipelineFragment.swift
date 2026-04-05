import Foundation

/// A composable fragment of pipeline steps and dependency edges.
///
/// Fragments can be chained with `.then { ... }` to create explicit dependency
/// wiring while keeping step definitions modular.
public struct PipelineFragment: Equatable, Sendable {
    private let nodes: [StepModel]
    private var edges: [Int: [Int]]
    private var outputOverride: [Int]?

    private init(nodes: [StepModel], edges: [Int: [Int]] = [:], outputOverride: [Int]? = nil) {
        self.nodes = nodes
        self.edges = edges
        self.outputOverride = outputOverride
    }

    init(_ step: StepModel) {
        nodes = [step]
        edges = [:]
        outputOverride = nil
    }

    init(_ steps: [StepModel]) {
        nodes = steps
        edges = [:]
        outputOverride = nil
    }

    static var empty: PipelineFragment {
        PipelineFragment(nodes: [])
    }

    static func concatenating(_ fragments: [PipelineFragment]) -> PipelineFragment {
        fragments.reduce(.empty, +)
    }

    /// Materializes the fragment into concrete step models with encoded dependencies.
    func materializedModels() -> [StepModel] {
        guard !nodes.isEmpty else {
            return []
        }

        var materializedModels = nodes
        var usedKeys = Set(materializedModels.compactMap(\.stepKey))

        var sourceNodeIDs: [Int] = []
        for targetNodeID in nodes.indices {
            if let sources = edges[targetNodeID] {
                sourceNodeIDs.append(contentsOf: sources)
            }
        }
        sourceNodeIDs = orderedUnique(sourceNodeIDs)
        for sourceNodeID in sourceNodeIDs {
            if materializedModels[sourceNodeID].stepKey == nil {
                let key = nextAutoDependencyKey(
                    preferredBase: preferredAutoDependencyKeyBase(
                        for: sourceNodeID,
                        models: materializedModels,
                    ),
                    usedKeys: &usedKeys,
                )
                materializedModels[sourceNodeID] = materializedModels[sourceNodeID].settingStepKey(key)
            }
        }

        for targetNodeID in materializedModels.indices {
            guard let sourceIDs = edges[targetNodeID], !sourceIDs.isEmpty else {
                continue
            }

            var combined = dependencies(from: materializedModels[targetNodeID].dependencyCondition)
            for sourceID in sourceIDs {
                guard let sourceKey = materializedModels[sourceID].stepKey else {
                    continue
                }

                let dependency = StepDependency(StepKey(sourceKey))
                if !combined.contains(where: { $0.key == dependency.key }) {
                    combined.append(dependency)
                }
            }

            materializedModels[targetNodeID] = materializedModels[targetNodeID].settingDependencyCondition(
                dependencyCondition(from: combined),
            )
        }

        return materializedModels
    }

    /// Chains another fragment to run after this fragment's current outputs.
    ///
    /// After wiring the dependency edge(s), the appended fragment's outputs become
    /// the current outputs for any subsequent `.then` calls.
    public func then(_ next: PipelineFragment) -> PipelineFragment {
        guard !nodes.isEmpty else {
            return next
        }

        guard !next.nodes.isEmpty else {
            return self
        }

        let upstreamOutputs = resolvedOutputNodeIDs()
        let downstreamEntries = next.resolvedEntryNodeIDs()

        let offset = nodes.count
        let remappedEntries = downstreamEntries.map { $0 + offset }
        let remappedOutputs = next.resolvedOutputNodeIDs().map { $0 + offset }

        var combined = self + next
        for entryID in remappedEntries {
            for outputID in upstreamOutputs {
                combined.appendEdge(from: outputID, to: entryID)
            }
        }

        combined.outputOverride = remappedOutputs
        return combined
    }

    /// Chains another fragment produced by a result builder.
    public func then(@PipelineFragmentBuilder _ next: () -> PipelineFragment) -> PipelineFragment {
        then(next())
    }

    /// Overrides this fragment's current outputs to its entry steps.
    ///
    /// This is useful when a nested chain should expose its first step(s)
    /// as dependency targets for the next downstream `.then`.
    public func setOutput() -> PipelineFragment {
        var copy = self
        copy.outputOverride = resolvedEntryNodeIDs()
        return copy
    }

    static func + (lhs: PipelineFragment, rhs: PipelineFragment) -> PipelineFragment {
        guard !lhs.nodes.isEmpty else {
            return rhs
        }

        guard !rhs.nodes.isEmpty else {
            return lhs
        }

        let offset = lhs.nodes.count
        var mergedEdges = lhs.edges

        for (target, sources) in rhs.edges {
            let remappedTarget = target + offset
            let remappedSources = sources.map { $0 + offset }
            mergedEdges[remappedTarget] = remappedSources
        }

        let mergedOutputOverride: [Int]? = switch (lhs.outputOverride, rhs.outputOverride) {
        case (.none, .none):
            nil
        case (.some(let lhsOverride), .none):
            lhsOverride
        case (.none, .some(let rhsOverride)):
            rhsOverride.map { $0 + offset }
        case (.some(let lhsOverride), .some(let rhsOverride)):
            orderedUnique(lhsOverride + rhsOverride.map { $0 + offset })
        }

        return PipelineFragment(
            nodes: lhs.nodes + rhs.nodes,
            edges: mergedEdges,
            outputOverride: mergedOutputOverride,
        )
    }
}

/// Creates a composable pipeline fragment from a result-builder closure.
public func Fragment(@PipelineFragmentBuilder _ content: () -> PipelineFragment) -> PipelineFragment {
    content()
}

public extension PipelineFragmentConvertible {
    /// Converts this step value into a composable fragment.
    var fragment: PipelineFragment {
        pipelineFragment
    }

    /// Chains this step to run before the next fragment.
    func then(_ next: PipelineFragment) -> PipelineFragment {
        fragment.then(next)
    }

    /// Chains this step to run before the next builder-produced fragment.
    func then(@PipelineFragmentBuilder _ next: () -> PipelineFragment) -> PipelineFragment {
        fragment.then(next)
    }

    /// Marks this step as the explicit output of its fragment.
    func setOutput() -> PipelineFragment {
        fragment.setOutput()
    }
}

extension PipelineFragment {
    func mapStepModels(_ transform: (StepModel) -> StepModel) -> PipelineFragment {
        PipelineFragment(
            nodes: nodes.map(transform),
            edges: edges,
            outputOverride: outputOverride,
        )
    }
}

private extension PipelineFragment {
    func preferredAutoDependencyKeyBase(for sourceNodeID: Int, models: [StepModel]) -> String? {
        if let directBase = models[sourceNodeID].autoDependencyKeyBase {
            return directBase
        }

        guard case .block = models[sourceNodeID] else {
            return nil
        }

        let downstreamTargetIDs = orderedUnique(
            edges.compactMap { targetNodeID, sources in
                sources.contains(sourceNodeID) ? targetNodeID : nil
            }
            .sorted(),
        )

        guard downstreamTargetIDs.count == 1, let targetNodeID = downstreamTargetIDs.first else {
            return nil
        }

        let targetModel = models[targetNodeID]
        let targetBase = targetModel.stepKey ?? targetModel.autoDependencyKeyBase
        return targetBase.map { "block_\($0)" }
    }

    func resolvedEntryNodeIDs() -> [Int] {
        let nodesWithIncomingEdges = Set(edges.keys)
        return nodes.indices.filter { !nodesWithIncomingEdges.contains($0) }
    }

    func resolvedOutputNodeIDs() -> [Int] {
        if let outputOverride {
            return outputOverride.filter { nodes.indices.contains($0) }
        }

        let nodesWithOutgoingEdges = Set(edges.values.flatMap { $0 })
        return nodes.indices.filter { !nodesWithOutgoingEdges.contains($0) }
    }

    mutating func appendEdge(from sourceNodeID: Int, to targetNodeID: Int) {
        var sources = edges[targetNodeID] ?? []
        if !sources.contains(sourceNodeID) {
            sources.append(sourceNodeID)
        }
        edges[targetNodeID] = sources
    }
}

private extension StepModel {
    var stepKey: String? {
        switch self {
        case .command(let model):
            model.key
        case .block(let model):
            model.key
        case .group(let model):
            model.key
        case .trigger(let model):
            model.key
        case .wait(let model):
            model.key
        }
    }

    var dependencyCondition: DependencyCondition? {
        switch self {
        case .command(let model):
            model.dependsOn
        case .wait(let model):
            model.dependsOn
        case .block(let model):
            model.dependsOn
        case .trigger(let model):
            model.dependsOn
        case .group(let model):
            model.dependsOn
        }
    }

    var autoDependencyKeyBase: String? {
        switch self {
        case .command(let model):
            sanitizedDependencyKeyBase(from: model.label)
        case .wait:
            nil
        case .block(let model):
            sanitizedDependencyKeyBase(from: model.input ?? model.block ?? model.prompt)
        case .trigger(let model):
            sanitizedDependencyKeyBase(from: model.label ?? model.trigger)
        case .group(let model):
            sanitizedDependencyKeyBase(from: model.group)
        }
    }

    func settingStepKey(_ value: String) -> StepModel {
        switch self {
        case .command(var model):
            model.key = value
            return .command(model)
        case .block(var model):
            model.key = value
            return .block(model)
        case .group(var model):
            model.key = value
            return .group(model)
        case .trigger(var model):
            model.key = value
            return .trigger(model)
        case .wait(var model):
            model.key = value
            return .wait(model)
        }
    }

    func settingDependencyCondition(_ value: DependencyCondition?) -> StepModel {
        switch self {
        case .command(var model):
            model.dependsOn = value
            return .command(model)
        case .wait(var model):
            model.dependsOn = value
            return .wait(model)
        case .block(var model):
            model.dependsOn = value
            return .block(model)
        case .trigger(var model):
            model.dependsOn = value
            return .trigger(model)
        case .group(var model):
            model.dependsOn = value
            return .group(model)
        }
    }
}

private func nextAutoDependencyKey(preferredBase: String?, usedKeys: inout Set<String>) -> String {
    let preferredBase = preferredBase ?? "_auto"

    if !usedKeys.contains(preferredBase) {
        usedKeys.insert(preferredBase)
        return preferredBase
    }

    var candidate = 2
    while true {
        let key = "\(preferredBase)_\(candidate)"
        if !usedKeys.contains(key) {
            usedKeys.insert(key)
            return key
        }

        candidate += 1
    }
}

private func sanitizedDependencyKeyBase(from name: String?) -> String? {
    guard let rawName = name?.trimmingCharacters(in: .whitespacesAndNewlines), !rawName.isEmpty else {
        return nil
    }

    // Strip Buildkite-style icon aliases such as ":package:" from labels.
    let withoutAliases = rawName.replacingOccurrences(
        of: #":[A-Za-z0-9_+\-]+:"#,
        with: " ",
        options: .regularExpression,
    )

    let lowered = withoutAliases.lowercased()
    let withUnderscores = lowered.replacingOccurrences(of: #"\s+"#, with: "_", options: .regularExpression)
    let stripped = withUnderscores.replacingOccurrences(
        of: #"[^a-z0-9_-]"#,
        with: "",
        options: .regularExpression,
    )

    let normalizedDelimiters = stripped
        .replacingOccurrences(of: #"_+"#, with: "_", options: .regularExpression)
        .replacingOccurrences(of: #"-+"#, with: "-", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: "_-"))

    guard !normalizedDelimiters.isEmpty else {
        return nil
    }

    return normalizedDelimiters
}

private func orderedUnique(_ values: [Int]) -> [Int] {
    var seen = Set<Int>()
    var output: [Int] = []
    output.reserveCapacity(values.count)

    for value in values where seen.insert(value).inserted {
        output.append(value)
    }

    return output
}
