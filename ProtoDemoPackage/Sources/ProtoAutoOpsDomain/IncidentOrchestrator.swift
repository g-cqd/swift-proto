import Proto

@Proto
public final class IncidentOrchestrator: IncidentOrchestratorProtocol {
    private let directory: any IncidentResourceDirectoryProtocol

    public init(directory: any IncidentResourceDirectoryProtocol) {
        self.directory = directory
    }

    public func createMitigationPlan(for incident: SecurityIncident) async -> MitigationSummary {
        let pager = directory.defaultPager()
        await pager.notify("Incident \(incident.id): \(incident.title)")

        let runbooks = directory.activePlaybooks()
        var executedSteps: [String] = []
        for runbook in runbooks {
            let steps = await runbook.run(for: incident)
            executedSteps.append(contentsOf: steps)
        }

        let responder = directory.escalationResponder()
        let escalationAccepted = await responder?.acknowledge(incidentID: incident.id) ?? false

        return MitigationSummary(
            incidentID: incident.id,
            pagerChannel: pager.channelName,
            escalationAccepted: escalationAccepted,
            executedSteps: executedSteps,
            responderHandle: responder?.handle
        )
    }
}
