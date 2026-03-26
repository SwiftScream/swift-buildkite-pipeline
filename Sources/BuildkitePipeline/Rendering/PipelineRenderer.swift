import Foundation
import Yams

enum PipelineRenderer {
    static func renderYAML(_ pipeline: PipelineModel) throws -> String {
        let encoder = YAMLEncoder()
        encoder.options.sortKeys = false
        return try encoder.encode(pipeline)
    }

    static func renderJSON(_ pipeline: PipelineModel, prettyPrinted: Bool) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = prettyPrinted ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        let data = try encoder.encode(pipeline)
        guard let output = String(data: data, encoding: .utf8) else {
            throw NSError(
                domain: "BuildkitePipeline.PipelineRenderer",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON output to UTF-8 string"],
            )
        }

        return output
    }
}
