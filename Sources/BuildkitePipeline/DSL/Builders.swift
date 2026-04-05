import Foundation

/// Intermediate content container used by `PipelineBuilder`.
public struct PipelineContent {
    var fragments: [PipelineFragment]
    var globalEnv: [GlobalEnvironmentVariable]
    var defaultAgents: [DefaultAgentEntry]
    var metadata: [MetadataEntry]
    var notify: [NotificationRule]

    init(
        fragments: [PipelineFragment] = [],
        globalEnv: [GlobalEnvironmentVariable] = [],
        defaultAgents: [DefaultAgentEntry] = [],
        metadata: [MetadataEntry] = [],
        notify: [NotificationRule] = [],
    ) {
        self.fragments = fragments
        self.globalEnv = globalEnv
        self.defaultAgents = defaultAgents
        self.metadata = metadata
        self.notify = notify
    }

    static func + (lhs: PipelineContent, rhs: PipelineContent) -> PipelineContent {
        PipelineContent(
            fragments: lhs.fragments + rhs.fragments,
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
    public static func buildExpression(_ expression: some PipelineFragmentConvertible) -> PipelineContent {
        PipelineContent(fragments: [expression.pipelineFragment])
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: PipelineFragment) -> PipelineContent {
        PipelineContent(fragments: [expression])
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
public enum PipelineFragmentBuilder {
    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildBlock(_ components: PipelineFragment...) -> PipelineFragment {
        components.reduce(.empty, +)
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: some PipelineFragmentConvertible) -> PipelineFragment {
        expression.pipelineFragment
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildExpression(_ expression: PipelineFragment) -> PipelineFragment {
        expression
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildOptional(_ component: PipelineFragment?) -> PipelineFragment {
        component ?? .empty
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildEither(first component: PipelineFragment) -> PipelineFragment {
        component
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildEither(second component: PipelineFragment) -> PipelineFragment {
        component
    }

    /// Builds and returns a partial result for the enclosing result builder.
    public static func buildArray(_ components: [PipelineFragment]) -> PipelineFragment {
        components.reduce(.empty, +)
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
