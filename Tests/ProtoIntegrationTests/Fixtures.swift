import Foundation
import Proto

// MARK: - Repository Pattern (class with CRUD methods)

@Proto
final class UserRepository: UserRepositoryProtocol {
    private var storage: [String: String] = [:]

    func fetch(by id: String) async throws -> String {
        storage[id] ?? ""
    }

    func save(_ value: String, for id: String) async throws {
        storage[id] = value
    }

    func delete(by id: String) async throws {
        storage[id] = nil
    }

    func fetchAll() async -> [String] {
        Array(storage.values)
    }
}

// MARK: - ViewModel with @MainActor

@MainActor
@Proto
final class ProfileViewModel: ProfileViewModelProtocol {
    var displayName = ""
    var isLoading = false

    func refresh() {
        isLoading = true
    }

    func reset() {
        displayName = ""
        isLoading = false
    }
}

// MARK: - Network Service (async throws)

@Proto
final class APIClient: APIClientProtocol {
    let baseURL: String

    init(baseURL: String) {
        self.baseURL = baseURL
    }

    func get(path: String) async throws -> Data {
        Data()
    }

    func post(path: String, body: Data) async throws -> Data {
        Data()
    }

    @ProtoExclude
    func debugLog(_ message: String) {
        print(message)
    }
}

// MARK: - Generic Container with Constraints

@Proto
final class Cache<Key: Hashable, Value>: CacheProtocol {
    private var store: [Key: Value] = [:]

    func get(_ key: Key) -> Value? {
        store[key]
    }

    func set(_ key: Key, value: Value) {
        store[key] = value
    }

    func clear() {
        store.removeAll()
    }
}

// MARK: - Actor-based Concurrent Store

@Proto
actor SessionStore: SessionStoreProtocol {
    var currentToken: String?
    var isAuthenticated: Bool {
        currentToken != nil
    }

    func login(token: String) {
        currentToken = token
    }

    func logout() {
        currentToken = nil
    }

    nonisolated func storeIdentifier() -> String {
        "session-store"
    }
}

// MARK: - Struct Config (value type with properties)

@Proto
struct AppConfig: AppConfigProtocol {
    var apiBaseURL: String
    var timeout: TimeInterval
    var maxRetries: Int

    func isValid() -> Bool {
        !apiBaseURL.isEmpty && timeout > 0 && maxRetries >= 0
    }
}

// MARK: - Generic Type with Where Clause

// Note: Uses extension conformance (`extension SortedCollection: SortedCollectionProtocol {}`)
// because the generated protocol has primary associated types. Both inline conformance
// (`: SortedCollectionProtocol` on the class declaration) and extension conformance are valid.

@Proto(.constrained(.withWhereClause))
final class SortedCollection<Element> where Element: Comparable & Hashable {
    private var items: [Element] = []

    func insert(_ element: Element) {
        items.append(element)
        items.sort()
    }

    func contains(_ element: Element) -> Bool {
        items.contains(element)
    }

    func allItems() -> [Element] {
        items
    }
}

extension SortedCollection: SortedCollectionProtocol {}

// MARK: - Class with @available

@available(macOS 15, iOS 18, *)
@Proto
final class ModernService: ModernServiceProtocol {
    func performTask() async -> String {
        "done"
    }

    var status: String {
        "active"
    }
}

// MARK: - Class with Subscript

@Proto
final class LookupTable: LookupTableProtocol {
    private var data: [String: Int] = [:]

    subscript(key: String) -> Int? {
        get { data[key] }
        set { data[key] = newValue }
    }

    func reset() {
        data.removeAll()
    }
}

// MARK: - Public Class (access level propagation)

@Proto
public final class PublicLogger: PublicLoggerProtocol {
    public func log(_ message: String) {}
    public func error(_ message: String) {}

    func internalDebug(_ message: String) {}
    private func secretTrace(_ message: String) {}
}

// MARK: - Static Members with .include(.static)

