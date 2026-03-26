import Foundation

/// A protocol for CLI-style generators that produce full pipelines.
///
/// Conform a type, mark it with `@main`, and provide `pipeline`.
/// The requirement is `async throws` for maximum flexibility, but conformers may
/// implement `pipeline` as a plain getter, a throwing getter, or an async throwing getter.
public protocol PipelineGenerator {
    /// The generated pipeline.
    var pipeline: Pipeline { get async throws }

    /// Creates a generator instance.
    init()
}

public extension PipelineGenerator {
    /// Creates the full pipeline from the generator.
    static func makePipeline() async throws -> Pipeline {
        let generator = Self()
        return try await generator.pipeline
    }

    /// Renders the generated pipeline as YAML.
    static func generateYAML() async throws -> String {
        try await makePipeline().toYAML()
    }

    /// Default executable entrypoint for `@main` pipeline generators.
    static func main() async throws {
        let yaml = try await generateYAML()
        FileHandle.standardOutput.write(Data(yaml.utf8))
        if !yaml.hasSuffix("\n") {
            FileHandle.standardOutput.write(Data("\n".utf8))
        }
    }
}
