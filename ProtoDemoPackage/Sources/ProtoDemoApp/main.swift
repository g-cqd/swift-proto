import Foundation
import ProtoDemoDomain

@main
enum ProtoDemoApp {
    static func main() async {
        let now = Date()
        let transactions = demoTransactions(reference: now)

        let syncService = TransactionsSyncService(seed: transactions)
        let repository = TransactionRepository()
        let notifier = BudgetNotifier()
        let coordinator = MonthlyBudgetCoordinator(
            syncService: syncService,
            repository: repository,
            notifier: notifier,
            budgetPlan: BudgetPlan(monthlyLimit: 500, notificationThreshold: 0.8)
        )

        do {
            let snapshot = try await coordinator.runMonthlyCheck(now: now)
            print("Monthly budget monitor")
            print("Transactions: \(snapshot.transactionCount)")
            print("Spent: \(String(format: "%.2f", snapshot.totalSpent))")
            print("Limit: \(String(format: "%.2f", snapshot.limit))")
            print("Threshold: \(Int(snapshot.threshold * 100))%")
            print("Notification needed: \(snapshot.shouldNotify ? "yes" : "no")")
        } catch {
            print("Budget monitor failed: \(error)")
        }
    }

    private static func demoTransactions(reference: Date) -> [LedgerTransaction] {
        let calendar = Calendar(identifier: .gregorian)
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: reference)) ?? reference
        return [
            LedgerTransaction(
                merchant: "Grocery Store",
                amount: 138.60,
                bookedAt: calendar.date(byAdding: .day, value: 2, to: monthStart) ?? monthStart
            ),
            LedgerTransaction(
                merchant: "Train Pass",
                amount: 74.00,
                bookedAt: calendar.date(byAdding: .day, value: 5, to: monthStart) ?? monthStart
            ),
            LedgerTransaction(
                merchant: "Utilities",
                amount: 215.30,
                bookedAt: calendar.date(byAdding: .day, value: 8, to: monthStart) ?? monthStart
            ),
        ]
    }
}
