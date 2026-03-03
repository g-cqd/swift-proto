import Foundation
import Proto

@Proto
public final class MonthlyBudgetCoordinator: MonthlyBudgetCoordinatorProtocol {
    private let syncService: any TransactionsSyncServiceProtocol
    private let repository: any TransactionRepositoryProtocol
    private let notifier: any BudgetNotifierProtocol
    private let budgetPlan: BudgetPlan
    private let calendar: Calendar

    public init(
        syncService: any TransactionsSyncServiceProtocol,
        repository: any TransactionRepositoryProtocol,
        notifier: any BudgetNotifierProtocol,
        budgetPlan: BudgetPlan,
        calendar: Calendar = .current
    ) {
        self.syncService = syncService
        self.repository = repository
        self.notifier = notifier
        self.budgetPlan = budgetPlan
        self.calendar = calendar
    }

    public func runMonthlyCheck(now: Date = Date()) async throws -> MonthlySpendingSnapshot {
        let monthStart = resolveMonthStart(for: now)

        let fetchedTransactions: [LedgerTransaction]
        do {
            fetchedTransactions = try await syncService.fetchTransactions(since: monthStart)
        } catch {
            throw BudgetMonitorError.syncFailed(String(describing: error))
        }

        await repository.save(fetchedTransactions)
        let monthTransactions = await repository.loadCurrentMonth()
        let totalSpent = monthTransactions.reduce(0) { partialResult, transaction in
            partialResult + transaction.amount
        }

        let snapshot = MonthlySpendingSnapshot(
            monthStart: monthStart,
            totalSpent: totalSpent,
            limit: budgetPlan.monthlyLimit,
            threshold: budgetPlan.notificationThreshold,
            transactionCount: monthTransactions.count
        )

        if snapshot.shouldNotify {
            await notifier.notifyOverspend(snapshot: snapshot)
        }

        return snapshot
    }

    private func resolveMonthStart(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
}
