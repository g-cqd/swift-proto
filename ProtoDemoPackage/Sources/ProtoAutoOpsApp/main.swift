import Foundation
import ProtoAutoOpsDomain

@main
enum ProtoAutoOpsApp {
    static func main() async {
        let incident = SecurityIncident(
            id: "INC-7421",
            title: "Suspicious API token usage",
            severity: .critical,
            reportedAt: Date()
        )

        let directory = IncidentResourceDirectory(
            responder: Responder(handle: "sec-primary"),
            playbooks: [
                Playbook(id: "containment", steps: ["Revoke token", "Block source IP"]),
                Playbook(id: "forensics", steps: ["Snapshot workload", "Collect audit logs"]),
            ],
            primaryPager: PagerChannel(channelName: "war-room"),
            secondaryPager: PagerChannel(channelName: "backup-room")
        )

        let orchestrator = IncidentOrchestrator(directory: directory)
        let summary = await orchestrator.createMitigationPlan(for: incident)

        print("Incident response demo")
        print("Incident: \(summary.incidentID)")
        print("Pager: \(summary.pagerChannel)")
        print("Escalation accepted: \(summary.escalationAccepted ? "yes" : "no")")
        print("Responder: \(summary.responderHandle ?? "none")")
        print("Steps executed: \(summary.executedSteps.count)")
    }
}
