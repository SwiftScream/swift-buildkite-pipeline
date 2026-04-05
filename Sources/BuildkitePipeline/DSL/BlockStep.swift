import Foundation

/// A single attribute used by block/input-step builders.
public enum BlockStepAttribute: Equatable, Sendable {
    /// Adds an input field definition.
    case field(BlockField)
}

/// Creates a text input field.
public func TextField(
    key: String,
    text: String,
    hint: String? = nil,
    required: Bool? = nil,
    defaultValue: String? = nil,
) -> BlockField {
    .text(TextBlockField(
        key: key,
        text: text,
        hint: hint,
        required: required,
        defaultValue: defaultValue,
    ))
}

/// Creates a select input field.
public func SelectField(
    key: String,
    select: String,
    options: [SelectOption],
    hint: String? = nil,
    required: Bool? = nil,
    multiple: Bool? = nil,
    defaultValue: String? = nil,
) -> BlockField {
    .select(SelectBlockField(
        key: key,
        select: select,
        options: options,
        hint: hint,
        required: required,
        multiple: multiple,
        defaultValue: defaultValue,
    ))
}

/// Creates a selectable option for `SelectField`.
public func Option(_ label: String, value: String) -> SelectOption {
    SelectOption(label: label, value: value)
}

/// A block/input step (`block`/`input`).
public struct BlockStep: Equatable, Sendable, PipelineFragmentConvertible, StepModelBackedStep {
    var model: StepModel

    /// Returns this value as a composable fragment.
    public var pipelineFragment: PipelineFragment {
        pipelineFragmentValue
    }
}

/// Creates a block step.
public func Block(_ prompt: String? = nil, @BlockStepBuilder _ content: () -> [BlockStepAttribute] = { [] }) -> BlockStep {
    var step = BlockStepModel(block: prompt)
    applyBlockAttributes(content(), to: &step)
    return BlockStep(model: .block(step))
}

/// Creates an input step.
public func Input(_ prompt: String, @BlockStepBuilder _ content: () -> [BlockStepAttribute] = { [] }) -> BlockStep {
    var step = BlockStepModel(input: prompt)
    applyBlockAttributes(content(), to: &step)
    return BlockStep(model: .block(step))
}

private func applyBlockAttributes(_ attributes: [BlockStepAttribute], to step: inout BlockStepModel) {
    for attribute in attributes {
        switch attribute {
        case .field(let field):
            var fields = step.fields ?? []
            fields.append(field)
            step.fields = fields
        }
    }
}

public extension BlockStep {
    /// Sets the step key.
    func key(_ value: String) -> BlockStep {
        withKey(value)
    }

    /// Sets the step key.
    func key(_ value: StepKey) -> BlockStep {
        key(value.rawValue)
    }

    /// Sets the Buildkite `if` condition.
    func condition(_ value: String) -> BlockStep {
        withCondition(value)
    }

    /// Sets branch filters for the step.
    func branches(_ value: String) -> BlockStep {
        withBranches(value)
    }

    /// Sets dependencies for the step.
    func dependsOn(_ dependencies: [StepDependency]) -> BlockStep {
        withDependsOn(dependencies)
    }

    /// Sets dependencies for the step.
    func dependsOn(_ dependencies: any StepDependencyConvertible...) -> BlockStep {
        dependsOn(dependencies.map(\.stepDependency))
    }

    /// Sets dependencies for the step.
    func dependsOn(keys: [StepKey]) -> BlockStep {
        dependsOn(keys.map { StepDependency($0) })
    }

    /// Controls whether failed dependencies are allowed.
    func allowDependencyFailure(_ value: Bool = true) -> BlockStep {
        withAllowDependencyFailure(value)
    }

    /// Overrides the prompt shown to users.
    func prompt(_ value: String) -> BlockStep {
        mapBlock { $0.prompt = value }
    }
}
