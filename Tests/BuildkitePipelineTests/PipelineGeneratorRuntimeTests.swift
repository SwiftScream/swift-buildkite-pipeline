@testable import BuildkitePipeline
import Testing

private struct MainCoverageGenerator: PipelineGenerator {
    init() {}

    var pipeline: Pipeline {
        Pipeline {
            Step("Main") {
                Command("echo main")
            }
        }
    }
}

@Test
func `PipelineGenerator main entrypoint is executable`() async throws {
    try await MainCoverageGenerator.main()
}
