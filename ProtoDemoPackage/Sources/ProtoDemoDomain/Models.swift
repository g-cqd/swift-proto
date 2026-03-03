import Foundation

public struct BudgetPlan: Sendable, Equatable {
    public let monthlyLimit: Double
    public let notificationThreshold: Double

    public init(monthlyLimit: Double, notificationThreshold: Double) {
        self.monthlyLimit = monthlyLimit
        self.notificationThreshold = notificationThreshold
    }
}

public struct LedgerTransaction: Sendable, Equatable {
    public let id: UUID
    public let merchant: String
    public let amount: Double
    public let bookedAt: Date

    public init(merchant: String, amount: Double, bookedAt: Date, id: UUID = UUID()) {
        self.merchant = merchant
        self.amount = amount
        self.bookedAt = bookedAt
        self.id = id
    }
}

public struct MonthlySpendingSnapshot: Sendable, Equatable {
    public let monthStart: Date
    public let totalSpent: Double
    public let limit: Double
    public let threshold: Double
    public let transactionCount: Int

    public init(
        monthStart: Date,
        totalSpent: Double,
        limit: Double,
        threshold: Double,
        transactionCount: Int
    ) {
        self.monthStart = monthStart
        self.totalSpent = totalSpent
        self.limit = limit
        self.threshold = threshold
        self.transactionCount = transactionCount
    }

    public var shouldNotify: Bool {
        guard limit > 0 else { return false }
        return totalSpent >= (limit * threshold)
    }
}

public enum BudgetMonitorError: Error, Equatable {
    case syncFailed(String)
}
