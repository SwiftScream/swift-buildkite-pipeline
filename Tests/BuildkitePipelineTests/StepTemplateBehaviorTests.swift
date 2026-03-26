@testable import BuildkitePipeline
import Testing

@Test
func `Step template modifiers and merge paths cover defaults and overrides`() {
    let template = StepTemplate {
        Command("echo template-command")
        Agent(queue: "template-queue")
        Env("TEMPLATE_ENV", "1")
        Plugin("template/plugin", ref: "v1.0.0")
        ArtifactPath("template/logs/**")
        Matrix {
            Dimension("swift", values: ["6.0"])
        }
        StepNotifySlack("#template")
    }
    .condition("build.branch == \"main\"")
    .branches("main")
    .softFail()
    .softFail(exitStatuses: [7])
    .retry(RetryPolicy(automatic: .enabled(false)))
    .automaticallyRetry()
    .automaticallyRetry(limit: 3)
    .automaticallyRetry(rules: [RetryRule(exitStatus: 3, limit: 1)])
    .manualRetry(allowed: true, permitOnPassed: true, reason: "template")
    .timeoutInMinutes(12)
    .priority(9)
    .parallelism(2)
    .concurrency(limit: 1, group: "template-group", method: .ordered)
    .concurrency(StepConcurrency(limit: 4, group: "template-group-2", method: .eager))
    .allowDependencyFailure()

    let pipeline = Pipeline {
        Steps(template: template) {
            Step(label: "No Local Command", command: nil as String?)

            Step("With Locals") {
                Command("echo local-command")
                Agent("role", "local")
                Env("TEMPLATE_ENV", "local-override")
                Plugin("local/plugin", ref: "v2.0.0")
                ArtifactPath("local/logs/**")
                StepNotifyGitHubCommitStatus()
            }
            .concurrency(limit: 10, group: "step-group")
        }
    }

    guard case .command(let noLocal) = pipeline.steps[0].model else {
        Issue.record("Expected first command step")
        return
    }

    #expect(noLocal.command == .single("echo template-command"))
    #expect(noLocal.agents?["queue"] == .string("template-queue"))
    #expect(noLocal.env?["TEMPLATE_ENV"] == "1")
    #expect(noLocal.plugins?.map(\.source) == ["template/plugin#v1.0.0"])
    #expect(noLocal.artifactPaths?.paths == ["template/logs/**"])
    #expect(noLocal.notify == [StepNotifySlack("#template")])
    #expect(noLocal.condition == "build.branch == \"main\"")
    #expect(noLocal.branches == "main")
    #expect(noLocal.softFail == .conditions([SoftFailCondition(exitStatus: 7)]))
    #expect(noLocal.retry?.automatic == .rules([RetryRule(exitStatus: 3, limit: 1)]))
    #expect(noLocal.retry?.manual == RetryManual(allowed: true, permitOnPassed: true, reason: "template"))
    #expect(noLocal.timeoutInMinutes == 12)
    #expect(noLocal.priority == 9)
    #expect(noLocal.parallelism == 2)
    #expect(noLocal.allowDependencyFailure == true)
    #expect(noLocal.concurrency == 4)
    #expect(noLocal.concurrencyGroup == "template-group-2")
    #expect(noLocal.concurrencyMethod == .eager)

    guard case .command(let withLocals) = pipeline.steps[1].model else {
        Issue.record("Expected second command step")
        return
    }

    #expect(withLocals.command == .single("echo local-command"))
    #expect(withLocals.agents?["queue"] == .string("template-queue"))
    #expect(withLocals.agents?["role"] == .string("local"))
    #expect(withLocals.env?["TEMPLATE_ENV"] == "local-override")
    #expect(withLocals.plugins?.map(\.source) == ["template/plugin#v1.0.0", "local/plugin#v2.0.0"])
    #expect(withLocals.artifactPaths?.paths == ["template/logs/**", "local/logs/**"])
    #expect(withLocals.notify == [StepNotifySlack("#template"), StepNotifyGitHubCommitStatus()])
    #expect(withLocals.concurrency == 10)
    #expect(withLocals.concurrencyGroup == "step-group")
}
