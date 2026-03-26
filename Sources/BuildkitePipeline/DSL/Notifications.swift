import Foundation

/// Creates an email notification rule.
public func NotifyEmail(_ address: String, condition: String? = nil) -> NotificationRule {
    .email(EmailNotification(email: address, condition: condition))
}

/// Creates a Slack notification rule.
public func NotifySlack(_ channel: String, condition: String? = nil) -> NotificationRule {
    .slack(SlackNotification(slack: channel, condition: condition))
}

/// Creates a webhook notification rule.
public func NotifyWebhook(_ url: URL, condition: String? = nil) -> NotificationRule {
    .webhook(WebhookNotification(webhook: url, condition: condition))
}

/// Creates a Slack notification rule for command-step `notify`.
public func StepNotifySlack(_ channel: String, condition: String? = nil) -> CommandStepNotificationRule {
    .slack(SlackNotification(slack: channel, condition: condition))
}

/// Creates the `github_check` command-step notification selector.
public func StepNotifyGitHubCheck() -> CommandStepNotificationRule {
    .githubCheck
}

/// Creates the `github_commit_status` command-step notification selector.
public func StepNotifyGitHubCommitStatus() -> CommandStepNotificationRule {
    .githubCommitStatus
}
