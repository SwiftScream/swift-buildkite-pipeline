import Foundation

/// Intermediate content container used by `PipelineBuilder`.
public struct PipelineContent {
    var steps: [PipelineStep]
    var globalEnv: [GlobalEnvironmentVariable]
    var defaultAgents: [DefaultAgentEntry]
    var metadata: [MetadataEntry]
    var notify: [NotificationRule]

    init(
        steps: [PipelineStep] = [],
        globalEnv: [GlobalEnvironmentVariable] = [],
        defaultAgents: [DefaultAgentEntry] = [],
        metadata: [MetadataEntry] = [],
        notify: [NotificationRule] = [],
    ) {
        self.steps = steps
        self.globalEnv = globalEnv
        self.defaultAgents = defaultAgents
        self.metadata = metadata
        self.notify = notify
    }

    static func + (lhs: PipelineContent, rhs: PipelineContent) -> PipelineContent {
        PipelineContent(
            steps: lhs.steps + rhs.steps,
            globalEnv: lhs.globalEnv + rhs.globalEnv,
            defaultAgents: lhs.defaultAgents + rhs.defaultAgents,
            metadata: lhs.metadata + rhs.metadata,
            notify: lhs.notify + rhs.notify,
        )
    }
}

/// Result builder used by `Pipeline { ... }`.
@resultBuilder
public enum PipelineBuilder {
    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildBlock(_ components: PipelineContent...) -> PipelineContent {
        components.reduce(PipelineContent(), +)
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: some PipelineStepConvertible) -> PipelineContent {
        PipelineContent(steps: [expression.pipelineStep])
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: [PipelineStep]) -> PipelineContent {
        PipelineContent(steps: expression)
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: GlobalEnvironmentVariable) -> PipelineContent {
        PipelineContent(globalEnv: [expression])
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: [GlobalEnvironmentVariable]) -> PipelineContent {
        PipelineContent(globalEnv: expression)
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: DefaultAgentEntry) -> PipelineContent {
        PipelineContent(defaultAgents: [expression])
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: [DefaultAgentEntry]) -> PipelineContent {
        PipelineContent(defaultAgents: expression)
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: MetadataEntry) -> PipelineContent {
        PipelineContent(metadata: [expression])
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: [MetadataEntry]) -> PipelineContent {
        PipelineContent(metadata: expression)
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: NotificationRule) -> PipelineContent {
        PipelineContent(notify: [expression])
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildOptional(_ component: PipelineContent?) -> PipelineContent {
        component ?? PipelineContent()
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildEither(first component: PipelineContent) -> PipelineContent {
        component
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildEither(second component: PipelineContent) -> PipelineContent {
        component
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildArray(_ components: [PipelineContent]) -> PipelineContent {
        components.reduce(PipelineContent(), +)
    }
}

/// Result builder used by APIs that accept nested pipeline steps.
@resultBuilder
public enum PipelineStepsBuilder {
    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildBlock(_ components: [PipelineStep]...) -> [PipelineStep] {
        components.flatMap { $0 }
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: some PipelineStepConvertible) -> [PipelineStep] {
        [expression.pipelineStep]
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: [PipelineStep]) -> [PipelineStep] {
        expression
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildOptional(_ component: [PipelineStep]?) -> [PipelineStep] {
        component ?? []
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildEither(first component: [PipelineStep]) -> [PipelineStep] {
        component
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildEither(second component: [PipelineStep]) -> [PipelineStep] {
        component
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildArray(_ components: [[PipelineStep]]) -> [PipelineStep] {
        components.flatMap { $0 }
    }
}

/// Result builder used by command-step content APIs.
@resultBuilder
public enum CommandStepBuilder {
    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildBlock(_ components: [CommandStepAttribute]...) -> [CommandStepAttribute] {
        components.flatMap { $0 }
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: CommandStepAttribute) -> [CommandStepAttribute] {
        [expression]
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: Plugin) -> [CommandStepAttribute] {
        [.plugin(expression)]
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: AgentEntry) -> [CommandStepAttribute] {
        [.agent(expression)]
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: EnvironmentVariable) -> [CommandStepAttribute] {
        [.environmentVariable(expression)]
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: [EnvironmentVariable]) -> [CommandStepAttribute] {
        expression.map(CommandStepAttribute.environmentVariable)
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: CommandStepNotificationRule) -> [CommandStepAttribute] {
        [.notification(expression)]
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: [CommandStepAttribute]) -> [CommandStepAttribute] {
        expression
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildOptional(_ component: [CommandStepAttribute]?) -> [CommandStepAttribute] {
        component ?? []
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildEither(first component: [CommandStepAttribute]) -> [CommandStepAttribute] {
        component
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildEither(second component: [CommandStepAttribute]) -> [CommandStepAttribute] {
        component
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildArray(_ components: [[CommandStepAttribute]]) -> [CommandStepAttribute] {
        components.flatMap { $0 }
    }
}

/// Result builder used by block/input-step content APIs.
@resultBuilder
public enum BlockStepBuilder {
    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildBlock(_ components: [BlockStepAttribute]...) -> [BlockStepAttribute] {
        components.flatMap { $0 }
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: BlockStepAttribute) -> [BlockStepAttribute] {
        [expression]
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: BlockField) -> [BlockStepAttribute] {
        [.field(expression)]
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: [BlockStepAttribute]) -> [BlockStepAttribute] {
        expression
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildOptional(_ component: [BlockStepAttribute]?) -> [BlockStepAttribute] {
        component ?? []
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildEither(first component: [BlockStepAttribute]) -> [BlockStepAttribute] {
        component
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildEither(second component: [BlockStepAttribute]) -> [BlockStepAttribute] {
        component
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildArray(_ components: [[BlockStepAttribute]]) -> [BlockStepAttribute] {
        components.flatMap { $0 }
    }
}

/// Result builder used by matrix configuration APIs.
@resultBuilder
public enum MatrixBuilder {
    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildBlock(_ components: [MatrixComponent]...) -> [MatrixComponent] {
        components.flatMap { $0 }
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: MatrixComponent) -> [MatrixComponent] {
        [expression]
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: [MatrixComponent]) -> [MatrixComponent] {
        expression
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildOptional(_ component: [MatrixComponent]?) -> [MatrixComponent] {
        component ?? []
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildEither(first component: [MatrixComponent]) -> [MatrixComponent] {
        component
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildEither(second component: [MatrixComponent]) -> [MatrixComponent] {
        component
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildArray(_ components: [[MatrixComponent]]) -> [MatrixComponent] {
        components.flatMap { $0 }
    }
}

/// Result builder used by notification lists.
@resultBuilder
public enum NotifyBuilder {
    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildBlock(_ components: [NotificationRule]...) -> [NotificationRule] {
        components.flatMap { $0 }
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: NotificationRule) -> [NotificationRule] {
        [expression]
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: [NotificationRule]) -> [NotificationRule] {
        expression
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildOptional(_ component: [NotificationRule]?) -> [NotificationRule] {
        component ?? []
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildEither(first component: [NotificationRule]) -> [NotificationRule] {
        component
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildEither(second component: [NotificationRule]) -> [NotificationRule] {
        component
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildArray(_ components: [[NotificationRule]]) -> [NotificationRule] {
        components.flatMap { $0 }
    }
}