@Proto(.include(.static))
final class ServiceLocator: ServiceLocatorProtocol {
    static var shared: ServiceLocator {
        ServiceLocator()
    }

    static func reset() {}

    func resolve<T>(_ type: T.Type) -> T? {
        nil
    }
}

// MARK: - Initializer with .include(.initializer)

@Proto(.include(.initializer))
final class DatabaseConnection: DatabaseConnectionProtocol {
    let host: String
    let port: Int

    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    func execute(_ query: String) async throws -> [String] {
        []
    }
}

// MARK: - Enum support with static + instance API

@Proto(.include(.static))
enum PlaybackState: PlaybackStateProtocol {
    case stopped
    case playing(rate: Double)

    static func playingNormal() -> Self {
        .playing(rate: 1.0)
    }

    var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }

    func descriptionText() -> String {
        switch self {
        case .stopped:
            "stopped"
        case .playing(let rate):
            "playing@\(rate)"
        }
    }
}

// MARK: - Mixed include/exclude selection

@Proto(.exclude(.members), .include(.methods), .include(.initializer))
final class OperationPipeline: OperationPipelineProtocol {
    let name: String
    var stepCount = 0

    init(name: String) {
        self.name = name
    }

    func run(_ input: String) -> String {
        stepCount += 1
        return "\(name):\(input)"
    }

    subscript(offset: Int) -> Int {
        stepCount + offset
    }
}

// MARK: - Generic constrained protocol without where clause

// Note: Uses extension conformance for the same reason as SortedCollection above.

@Proto(.constrained)
final class FlexibleBox<T> where T: Hashable & Codable {
    var value: T

    init(value: T) {
        self.value = value
    }
}

extension FlexibleBox: FlexibleBoxProtocol {}

// MARK: - Throwing property getter via @ProtoMember

enum ValueReadError: Error {
    case negativeValue
}

@Proto
final class ThrowingCounter: ThrowingCounterProtocol {
    private var storage = 0

    func set(_ value: Int) {
        storage = value
    }

    @ProtoMember(.throws) var currentValue: Int {
        get throws {
            if storage < 0 {
                throw ValueReadError.negativeValue
            }
            return storage
        }
    }
}

// MARK: - Generated mock via .mock

enum BillingError: Error {
    case offline
}

@Proto(.mock)
final class BillingService: BillingServiceProtocol {
    func charge(cents: Int) async throws -> String {
        "charged-\\(cents)"
    }

    @ProtoMockIgnored
    func debugState() -> String {
        "ok"
    }
}

@Proto(.mock(.expr("DEBUG && canImport(Foundation)")))
final class ConditionalBillingService: ConditionalBillingServiceProtocol {
    func ping(_ value: Int) -> Int {
        value + 1
    }
}

@Proto(.mock, .conforms(to: Sendable.self))
final class ConcurrentBillingService: ConcurrentBillingServiceProtocol {
    func charge(cents: Int) -> Int {
        cents
    }
}

@Proto(.mock, .conforms(to: Sendable.self))
final class ConcurrentThrowingBillingService: ConcurrentThrowingBillingServiceProtocol {
    func charge(cents: Int) throws -> Int {
        cents
    }
}

// MARK: - Generated mock via .mock(.auto)

@Proto(.mock)
final class BillingAccount: BillingAccountProtocol {
    var identifier: String {
        "account"
    }
}

@Proto(.mock(.auto))
final class AutoDefaultBillingService: AutoDefaultBillingServiceProtocol {
    func primaryAccount() -> BillingAccountProtocol {
        BillingAccount()
    }

    func optionalAccount() -> BillingAccountProtocol? {
        nil
    }

    func allAccounts() -> [BillingAccountProtocol] {
        []
    }

    var currentAccount: BillingAccountProtocol {
        BillingAccount()
    }

    subscript(index: Int) -> BillingAccountProtocol {
        BillingAccount()
    }
}
