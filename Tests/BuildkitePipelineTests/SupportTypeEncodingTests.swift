@testable import BuildkitePipeline
import Foundation
import Testing

@Test
func `JSONValue literal initializers and encoding cover all cases`() throws {
    let stringValue = JSONValue("manual")
    let intValue: JSONValue = 42
    let doubleValue: JSONValue = 3.14
    let boolValue: JSONValue = true
    let nilValue: JSONValue = nil
    let arrayValue: JSONValue = ["x", 1, false]
    let objectValue: JSONValue = [
        "k": "v",
        "n": nil,
    ]

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    func encoded(_ value: JSONValue) throws -> String {
        let data = try encoder.encode(value)
        return try #require(String(data: data, encoding: .utf8))
    }

    #expect(try encoded(stringValue) == "\"manual\"")
    #expect(try encoded(intValue) == "42")
    #expect(try encoded(doubleValue).contains("3.14"))
    #expect(try encoded(boolValue) == "true")
    #expect(try encoded(nilValue) == "null")
    #expect(try encoded(arrayValue) == "[\"x\",1,false]")
    #expect(try encoded(objectValue) == "{\"k\":\"v\",\"n\":null}")
}

@Test
func `DynamicCodingKey int initializer stores both values`() {
    let key = DynamicCodingKey(intValue: 42)
    #expect(key?.stringValue == "42")
    #expect(key?.intValue == 42)
}

@Test
func `Command values, retry and soft-fail encode all single-value branches`() throws {
    let single = CommandValue("echo one")
    #expect(single == .single("echo one"))
    #expect(single.values == ["echo one"])
    #expect(CommandValue(["echo a", "echo b"]).values == ["echo a", "echo b"])

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    func encode(_ value: some Encodable) throws -> String {
        let data = try encoder.encode(value)
        return try #require(String(data: data, encoding: .utf8))
    }

    #expect(try encode(SoftFailPolicy.enabled(false)) == "false")
    #expect(try encode(RetryAutomatic.enabled(true)) == "true")
    let rulesJSON = try encode(RetryAutomatic.rules([RetryRule(exitStatus: 17, limit: 2)]))
    #expect(rulesJSON.contains("\"exit_status\":17"))
    #expect(rulesJSON.contains("\"limit\":2"))
}

@Test
func `OrderedKeyValuePairs dictionary initializer and subscript mutation`() {
    var values = OrderedKeyValuePairs<String>([
        "b": "2",
        "a": "1",
    ])

    #expect(values["a"] == "1")
    #expect(values.allEntries.map(\.key) == ["a", "b"])

    values["a"] = nil
    #expect(values["a"] == nil)
    #expect(values.allEntries.map(\.key) == ["b"])
}

@Test
func `Plugin options setter updates ordered options`() {
    var plugin = Plugin("example/plugin")
    plugin.options = ["enabled": true, "limit": 2]
    #expect(plugin.options?["enabled"] == .bool(true))
    #expect(plugin.options?["limit"] == .int(2))
}
