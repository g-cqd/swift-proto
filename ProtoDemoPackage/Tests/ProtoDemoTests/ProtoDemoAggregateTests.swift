import Foundation
import ProtoAutoOpsDomain
import ProtoDemoDomain
import Testing

@Suite("ProtoDemo package aggregate")
struct ProtoDemoAggregateTests {
    @Test
    private func `budget demo workflow remains usable`() async throws {
        let now = Date()
        let tx = [
            LedgerTransaction(merchant: "Ops", amount: 240, bookedAt: now),
            LedgerTransaction(merchant: "Cloud", amount: 120, bookedAt: now),
        ]

        let coordinator = MonthlyBudgetCoordinator(
            syncService: TransactionsSyncService(seed: tx),
            repository: TransactionRepository(),
            notifier: BudgetNotifier(),
            budgetPlan: BudgetPlan(monthlyLimit: 500, notificationThreshold: 0.7)
        )

        let summary = try await coordinator.runMonthlyCheck(now: now)
        #expect(summary.totalSpent == 360)
    }

    @Test
    private func `auto ops demo workflow remains usable`() async {
        let incident = SecurityIncident(
            id: "INC-200",
            title: "Suspicious admin login",
            severity: .high,
            reportedAt: Date()
        )

        let orchestrator = IncidentOrchestrator(directory: IncidentResourceDirectory())
        let summary = await orchestrator.createMitigationPlan(for: incident)

        #expect(summary.incidentID == "INC-200")
        #expect(!summary.pagerChannel.isEmpty)
    }
}
