import Foundation
import ProtoAutoOpsDomain
import ProtoDemoDomain
import Testing

@Suite("Demo domain coverage gaps")
struct ProtoDemoCoverageGapTests {
    // MARK: - Services.swift (ProtoDemoDomain)

    @Test
    private func `fetchTransactions returns empty when all before date`() async throws {
        let past = Date(timeIntervalSince1970: 0)
        let service = TransactionsSyncService(seed: [
            LedgerTransaction(merchant: "Old", amount: 50, bookedAt: past)
        ])

        let result = try await service.fetchTransactions(since: Date.distantFuture)
        #expect(result.isEmpty)
    }

    @Test
    private func `budget notifier formats message correctly`() async {
        let notifier = BudgetNotifier()
        let snapshot = MonthlySpendingSnapshot(
            monthStart: Date(),
            totalSpent: 123.45,
            limit: 500,
            threshold: 0.8,
            transactionCount: 3
        )

        await notifier.notifyOverspend(snapshot: snapshot)
        #expect(notifier.messages.count == 1)
        #expect(notifier.messages.first == "Budget alert: spent 123.45 of 500.00")
    }

    // MARK: - MonthlyBudgetCoordinator.swift catch branch

    @Test
    private func `sync failure maps to domain error`() async {
        let syncService = TransactionsSyncServiceMock()
        let repository = TransactionRepositoryMock()
        let notifier = BudgetNotifierMock()
        syncService.fetchTransactionsError = SyncTestError.offline

        let coordinator = MonthlyBudgetCoordinator(
            syncService: syncService,
            repository: repository,
            notifier: notifier,
            budgetPlan: BudgetPlan(monthlyLimit: 500, notificationThreshold: 0.8)
        )

        await #expect(throws: BudgetMonitorError.syncFailed("offline")) {
            _ = try await coordinator.runMonthlyCheck(now: Date())
        }
    }

    // MARK: - IncidentOrchestrator.swift nil responder path

    @Test
    private func `orchestrator handles nil escalation responder`() async {
        let directory = IncidentResourceDirectoryMock()
        let incident = SecurityIncident(
            id: "INC-300",
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
    }

    // MARK: - AutoOps Services.swift backupPager property

    @Test
    private func `backup pager returns secondary pager`() {
        let directory = IncidentResourceDirectory(
            secondaryPager: PagerChannel(channelName: "backup-channel")
        )

        let backup = directory.backupPager
        #expect(backup.channelName == "backup-channel")
    }
}

private enum SyncTestError: Error {
    case offline
}
