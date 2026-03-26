# Buildkite Pipeline

BuildkitePipeline is an ergonomic Swift DSL for generating Buildkite pipelines.

It combines:
- Swift result builders for human-friendly declarations
- An Encodable-backed schema model
- YAML serialization via [Yams](https://github.com/jpsim/Yams)

The goal is to let you author Buildkite pipelines in strongly typed Swift, while still producing Buildkite-native YAML.

## Installation

Add BuildkitePipeline as a dependency in your `Package.swift`:

```swift
.package(url: "https://github.com/SwiftScream/swift-buildkite-pipeline.git", from: "0.1.0")
```

Then add the product to your target dependencies:

```swift
.product(name: "BuildkitePipeline", package: "swift-buildkite-pipeline")
```

## Quick Start

```swift
import BuildkitePipeline

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

let yaml = try pipeline.toYAML()
print(yaml)
```

## Executable Generator Pattern

For the common case of a Swift executable that prints pipeline YAML to stdout:

```swift
import BuildkitePipeline

@main
struct MyPipeline: PipelineGenerator {
    init() {}

    var pipeline: Pipeline {
        Pipeline {
            Group("Tests") {
                Step("Unit Tests") {
                    Command("swift test")
                }
            }

            Step("Lint") {
                Command("swift-format lint .")
            }
        }
    }
}
```

`PipelineGenerator` provides a default `main()` that:
- uses your `pipeline`
- renders YAML
- writes it to stdout

You can also configure top-level pipeline settings directly in `Pipeline { ... }`:
- `GlobalEnv(...)`
- `DefaultAgent(...)`
- `Metadata(...)`
- `NotifyEmail(...)`, `NotifySlack(...)`, `NotifyWebhook(...)`
- command-step notify helpers: `StepNotifySlack(...)`, `StepNotifyGitHubCheck()`, `StepNotifyGitHubCommitStatus()`

And pipeline-level priority as a modifier:
- `.priority(...)`

### Async Content

`PipelineGenerator.pipeline` is declared as `get async throws`, so you can also use async work directly in the property getter:

```swift
import BuildkitePipeline

@main
struct DynamicPipeline: PipelineGenerator {
    init() {}

    var pipeline: Pipeline {
        get async throws {
            let modules = try await discoverChangedModules()
            return Pipeline {
                for module in modules {
                    Step("Test \(module)") {
                        Command("swift test --filter \(module)")
                    }
                    .key("test-\(module)")
                }
            }
        }
    }
}
```

## DSL Examples

### Command Step With Agents/Env/Retry

```swift
let tests = StepKey("tests")

let pipeline = Pipeline {
    Step("Tests") {
        Command("swift test --parallel")
        Agent(queue: "macos")
        Agent("xcode", "15.4")
        Env("SWIFT_VERSION", "6.0")
        Env("CI", "1")
        Plugin("docker", ref: "v5.9.0")
        StepNotifySlack("#ci-step")
    }
    .key(tests)
    .softFail(exitStatuses: [1])
    .timeoutInMinutes(30)
    .automaticallyRetry(limit: 2)
    .manualRetry(permitOnPassed: true)

    Wait()
        .dependsOn(tests)
}
```

Dependencies are wired with `StepKey` for safer references:

```swift
let build = StepKey("build")

Step("Build") {
    Command("swift build")
}
.key(build)

Step("Test") {
    Command("swift test")
}
.dependsOn(build)

Step("Report") {
    Command("swift run report")
}
.dependsOn(build, allowingFailure(StepKey("flaky-non-blocking-check")))
```

### Shared Defaults For A Step Section

Use `Steps(template:)` with `StepTemplate` to apply shared defaults to multiple steps:

```swift
let lintTemplate = StepTemplate {
    Agent(queue: "ios2")
    Env("XCODE_SCHEME", "Westfield")
}
.timeoutInMinutes(15)

let pipeline = Pipeline {
    Steps(template: lintTemplate) {
        Step(":crossed_fingers: XcodeGen") {
            Command(".buildkite/xcodegen-lint")
        }
        Step(":crossed_fingers: SwiftGen") {
            Command(".buildkite/swiftgen-lint")
        }
        Step(":crossed_fingers: SwiftLint") {
            Command(".buildkite/swiftlint")
        }
        .timeoutInMinutes(30) // step-local value wins over template default
    }
}
```

Template semantics:
- Template values are applied first, then step-local values.
- Step-local values override conflicts (for example duplicate env keys).
- Additive values (plugins, notifications, artifact paths) are prepended from template and then extended by the step.

### Trigger Step With Build Payload

```swift
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
            metadata: ["service": "api"]
        )
}
```

### Block/Input Step

```swift
let pipeline = Pipeline {
    Block("Release to production?") {
        TextField(key: "release_note", text: "Release note", required: true)
        SelectField(
            key: "env",
            select: "Environment",
            options: [
                Option("Staging", value: "staging"),
                Option("Production", value: "production")
            ],
            required: true
        )
    }
        .key("release-gate")
}
```

## Rendering

```swift
let yaml = try pipeline.toYAML()
let json = try pipeline.toJSON()
```

## Design Notes

- DSL-facing declarations are separate from the underlying serializable model.
- The library prefers typed value types/enums for bounded schema areas.
- One-of fields are modeled with enums where practical (`command`, `depends_on`, `soft_fail`, retry modes).
- Custom encoding is limited to cases where Buildkite shape requires it (step union, plugin objects, wait null encoding).
- The structure is intentionally extensible for future schema additions.

## Schema Coverage

This package is inspired by Buildkite’s schema repository:
- [pipeline-schema/schema.json](https://github.com/buildkite/pipeline-schema/blob/main/schema.json)
- [pipeline-schema/test/valid-pipelines](https://github.com/buildkite/pipeline-schema/tree/main/test/valid-pipelines)

Implemented coverage includes:
- Step kinds: command, wait, block/input, trigger, group
- Common attributes: `label`, `key`, `if`, `branches`, `depends_on`, `allow_dependency_failure`
- Command-focused attributes: `command`, `plugins`, `agents`, `env`, `artifact_paths`, `parallelism`, `priority`, `timeout_in_minutes`, `retry`, `soft_fail`, `matrix`, `notify`, `concurrency`, `concurrency_group`, `concurrency_method`
- Trigger build payload: `branch`, `commit`, `message`, `env`, `meta_data`

## Current Limitations / TODO

This first release focuses on common production patterns. Remaining partial areas include:
- Additional notification backends and richer notify payload variants
- Wider plugin option shape helpers (currently generic JSON-like options)
- Full fidelity for all less-common schema branches in `schema.json`
- Expanded validation utilities (e.g. local semantic checks before serialization)
- More fixture parity with every valid pipeline sample from the schema repository

## Testing

Run tests with:

```bash
swift test
```

The suite covers:
- basic pipeline serialization
- command, wait, block/input, trigger, and group step encoding
- env/agents/plugins
- retry/soft_fail/depends_on/matrix/notify
- snapshot-style YAML assertions

## AI Agent Documentation

For repository architecture, conventions, and extension guidance for coding agents, see [AGENTS.md](AGENTS.md).
