import Foundation
import Proto

@Proto(.mock(.auto))
public final class TransactionsSyncService: TransactionsSyncServiceProtocol {
    private let seed: [LedgerTransaction]

    public init(seed: [LedgerTransaction] = []) {
        self.seed = seed
    }

    public func fetchTransactions(since date: Date) async throws -> [LedgerTransaction] {
        seed.filter { $0.bookedAt >= date }
    }
}

@Proto(.mock(.auto))
public final class TransactionRepository: TransactionRepositoryProtocol {
    private var storage: [LedgerTransaction]

    public init(storage: [LedgerTransaction] = []) {
        self.storage = storage
    }

    public func save(_ transactions: [LedgerTransaction]) async {
        storage = transactions
    }

    public func loadCurrentMonth() async -> [LedgerTransaction] {
        storage
    }
}

@Proto(.mock(.auto))
public final class BudgetNotifier: BudgetNotifierProtocol {
    public private(set) var messages: [String] = []

    public init() {}

    public func notifyOverspend(snapshot: MonthlySpendingSnapshot) async {
        let message = String(
            format: "Budget alert: spent %.2f of %.2f",
            snapshot.totalSpent,
            snapshot.limit
        )
        messages.append(message)
    }
}
