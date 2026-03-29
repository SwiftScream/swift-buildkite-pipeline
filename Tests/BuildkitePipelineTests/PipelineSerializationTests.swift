@testable import BuildkitePipeline
import Foundation
import Testing

private struct ExampleGenerator: PipelineGenerator {
    init() {}

    var pipeline: Pipeline {
        let lint = StepKey("lint")

        return Pipeline {
            GlobalEnv("CI", "1")

            Step("Lint") {
                Command("swift-format lint .")
            }
            .key(lint)

            Wait()

            Step("Tests") {
                Command("swift test")
            }
            .dependsOn(lint)
        }
    }
}

private struct ExampleAsyncGenerator: PipelineGenerator {
    init() {}

    var pipeline: Pipeline {
        get async throws {
            let dynamicLabels = ["Lint", "Tests"]
            return Pipeline {
                for label in dynamicLabels {
                    Step(label) {
                        Command("echo \(label)")
                    }
                }
            }
        }
    }
}

@Test
func `Basic pipeline serialization`() throws {
    let pipeline = Pipeline {
        GlobalEnv("CI", "1")
        DefaultAgent(queue: "macos")
        NotifySlack("#ci")

        Group("Tests") {
            Step("Unit Tests") {
                Command("swift test")
            }
        }

        Step("Lint") {
            Command("swift-format lint .")
        }
    }
    .priority(20)

    try assertPipelineYAMLFixture(pipeline, fixtureName: "basic-pipeline-serialization")
}

@Test
func `PipelineGenerator makePipeline and generateYAML`() async throws {
    let pipeline = try await ExampleGenerator.makePipeline()
    let yaml = try await ExampleGenerator.generateYAML()

    #expect(pipeline.env?["CI"] == "1")
    try assertYAMLFixture(yaml, fixtureName: "pipeline-generator-helpers")
}

@Test
func `PipelineGenerator async steps support`() async throws {
    let pipeline = try await ExampleAsyncGenerator.makePipeline()
    let yaml = try await ExampleAsyncGenerator.generateYAML()

    #expect(pipeline.steps.count == 2)
    try assertYAMLFixture(yaml, fixtureName: "pipeline-generator-async-steps")
}

@Test
func `Command step encodes env agents and plugins`() throws {
    let pipeline = Pipeline {
        Step("Tests") {
            Command("swift test --parallel")
            Agent(queue: "macos")
            Agent("xcode", "15.4")
            Env("SWIFT_VERSION", "6.0")
            Env("CI", "1")
            Plugin("docker", ref: "v5.9.0")
            Plugin("artifacts", ref: "v1.9.4", options: ["upload": "build/**/*.zip"])
            ArtifactPath("build/**/*.xcresult")
            ArtifactPath("build/**/*.zip")
        }
        .key("tests")
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "command-step-encodes-env-agents-plugins")
}

@Test
func `Plugin ref initializer composes source and preserves options`() {
    let plugin = Plugin("example/plugin", ref: "v0.1.0")
    let configured = Plugin("artifacts", ref: "main", options: ["download": ".ci-artifacts/report.xml"])

    #expect(plugin.source == "example/plugin#v0.1.0")
    #expect(plugin.options == nil)
    #expect(configured.source == "artifacts#main")
    #expect(configured.options?["download"] == ".ci-artifacts/report.xml")
}

@Test
func `JSONValue string convenience initializer`() {
    let value = JSONValue("hello")
    #expect(value == .string("hello"))
}

