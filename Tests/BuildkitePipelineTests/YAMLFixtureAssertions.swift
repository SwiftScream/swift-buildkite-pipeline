@testable import BuildkitePipeline
import Foundation
import Testing

private let recordYAMLFixtures = ProcessInfo.processInfo.environment["RECORD_YAML_FIXTURES"] == "1"

private let yamlFixturesDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("Fixtures")
    .appendingPathComponent("YAML")

private func normalizeYAML(_ value: String) -> String {
    value
        .replacingOccurrences(of: "\r\n", with: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func writeFixture(_ value: String, to url: URL) throws {
    let directory = url.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try (normalizeYAML(value) + "\n").write(to: url, atomically: true, encoding: .utf8)
}

func assertYAMLFixture(_ yaml: String, fixtureName: String) throws {
    let fixtureURL = yamlFixturesDirectory.appendingPathComponent("\(fixtureName).yaml")

    if recordYAMLFixtures {
        try writeFixture(yaml, to: fixtureURL)
        return
    }

    let expected = try String(contentsOf: fixtureURL, encoding: .utf8)
    #expect(normalizeYAML(yaml) == normalizeYAML(expected))
}

func assertPipelineYAMLFixture(_ pipeline: Pipeline, fixtureName: String) throws {
    try assertYAMLFixture(pipeline.toYAML(), fixtureName: fixtureName)
}
