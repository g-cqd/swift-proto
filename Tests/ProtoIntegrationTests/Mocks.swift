import Foundation
import Proto

// MARK: - Mock implementations proving protocol conformance works for DI

final class MockUserRepository: UserRepositoryProtocol {
    var savedValues: [(id: String, value: String)] = []
    var deletedIDs: [String] = []
    var fetchResult = "mock-user"

    func fetch(by id: String) async throws -> String {
        fetchResult
    }

    func save(_ value: String, for id: String) async throws {
        savedValues.append((id: id, value: value))
    }

    func delete(by id: String) async throws {
        deletedIDs.append(id)
    }

    func fetchAll() async -> [String] {
        savedValues.map(\.value)
    }
}

@MainActor
final class MockProfileViewModel: ProfileViewModelProtocol {
    var displayName = "Mock"
    var isLoading = false

    func refresh() {
        isLoading = true
    }

    func reset() {
        displayName = ""
        isLoading = false
    }
}

final class MockAPIClient: APIClientProtocol {
    var baseURL = "https://mock.api"
    var lastGetPath: String?
    var lastPostPath: String?

    func get(path: String) async throws -> Data {
        lastGetPath = path
        return Data("mock-response".utf8)
    }

    func post(path: String, body: Data) async throws -> Data {
        lastPostPath = path
        return Data("mock-post-response".utf8)
    }
}

struct MockAppConfig: AppConfigProtocol {
    var apiBaseURL = "https://mock.api"
    var timeout: TimeInterval = 30
    var maxRetries = 3

    func isValid() -> Bool {
        true
    }
}

final class MockLookupTable: LookupTableProtocol {
    private var data: [String: Int] = [:]

    subscript(key: String) -> Int? {
        get { data[key] }
        set { data[key] = newValue }
    }

    func reset() {
        data.removeAll()
    }
}

actor MockSessionStore: SessionStoreProtocol {
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
        "mock-session-store"
    }
}

final class MockDatabaseConnection: DatabaseConnectionProtocol {
    let host: String
    let port: Int
    var executedQueries: [String] = []

    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    func execute(_ query: String) async throws -> [String] {
        executedQueries.append(query)
        return ["row1", "row2"]
    }
}

final class MockOperationPipeline: OperationPipelineProtocol {
    let name: String
    var receivedInputs: [String] = []

    init(name: String) {
        self.name = name
    }

    func run(_ input: String) -> String {
        receivedInputs.append(input)
        return "\(name):\(input)"
    }
}

struct MockFlexibleBox<T: Hashable & Codable>: FlexibleBoxProtocol {
    var value: T
}

final class MockThrowingCounter: ThrowingCounterProtocol {
    var nextValue = 0
    var shouldThrow = false

    func set(_ value: Int) {
        nextValue = value
    }

    var currentValue: Int {
        get throws {
            if shouldThrow {
                throw ValueReadError.negativeValue
            }
            return nextValue
        }
    }
}

public final class MockPublicLogger: PublicLoggerProtocol {
    public var loggedMessages: [String] = []
    public var loggedErrors: [String] = []

    public func log(_ message: String) {
        loggedMessages.append(message)
    }

    public func error(_ message: String) {
        loggedErrors.append(message)
    }
}

// MARK: - Mock conformance for PlaybackState, ModernService, SortedCollection

enum MockPlaybackState: PlaybackStateProtocol {
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
            "mock-stopped"
        case .playing(let rate):
            "mock-playing@\(rate)"
        }
    }
}

@available(macOS 15, iOS 18, *)
final class MockModernService: ModernServiceProtocol {
    var status = "mock-active"

    func performTask() async -> String {
        "mock-done"
    }
}

final class MockSortedCollection<Element: Comparable & Hashable>: SortedCollectionProtocol {
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

final class MockServiceLocator: ServiceLocatorProtocol {
    static var shared: MockServiceLocator {
        MockServiceLocator()
    }

    private nonisolated(unsafe) static var _resetCalled = false
    private static let _resetCalledLock = NSLock()

    static var resetCalled: Bool {
        get {
            _resetCalledLock.lock()
            defer { _resetCalledLock.unlock() }
            return _resetCalled
        }
        set {
            _resetCalledLock.lock()
            _resetCalled = newValue
            _resetCalledLock.unlock()
        }
    }

    static func reset() {
        resetCalled = true
    }

    var resolvedTypes: [String] = []

    func resolve<T>(_ type: T.Type) -> T? {
        resolvedTypes.append(String(describing: type))
        return nil
    }
}