@Test
func `Plugin options preserve KeyValuePairs order in YAML`() throws {
    let pipeline = Pipeline {
        Step("Plugin Options Ordering") {
            Command("echo plugin-order")
            Plugin("example/plugin", ref: "v1.0.0", options: [
                "first": "one",
                "second": "two",
                "third": "three",
            ])
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "plugin-options-ordering")
}

@Test
func `Direct initializer artifact paths are encoded as a semicolon-delimited string`() throws {
    let pipeline = Pipeline {
        Step(
            label: "Artifacts",
            command: "echo artifacts",
            artifactPaths: ["build/**/*.xcresult", "build/**/*.zip"],
        )
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "direct-artifact-paths-encoding")
}

@Test
func `Command APIs support string, array, and variadic overloads`() throws {
    let pipeline = Pipeline {
        Step("Array Modifier") {
            Command(["echo one", "echo two"])
        }

        Step("Variadic Modifier") {
            Command("echo a", "echo b")
        }

        Step(
            label: "Direct Array",
            command: ["echo x", "echo y"],
        )
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "command-overload-encoding")
}

@Test
func `Command modifiers merge duplicate agents and env keys with last-write-wins`() throws {
    let pipeline = Pipeline {
        Step("Duplicate Keys") {
            Command("echo ok")
            Agent(queue: "macos-old")
            Agent(queue: "macos")
            Env("SWIFT_VERSION", "5.10")
            Env("SWIFT_VERSION", "6.0")
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "command-modifier-duplicate-key-merging")
}

@Test
func `Command step env and agents preserve DSL insertion order`() throws {
    let pipeline = Pipeline {
        Step("Ordering") {
            Command("echo ordering")
            Agent("zeta", "z")
            Agent(queue: "ios2")
            Agent("alpha", "a")
            Env("B", "2")
            Env("A", "1")
            Env("C", "3")
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "command-step-env-and-agents-ordering")
}

@Test
func `Env KeyValuePairs overload expands reusable environment chunks`() throws {
    let sharedEnv: KeyValuePairs<String, String> = [
        "SWIFT_VERSION": "6.0",
        "CI": "1",
    ]

    let pipeline = Pipeline {
        Step("Chunked Env") {
            Command("echo env")
            Env(sharedEnv)
            Env("MODULE", "BuildkitePipeline")
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "env-key-value-pairs-overload")
}

@Test
func `Env optional KeyValuePairs overload omits nil values`() throws {
    let releaseTag: String? = nil
    let branch: String? = "main"
    let maybeEnv: KeyValuePairs<String, String?> = [
        "CI": "1",
        "RELEASE_TAG": releaseTag,
        "BRANCH": branch,
        "SKIP_ME": nil,
    ]

    let pipeline = Pipeline {
        Step("Optional Env") {
            Command("echo optional-env")
            Env(maybeEnv)
            Env("MODULE", "BuildkitePipeline")
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "env-optional-key-value-pairs-overload")
}

@Test
func `Top-level env and agents preserve DSL insertion order`() throws {
    let pipeline = Pipeline {
        GlobalEnv("B", "2")
        GlobalEnv("A", "1")
        GlobalEnv("C", "3")

        DefaultAgent("zeta", "z")
        DefaultAgent(queue: "ios2")
        DefaultAgent("alpha", "a")

        Step("No-op") {
            Command("echo ok")
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "top-level-env-and-agents-ordering")
}

@Test
func `GlobalEnv KeyValuePairs overloads preserve order and omit nil values`() throws {
    let sharedEnv: KeyValuePairs<String, String> = [
        "B": "2",
        "A": "1",
    ]
    let optionalEnv: KeyValuePairs<String, String?> = [
        "SKIP_ME": nil,
        "C": "3",
    ]

    let pipeline = Pipeline {
        GlobalEnv(sharedEnv)
        GlobalEnv(optionalEnv)

        Step("No-op") {
            Command("echo ok")
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "global-env-key-value-pairs-overloads")
}

@Test
func `DefaultAgent KeyValuePairs overloads preserve order and omit nil values`() throws {
    let sharedAgents: KeyValuePairs<String, JSONValue> = [
        "zeta": "z",
        "queue": "ios2",
    ]
    let optionalAgents: KeyValuePairs<String, JSONValue?> = [
        "alpha": "a",
        "SKIP_ME": nil,
    ]

    let pipeline = Pipeline {
        DefaultAgent(sharedAgents)
        DefaultAgent(optionalAgents)

        Step("No-op") {
            Command("echo ok")
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "default-agent-key-value-pairs-overloads")
}

@Test
func `Top-level metadata preserves DSL insertion order`() throws {
    let pipeline = Pipeline {
        Metadata("B", "2")
        Metadata("A", "1")
        Metadata("C", "3")

        Step("No-op") {
            Command("echo ok")
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "top-level-metadata-ordering")
}

@Test
func `Metadata KeyValuePairs overload expands reusable metadata chunks`() throws {
    let sharedMetadata: KeyValuePairs<String, String> = [
        "service": "mobile",
        "owner": "ios-team",
    ]

    let pipeline = Pipeline {
        Metadata(sharedMetadata)
        Metadata("component", "pipeline")

        Step("No-op") {
            Command("echo ok")
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "metadata-key-value-pairs-overload")
}

@Test
func `Metadata optional KeyValuePairs overload omits nil values`() throws {
    let releaseTag: String? = nil
    let branch: String? = "main"
    let maybeMetadata: KeyValuePairs<String, String?> = [
        "service": "mobile",
        "release_tag": releaseTag,
        "branch": branch,
        "skip_me": nil,
    ]

    let pipeline = Pipeline {
        Metadata(maybeMetadata)
        Metadata("component", "pipeline")

        Step("No-op") {
            Command("echo ok")
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "metadata-optional-key-value-pairs-overload")
}

@Test
func `Step templates apply defaults and keep step-local precedence`() {
    let pipeline = Pipeline {
        Steps(
            template: StepTemplate {
                Agent(queue: "ios2")
                Env("DEFAULT_ENV", "template")
                Env("OVERRIDE_ME", "template")
                Plugin("docker#v5.9.0")
                ArtifactPath("logs/**/*.txt")
            }
            .timeoutInMinutes(15)
            .priority(7),
        ) {
            Step("One") {
                Command("echo one")
                Env("OVERRIDE_ME", "step")
                Plugin("my/plugin#v1.0.0")
                ArtifactPath("one/**/*.zip")
            }

            Step("Two") {
                Command("echo two")
            }
            .timeoutInMinutes(20)

            Wait()
        }
    }

    #expect(pipeline.steps.count == 3)

    guard case .command(let first) = pipeline.steps[0].model else {
        #expect(Bool(false))
        return
    }

    #expect(first.agents?["queue"] == .string("ios2"))
    #expect(first.env?["DEFAULT_ENV"] == "template")
    #expect(first.env?["OVERRIDE_ME"] == "step")
    #expect(first.plugins?.map(\.source) == ["docker#v5.9.0", "my/plugin#v1.0.0"])
    #expect(first.artifactPaths?.paths == ["logs/**/*.txt", "one/**/*.zip"])
    #expect(first.timeoutInMinutes == 15)
    #expect(first.priority == 7)

    guard case .command(let second) = pipeline.steps[1].model else {
        #expect(Bool(false))
        return
    }

    #expect(second.agents?["queue"] == .string("ios2"))
    #expect(second.env?["DEFAULT_ENV"] == "template")
    #expect(second.timeoutInMinutes == 20)
    #expect(second.priority == 7)

    guard case .wait = pipeline.steps[2].model else {
        #expect(Bool(false))
        return
    }
}

@Test
func `Step templates apply recursively to command steps nested in groups`() {
    let pipeline = Pipeline {
        Steps(template: StepTemplate {
            Agent(queue: "ios2")
            Env("GLOBAL", "true")
        }
        .timeoutInMinutes(10)) {
            Group("Verification") {
                Step("Nested One") {
                    Command("echo nested-one")
                }
                Step("Nested Two") {
                    Command("echo nested-two")
                }
                .timeoutInMinutes(30)
            }
        }
    }

    guard case .group(let group) = pipeline.steps[0].model else {
        #expect(Bool(false))
        return
    }
    #expect(group.steps.count == 2)

    guard case .command(let nestedOne) = group.steps[0] else {
        #expect(Bool(false))
        return
    }

    #expect(nestedOne.agents?["queue"] == .string("ios2"))
    #expect(nestedOne.env?["GLOBAL"] == "true")
    #expect(nestedOne.timeoutInMinutes == 10)

    guard case .command(let nestedTwo) = group.steps[1] else {
        #expect(Bool(false))
        return
    }

    #expect(nestedTwo.agents?["queue"] == .string("ios2"))
    #expect(nestedTwo.env?["GLOBAL"] == "true")
    #expect(nestedTwo.timeoutInMinutes == 30)
}

@Test
func `Concurrency settings encode as coupled fields`() throws {
    let pipeline = Pipeline {
        Step("Modifier Concurrency") {
            Command("echo modifier")
        }
        .concurrency(limit: 1, group: "deploy", method: .ordered)

        Step(
            label: "Initializer Concurrency",
            command: "echo initializer",
            concurrency: StepConcurrency(limit: 2, group: "tests", method: .eager),
        )
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "concurrency-encoding")
}

@Test
func `Direct initializers accept typed StepKey values`() throws {
    let commandKey = StepKey("typed-command-key")
    let groupKey = StepKey("typed-group-key")

    let pipeline = Pipeline {
        Step(
            label: "Typed Key Command",
            command: "echo typed",
            key: commandKey,
        )

        Group("Typed Group", key: groupKey) {
            Step("Nested") {
                Command("echo nested")
            }
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "typed-step-key-direct-initializer-encoding")
}

@Test
func `Typed key direct initializer supports optional command overload`() throws {
    let optionalCommand: String? = "echo typed-optional"
    let typedKey = StepKey("typed-optional-key")

    let pipeline = Pipeline {
        Step(
            label: "Typed Optional",
            command: optionalCommand,
            key: typedKey,
        )
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "typed-step-key-optional-command-overload")
}

@Test
func `Dependencies support typed keys and per-edge allow_failure`() throws {
    let build = StepKey("build")
    let lint = StepKey("lint")
    let flaky = StepKey("flaky")

    let pipeline = Pipeline {
        Step("Integration") {
            Command("swift test --filter Integration")
        }
        .dependsOn(build, lint, allowingFailure(flaky))
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "typed-dependency-encoding")
}

@Test
func `Wait step encoding`() throws {
    let build = StepKey("build")

    let pipeline = Pipeline {
        Step("Build") {
            Command("swift build")
        }
        .key(build)
        Wait()
            .dependsOn(build)
            .allowDependencyFailure()
            .condition("build.branch == \"main\"")
        Step("Post-Wait") {
            Command("echo done")
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "wait-step-encoding")
}

@Test
func `Block and input step encoding`() throws {
    let pipeline = Pipeline {
        Block("Release to production?") {
            TextField(key: "release_note", text: "Release note", required: true)
            SelectField(
                key: "env",
                select: "Environment",
                options: [
                    Option("Staging", value: "staging"),
                    Option("Production", value: "production"),
                ],
                required: true,
            )
        }
        .key("release-gate")
        .prompt("Only release from green builds")

        Input("Who is approving this release?")
            .key("approver")
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "block-and-input-encoding")
}

@Test
func `Nameless block step encodes as scalar marker`() throws {
    let pipeline = Pipeline {
        Block()
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "nameless-block-encoding")
}

@Test
func `Nameless block step with attributes encodes block as empty string`() throws {
    let build = StepKey("build")

    let pipeline = Pipeline {
        Step("Build") {
            Command("swift build")
        }
        .key(build)

        Block()
            .dependsOn(build)
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "nameless-block-with-attributes-encoding")
}

@Test
func `Trigger step with build payload`() throws {
    let pipeline = Pipeline {
        Trigger("deploy-pipeline")
            .label("Deploy")
            .key("deploy")
            .asynchronous()
            .build(
                branch: "main",
                commit: "HEAD",
                message: "Triggered from BuildkitePipeline",
                env: ["RELEASE": "true"],
                metadata: ["service": "api"],
            )
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "trigger-step-encoding")
}

@Test
func `Group step encoding`() throws {
    let pipeline = Pipeline {
        Group("Verification", key: "verification") {
            Step("Lint") {
                Command("swift-format lint .")
            }
            Step("Tests") {
                Command("swift test")
            }
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "group-step-encoding")
}

@Test
func `Retry soft_fail depends_on matrix and notify encoding`() throws {
    let build = StepKey("build")
    let lint = StepKey("lint")

    let pipeline = Pipeline {
        Step("Matrix Tests") {
            Command("swift test")
            Matrix {
                Dimension("swift", values: ["5.10", "6.0"])
                Dimension("os", values: ["macos-14", "ubuntu-22.04"])
                Adjustment(with: ["swift": "6.0", "os": "ubuntu-22.04"], softFail: true)
            }
            StepNotifyGitHubCheck()
            StepNotifySlack("#ci-alerts")
        }
        .dependsOn(keys: [build, lint])
        .softFail(exitStatuses: [1, 2])
        .automaticallyRetry(limit: 2)
        .manualRetry(permitOnPassed: true)
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "retry-soft-fail-depends-on-matrix-and-notify-encoding")
}

@Test
func `Command step notify encodes github_commit_status selector`() throws {
    let pipeline = Pipeline {
        Step("Notify Coverage") {
            Command("echo notify")
            StepNotifyGitHubCommitStatus()
            StepNotifyGitHubCheck()
        }
    }

    try assertPipelineYAMLFixture(
        pipeline,
        fixtureName: "command-step-github-commit-status-notify-encoding",
    )
}

@Test
func `YAML snapshot style output`() throws {
    let lint = StepKey("lint")

    let pipeline = Pipeline {
        Step("Lint") {
            Command("swift-format lint .")
        }
        .key(lint)

        Wait()

        Step("Test") {
            Command("swift test")
        }
        .dependsOn(lint)
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "yaml-snapshot-style-output")
}

@Test
func `Fixture parity command-with-wait`() throws {
    let lint = StepKey("lint")

    let pipeline = Pipeline {
        Step("Lint") {
            Command("swift-format lint .")
        }
        .key(lint)

        Wait()

        Step("Test") {
            Command("swift test")
        }
        .dependsOn(lint)
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "fixture-parity-command-with-wait")
}
