@testable import BuildkitePipeline
import Testing

@Test
func `Command step builder aggregates command attributes and normalizes cardinality`() {
    let pipeline = Pipeline {
        Step("No Command Attribute") {
            Agent(queue: "ios2")
        }

        Step("Single Command From Array Attribute") {
            Command(["echo one"])
        }

        Step("Multiple Commands Across Attributes") {
            Command("echo two")
            Command("echo three")
        }

        Step("Mixed Command Attributes Flatten In Order") {
            Command("echo four")
            Command(["echo five", "echo six"])
            Command()
        }

        Step("Only Empty Command Attributes") {
            Command()
            Command([])
        }
    }

    guard case .command(let first) = pipeline.materializedStepModels[0] else {
        Issue.record("Expected first step to be command")
        return
    }
    #expect(first.command == nil)

    guard case .command(let second) = pipeline.materializedStepModels[1] else {
        Issue.record("Expected second step to be command")
        return
    }
    #expect(second.command == .single("echo one"))

    guard case .command(let third) = pipeline.materializedStepModels[2] else {
        Issue.record("Expected third step to be command")
        return
    }
    #expect(third.command == .multiple(["echo two", "echo three"]))

    guard case .command(let fourth) = pipeline.materializedStepModels[3] else {
        Issue.record("Expected fourth step to be command")
        return
    }
    #expect(fourth.command == .multiple(["echo four", "echo five", "echo six"]))

    guard case .command(let fifth) = pipeline.materializedStepModels[4] else {
        Issue.record("Expected fifth step to be command")
        return
    }
    #expect(fifth.command == nil)
}

@Test
func `Command step direct initializers and modifiers cover remaining overloads`() {
    let directStringKey = StepKey("direct-string")
    let directArrayKey = StepKey("direct-array")

    let modified = Step("Initial Label") {
        Command("echo modified")
    }
    .label("Relabeled")
    .condition("build.branch == \"main\"")
    .branches("main")
    .allowDependencyFailure()
    .concurrency(StepConcurrency(limit: 2, group: "mod", method: .eager))
    .softFail()
    .retry(RetryPolicy(manual: RetryManual(permitOnPassed: true)))
    .automaticallyRetry(false)
    .automaticallyRetry(rules: [RetryRule(exitStatus: 1, limit: 2)])
    .priority(7)
    .parallelism(3)

    let pipeline = Pipeline {
        Step(
            label: "Direct String",
            command: "echo direct-string",
            key: directStringKey,
        )

        Step(
            label: "Direct Array",
            command: ["echo one", "echo two"],
            key: directArrayKey,
        )

        modified
    }

    guard case .command(let first) = pipeline.materializedStepModels[0] else {
        Issue.record("Expected first step to be command")
        return
    }
    #expect(first.key == directStringKey.rawValue)
    #expect(first.command == .single("echo direct-string"))

    guard case .command(let second) = pipeline.materializedStepModels[1] else {
        Issue.record("Expected second step to be command")
        return
    }
    #expect(second.key == directArrayKey.rawValue)
    #expect(second.command == .multiple(["echo one", "echo two"]))

    guard case .command(let third) = pipeline.materializedStepModels[2] else {
        Issue.record("Expected third step to be command")
        return
    }
    #expect(third.label == "Relabeled")
    #expect(third.condition == "build.branch == \"main\"")
    #expect(third.branches == "main")
    #expect(third.allowDependencyFailure == true)
    #expect(third.concurrency == 2)
    #expect(third.concurrencyGroup == "mod")
    #expect(third.concurrencyMethod == .eager)
    #expect(third.softFail == .enabled(true))
    #expect(third.priority == 7)
    #expect(third.parallelism == 3)
    #expect(third.retry?.automatic == .rules([RetryRule(exitStatus: 1, limit: 2)]))
}

@Test
func `Group step modifiers cover typed keys dependencies and notify builder`() {
    let baseDependency = StepKey("base-dep")
    let group = Group(
        "Group Base",
        key: StepKey("group-base"),
        condition: "build.branch == \"develop\"",
        branches: "develop",
        dependsOn: [StepDependency(baseDependency)],
        allowDependencyFailure: true,
        notify: [NotifySlack("#base-group")],
    ) {
        Step("Child") {
            Command("echo child")
        }
    }
    .key("group-override")
    .key(StepKey("group-final"))
    .condition("build.branch == \"main\"")
    .branches("main")
    .dependsOn([StepDependency(StepKey("dep-array"))])
    .dependsOn(StepKey("dep-var"), allowingFailure(StepKey("dep-var-allow")))
    .dependsOn(keys: [StepKey("dep-keys")])
    .allowDependencyFailure(false)
    .notify {
        NotifyEmail("group@example.com")
    }

    let pipeline = Pipeline { group }
    guard case .group(let model) = pipeline.materializedStepModels[0] else {
        Issue.record("Expected group step")
        return
    }

    #expect(model.key == "group-final")
    #expect(model.condition == "build.branch == \"main\"")
    #expect(model.branches == "main")
    #expect(model.allowDependencyFailure == false)
    #expect(model.dependsOn == .single(.key("dep-keys")))
    #expect(model.notify == [NotifyEmail("group@example.com")])
}

