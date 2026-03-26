@testable import BuildkitePipeline
import Testing

@Test
func `Pipeline JSON rendering supports pretty and compact output`() throws {
    let pipeline = Pipeline {
        Step("JSON") {
            Command("echo json")
        }
    }

    let pretty = try pipeline.toJSON(prettyPrinted: true)
    let compact = try pipeline.toJSON(prettyPrinted: false)

    #expect(pretty.contains("\n"))
    #expect(!compact.contains("\n"))
    #expect(pretty.contains("\"steps\""))
    #expect(compact.contains("\"steps\""))
}

@Test
func `Pipeline direct initializer and computed rendering accessors`() throws {
    let erasedStep = Wait().pipelineStep
    #expect(erasedStep.pipelineStep == erasedStep)

    let pipeline = Pipeline(
        env: ["CI": "1"],
        agents: ["queue": "ios2"],
        notify: [NotifyEmail("direct@example.com")],
        metadata: ["owner": "platform"],
        priority: 11,
        steps: [erasedStep],
    )

    #expect(pipeline.env?["CI"] == "1")
    #expect(pipeline.agents?["queue"] == .string("ios2"))
    #expect(pipeline.metadata?["owner"] == "platform")
    #expect(pipeline.priority == 11)

    let yaml = try pipeline.yamlString
    let json = try pipeline.jsonString
    try assertYAMLFixture(yaml, fixtureName: "pipeline-direct-initializer-and-computed-accessors")
    #expect(json.contains("\"meta_data\""))
}
