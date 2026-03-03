import Foundation
import ProtoAutoOpsDomain
import Testing

@Suite("Incident auto-default mocking")
struct IncidentOrchestratorTests {
    @Test
    private func `auto-default mock returns protocol-shaped defaults when unstubbed`() {
        let directory = IncidentResourceDirectoryMock()

        let responder = directory.escalationResponder()
        let playbooks = directory.activePlaybooks()
        let pager = directory.defaultPager()
        let backupPager = directory.backupPager

        #expect(responder is ResponderMock)
        #expect(playbooks.count == 1)
        #expect(playbooks.first is PlaybookMock)
        #expect(pager is PagerChannelMock)
        #expect(backupPager is PagerChannelMock)
    }

    @Test
    private func `explicit stubs override auto defaults`() {
        final class ManualResponder: ResponderProtocol {
            let handle = "manual-override"

            func acknowledge(incidentID: String) async -> Bool {
                true
            }
        }

        let directory = IncidentResourceDirectoryMock()
        directory.escalationResponderSetReturnValue(ManualResponder())

        let responder = directory.escalationResponder()
        #expect(responder is ManualResponder)
    }

    @Test
    private func `orchestrator composes mitigation summary from directory resources`() async {
        let directory = IncidentResourceDirectoryMock()
        let incident = SecurityIncident(
            id: "INC-100",
            title: "Privilege escalation attempt",
            severity: .high,
            reportedAt: Date()
        )

        directory.defaultPagerSetReturnValue(PagerChannel(channelName: "war-room"))
        directory.activePlaybooksSetReturnValue([
            Playbook(id: "containment", steps: ["Isolate host", "Rotate credentials"])
        ])
        directory.escalationResponderSetReturnValue(Responder(handle: "sec-oncall"))

        let orchestrator = IncidentOrchestrator(directory: directory)
        let summary = await orchestrator.createMitigationPlan(for: incident)

        #expect(summary.incidentID == "INC-100")
        #expect(summary.pagerChannel == "war-room")
        #expect(summary.escalationAccepted)
        #expect(summary.executedSteps == ["Isolate host", "Rotate credentials"])
        #expect(summary.responderHandle == "sec-oncall")

        #expect(directory.defaultPagerCallCount == 1)
        #expect(directory.activePlaybooksCallCount == 1)
        #expect(directory.escalationResponderCallCount == 1)
    }

    @Test
    private func `orchestrator handles nil escalation responder`() async {
        let directory = IncidentResourceDirectoryMock()
        let incident = SecurityIncident(
            id: "INC-200",
            title: "Brute force login",
            severity: .medium,
            reportedAt: Date()
        )

        directory.defaultPagerSetReturnValue(PagerChannel(channelName: "alerts"))
        directory.activePlaybooksSetReturnValue([])
        directory.escalationResponderSetReturnValue(nil)

        let orchestrator = IncidentOrchestrator(directory: directory)
        let summary = await orchestrator.createMitigationPlan(for: incident)

        #expect(!summary.escalationAccepted)
        #expect(summary.responderHandle == nil)
        #expect(summary.incidentID == "INC-200")
        #expect(summary.pagerChannel == "alerts")
        #expect(summary.executedSteps.isEmpty)
    }
}
