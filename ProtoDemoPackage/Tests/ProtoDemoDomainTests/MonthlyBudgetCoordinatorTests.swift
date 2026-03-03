import Foundation
import ProtoDemoDomain
import Testing

@Suite("Monthly budget monitoring with Proto-generated mocks")
struct MonthlyBudgetCoordinatorTests {
    @Test
    private func `notifies when spending crosses threshold`() async throws {
        let transactions = [
            LedgerTransaction(merchant: "Rent", amount: 420, bookedAt: Date()),
            LedgerTransaction(merchant: "Groceries", amount: 130, bookedAt: Date()),
        ]
        let syncService = TransactionsSyncServiceMock()
        let repository = TransactionRepositoryMock()
        let notifier = BudgetNotifierMock()
        syncService.fetchTransactionsSetReturnValue(transactions)
        repository.loadCurrentMonthSetReturnValue(transactions)

        let coordinator = MonthlyBudgetCoordinator(
            syncService: syncService,
            repository: repository,
            notifier: notifier,
            budgetPlan: BudgetPlan(monthlyLimit: 600, notificationThreshold: 0.9)
        )

        let snapshot = try await coordinator.runMonthlyCheck(now: Date())

        #expect(snapshot.totalSpent == 550)
        #expect(snapshot.shouldNotify)
        #expect(syncService.fetchTransactionsCallCount == 1)
        #expect(repository.saveCallCount == 1)
        #expect(repository.loadCurrentMonthCallCount == 1)
        #expect(notifier.notifyOverspendCallCount == 1)
    }

    @Test
    private func `does not notify when spending is below threshold`() async throws {
        let transactions = [
            LedgerTransaction(merchant: "Internet", amount: 40, bookedAt: Date()),
            LedgerTransaction(merchant: "Coffee", amount: 20, bookedAt: Date()),
        ]
        let syncService = TransactionsSyncServiceMock()
        let repository = TransactionRepositoryMock()
        let notifier = BudgetNotifierMock()
        syncService.fetchTransactionsSetReturnValue(transactions)
        repository.loadCurrentMonthSetReturnValue(transactions)

        let coordinator = MonthlyBudgetCoordinator(
            syncService: syncService,
            repository: repository,
            notifier: notifier,
            budgetPlan: BudgetPlan(monthlyLimit: 500, notificationThreshold: 0.8)
        )

        let snapshot = try await coordinator.runMonthlyCheck(now: Date())

        #expect(snapshot.totalSpent == 60)
        #expect(!snapshot.shouldNotify)
        #expect(notifier.notifyOverspendCallCount == 0)
    }

    @Test
    private func `sync failures are mapped to domain error`() async {
        let syncService = TransactionsSyncServiceMock()
        let repository = TransactionRepositoryMock()
        let notifier = BudgetNotifierMock()
        syncService.fetchTransactionsError = DemoSyncError.offline

        let coordinator = MonthlyBudgetCoordinator(
            syncService: syncService,
            repository: repository,
            notifier: notifier,
            budgetPlan: BudgetPlan(monthlyLimit: 500, notificationThreshold: 0.8)
        )

        await #expect(throws: BudgetMonitorError.syncFailed("offline")) {
            _ = try await coordinator.runMonthlyCheck(now: Date())
        }

        #expect(repository.saveCallCount == 0)
        #expect(repository.loadCurrentMonthCallCount == 0)
        #expect(notifier.notifyOverspendCallCount == 0)
    }

    // MARK: - Real service coverage (Services.swift)

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
}

private enum DemoSyncError: Error {
    case offline
}