@Test
func `Trigger step modifiers cover retry dependency and metadata helpers`() {
    let trigger = Trigger("deploy-pipeline")
        .label("Deploy")
        .key("deploy-key")
        .key(StepKey("deploy-key-typed"))
        .condition("build.branch == \"main\"")
        .branches("main")
        .dependsOn([StepDependency(StepKey("dep-array"))])
        .dependsOn(StepKey("dep-var"), allowingFailure(StepKey("dep-var-allow")))
        .dependsOn(keys: [StepKey("dep-keys")])
        .allowDependencyFailure()
        .asynchronous(false)
        .softFail()
        .softFail(exitStatuses: [1, 2])
        .retry(RetryPolicy(automatic: .enabled(false)))
        .automaticallyRetry(false)
        .automaticallyRetry(limit: 2)
        .automaticallyRetry(rules: [RetryRule(exitStatus: 9, limit: 3)])
        .manualRetry(allowed: true, permitOnPassed: true, reason: "manual retry")
        .build(
            branch: "main",
            commit: "HEAD",
            message: "first build",
            env: ["FIRST": "1"],
            metadata: ["service": "api"],
        )
        .build(TriggerBuild(branch: "release", metadata: ["channel": "stable"]))

    let pipeline = Pipeline { trigger }
    guard case .trigger(let model) = pipeline.materializedStepModels[0] else {
        Issue.record("Expected trigger step")
        return
    }

    #expect(model.label == "Deploy")
    #expect(model.key == "deploy-key-typed")
    #expect(model.condition == "build.branch == \"main\"")
    #expect(model.branches == "main")
    #expect(model.dependsOn == .single(.key("dep-keys")))
    #expect(model.allowDependencyFailure == true)
    #expect(model.async == false)
    #expect(model.softFail == .conditions([SoftFailCondition(exitStatus: 1), SoftFailCondition(exitStatus: 2)]))
    #expect(model.retry?.automatic == .rules([RetryRule(exitStatus: 9, limit: 3)]))
    #expect(model.retry?.manual == RetryManual(allowed: true, permitOnPassed: true, reason: "manual retry"))
    #expect(model.build == TriggerBuild(branch: "release", metadata: ["channel": "stable"]))
}

@Test
func `Wait step covers key-based dependencies and continue-on-failure modifier`() {
    let wait = Wait(
        continueOnFailure: false,
        dependsOn: [StepDependency(StepKey("dep-initial"))],
        allowDependencyFailure: false,
        condition: "build.branch == \"dev\"",
        branches: "dev",
    )
    .branches("main")
    .dependsOn(keys: [StepKey("dep-key-1"), StepKey("dep-key-2")])
    .continueOnFailure()
    .condition("build.branch == \"main\"")
    .allowDependencyFailure()

    let pipeline = Pipeline { wait }
    guard case .wait(let model) = pipeline.materializedStepModels[0] else {
        Issue.record("Expected wait step")
        return
    }

    #expect(model.branches == "main")
    #expect(model.continueOnFailure == true)
    #expect(model.condition == "build.branch == \"main\"")
    #expect(model.allowDependencyFailure == true)
    #expect(model.dependsOn == .multiple([.key("dep-key-1"), .key("dep-key-2")]))
}

@Test
func `Block step typed modifiers cover dependency overloads`() {
    let block = Block("Release Gate")
        .key(StepKey(rawValue: "block-key"))
        .condition("build.branch == \"main\"")
        .branches("main")
        .dependsOn([StepDependency(key: StepKey(rawValue: "dep-array"), allowFailure: true)])
        .dependsOn(StepKey(rawValue: "dep-var"), allowingFailure(StepKey(rawValue: "dep-var-allow")))
        .dependsOn(keys: [StepKey(rawValue: "dep-final")])
        .allowDependencyFailure(false)

    let pipeline = Pipeline { block }
    guard case .block(let model) = pipeline.materializedStepModels[0] else {
        Issue.record("Expected block step")
        return
    }

    #expect(model.key == "block-key")
    #expect(model.condition == "build.branch == \"main\"")
    #expect(model.branches == "main")
    #expect(model.allowDependencyFailure == false)
    #expect(model.dependsOn == .single(.key("dep-final")))
}
