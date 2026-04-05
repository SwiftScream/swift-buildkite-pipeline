@testable import BuildkitePipeline
import Foundation
import Testing

@Test
func `PipelineBuilder and PipelineStepsBuilder support control flow and fragment expressions`() throws {
    let alwaysTrue = Date().timeIntervalSinceReferenceDate > 0
    let alwaysFalse = Date().timeIntervalSinceReferenceDate < 0
    let optionalFlag = ProcessInfo.processInfo.environment["BUILDKITE_PIPELINE_OPTIONAL"] == "1"

    let extraTopLevelSteps = Step("Top Array Step") {
        Command("echo top-array")
    }
    .pipelineFragment

    let sharedEnv = GlobalEnv([
        "SHARED_A": "1",
        "SHARED_B": "2",
    ])

    let sharedAgents = DefaultAgent([
        "queue": "ios2",
        "fleet": "test",
    ])

    let sharedMetadata = Metadata([
        "owner": "ci",
        "component": "builder-coverage",
    ])

    let pipeline = Pipeline {
        if alwaysTrue {
            GlobalEnv("FIRST_BRANCH", "true")
        } else {
            GlobalEnv("FIRST_BRANCH", "false")
        }

        if alwaysFalse {
            DefaultAgent("branch", "first")
        } else {
            DefaultAgent("branch", "second")
        }

        if optionalFlag {
            Metadata("optional", "present")
        }

        sharedEnv
        sharedAgents
        sharedMetadata

        if alwaysTrue {
            NotifySlack("#pipeline-builder")
        } else {
            NotifyEmail("never@example.com")
        }

        if alwaysFalse {
            Step("Never Top") {
                Command("echo never")
            }
        } else {
            Step("Else Top") {
                Command("echo else")
            }
        }

        for label in ["Loop Top 1", "Loop Top 2"] {
            Step(label) {
                Command("echo \(label)")
            }
        }

        extraTopLevelSteps

        Group("Child Control Flow") {
            if alwaysTrue {
                Step("Child First") {
                    Command("echo child-first")
                }
            } else {
                Step("Child Never First") {
                    Command("echo child-never-first")
                }
            }

            if alwaysFalse {
                Step("Child Never Second") {
                    Command("echo child-never-second")
                }
            } else {
                Step("Child Second") {
                    Command("echo child-second")
                }
            }

            if optionalFlag {
                Step("Child Optional") {
                    Command("echo child-optional")
                }
            }

            for i in 1...2 {
                Step("Child Loop \(i)") {
                    Command("echo child-loop-\(i)")
                }
            }

            let childArray = Step("Child Array Step") {
                Command("echo child-array")
            }
            .pipelineFragment
            childArray
        }
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "pipeline-builder-control-flow")
}

@Test
func `CommandStepBuilder and MatrixBuilder support control flow and arrays`() throws {
    let alwaysTrue = Date().timeIntervalSinceReferenceDate > 0
    let alwaysFalse = Date().timeIntervalSinceReferenceDate < 0
    let optionalFlag = ProcessInfo.processInfo.environment["BUILDKITE_COMMAND_OPTIONAL"] == "1"

    let step = Step("Command Builder Coverage") {
        if alwaysTrue {
            Command("echo command-first")
        } else {
            Command("echo command-never-first")
        }

        if alwaysFalse {
            Command("echo command-never-second")
        } else {
            Command("echo command-second")
        }

        if optionalFlag {
            Command("echo command-optional")
        }

        for path in ["logs/a/**", "logs/b/**"] {
            ArtifactPath(path)
        }

        let commandAttrs: [CommandStepAttribute] = [
            ArtifactPath("logs/array/**"),
            .notification(StepNotifySlack("#command-array")),
        ]
        commandAttrs

        let envChunk: [EnvironmentVariable] = Env([
            "ENV_ONE": "1",
            "ENV_TWO": "2",
        ])
        envChunk

        Agent("role", "coverage")
        StepNotifySlack("#command-builder")
        Plugin("docker", ref: "v5.9.0")

        Matrix {
            if alwaysTrue {
                Dimension("swift", values: ["5.10", "6.0"])
            } else {
                Dimension("never", values: ["0"])
            }

            if alwaysFalse {
                Adjustment(with: ["swift": "5.10"], skip: true)
            } else {
                Adjustment(with: ["swift": "6.0"], softFail: true)
            }

            if optionalFlag {
                Dimension("optional", values: ["x"])
            }

            for os in ["macos", "linux"] {
                Adjustment(with: ["os": os], skip: os == "linux")
            }

            let matrixArray: [MatrixComponent] = [
                Dimension("arch", values: ["arm64"]),
            ]
            matrixArray
        }
    }

    let pipeline = Pipeline { step }
    try assertPipelineYAMLFixture(pipeline, fixtureName: "command-and-matrix-builder-control-flow")
}

@Test
func `BlockStepBuilder and NotifyBuilder support control flow and arrays`() throws {
    let alwaysTrue = Date().timeIntervalSinceReferenceDate > 0
    let alwaysFalse = Date().timeIntervalSinceReferenceDate < 0
    let optionalFlag = ProcessInfo.processInfo.environment["BUILDKITE_BLOCK_OPTIONAL"] == "1"
    let webhookURL = try #require(URL(string: "https://example.com/hook"))

    let gate = Group("Notify Gate") {
        Step("Inside Group") {
            Command("echo group")
        }
    }
    .notify {
        if alwaysTrue {
            NotifySlack("#group-first")
        } else {
            NotifyEmail("never-first@example.com")
        }

        if alwaysFalse {
            NotifyEmail("never-second@example.com")
        } else {
            NotifyWebhook(webhookURL)
        }

        if optionalFlag {
            NotifyEmail("optional@example.com")
        }

        for address in ["loop-a@example.com", "loop-b@example.com"] {
            NotifyEmail(address)
        }

        let notifyArray: [NotificationRule] = [
            NotifyEmail("array@example.com"),
        ]
        notifyArray
    }

    let block = Block("Release?") {
        if alwaysTrue {
            TextField(key: "reason", text: "Reason")
        } else {
            TextField(key: "never-first", text: "Never")
        }

        if alwaysFalse {
            TextField(key: "never-second", text: "Never")
        } else {
            SelectField(
                key: "env",
                select: "Environment",
                options: [
                    Option("Staging", value: "staging"),
                    Option("Production", value: "production"),
                ],
            )
        }

        if optionalFlag {
            TextField(key: "optional", text: "Optional")
        }

        for i in 1...2 {
            TextField(key: "loop_\(i)", text: "Loop \(i)")
        }

        let blockArray: [BlockStepAttribute] = [
            .field(TextField(key: "array_field", text: "Array Field")),
        ]
        blockArray

        BlockStepAttribute.field(TextField(key: "direct_field", text: "Direct Field"))
    }

    let pipeline = Pipeline {
        gate
        block
    }

    try assertPipelineYAMLFixture(pipeline, fixtureName: "block-and-notify-builder-control-flow")
}
