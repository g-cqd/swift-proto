import Foundation
import Proto
import Testing

@Suite("Real-type conformance")
struct ConformanceTests {
    @Test
    private func `repository CRUD via protocol`() async throws {
        let repo: any UserRepositoryProtocol = UserRepository()
        try await repo.save("Alice", for: "1")
        let result = try await repo.fetch(by: "1")
        #expect(result == "Alice")
        let all = await repo.fetchAll()
        #expect(all.contains("Alice"))
    }

    @Test
    @MainActor
    private func `viewModel properties and actions via protocol`() {
        var vm: any ProfileViewModelProtocol = ProfileViewModel()
        vm.displayName = "Bob"
        #expect(vm.displayName == "Bob")
        vm.refresh()
        #expect(vm.isLoading)
        vm.reset()
        #expect(vm.displayName.isEmpty)
        #expect(!vm.isLoading)
    }

    @Test
    private func `API client async requests via protocol`() async throws {
        let client: any APIClientProtocol = APIClient(baseURL: "https://api.example.com")
        #expect(client.baseURL == "https://api.example.com")
        _ = try await client.get(path: "/users")
        _ = try await client.post(path: "/users", body: Data())
    }

    @Test
    private func `generic cache get/set/clear via protocol`() {
        let cache = Cache<String, Int>()
        cache.set("a", value: 42)
        #expect(cache.get("a") == 42)
        cache.clear()
        #expect(cache.get("a") == nil)
    }

    @Test
    private func `actor session store login/logout via protocol`() async {
        let store: any SessionStoreProtocol = SessionStore()
        #expect(await store.currentToken == nil)
        #expect(await store.isAuthenticated == false)
        await store.login(token: "abc123")
        #expect(await store.currentToken == "abc123")
        #expect(await store.isAuthenticated == true)
        await store.logout()
        #expect(await store.currentToken == nil)
    }

    @Test
    private func `actor nonisolated method via protocol`() {
        let store = SessionStore()
        #expect(store.storeIdentifier() == "session-store")
    }

    @Test
    private func `struct config validation via protocol`() {
        var config: any AppConfigProtocol = AppConfig(
            apiBaseURL: "https://api.example.com",
            timeout: 30,
            maxRetries: 3
        )
        #expect(config.isValid())
        config.apiBaseURL = ""
        #expect(!config.isValid())
    }

    @Test
    private func `generic where-clause sorted collection via protocol`() {
        let collection: some SortedCollectionProtocol<Int> = SortedCollection<Int>()
        collection.insert(3)
        collection.insert(1)
        collection.insert(2)
        #expect(collection.allItems() == [1, 2, 3])
        #expect(collection.contains(2))
        #expect(!collection.contains(99))
    }

    @Test
    private func `subscript access via protocol`() {
        var table: some LookupTableProtocol = LookupTable()
        table["x"] = 10
        #expect(table["x"] == 10)
        table.reset()
        #expect(table["x"] == nil)
    }

    @Test
    private func `static members via protocol`() {
        _ = ServiceLocator.shared
        ServiceLocator.reset()
        let locator = ServiceLocator()
        let resolved: Int? = locator.resolve(Int.self)
        #expect(resolved == nil)
    }

    @Test
    private func `initializer requirement via protocol`() async throws {
        let conn: any DatabaseConnectionProtocol = DatabaseConnection(host: "localhost", port: 5432)
        #expect(conn.host == "localhost")
        #expect(conn.port == 5432)
        let rows = try await conn.execute("SELECT 1")
        #expect(rows.isEmpty)
    }

    @available(macOS 15, iOS 18, *)
    @Test
    private func `@available attribute preserved via protocol`() async {
        let service: any ModernServiceProtocol = ModernService()
        let result = await service.performTask()
        #expect(result == "done")
        #expect(service.status == "active")
    }

    @Test
    private func `enum with static and instance members via protocol`() {
        let state: any PlaybackStateProtocol = PlaybackState.playing(rate: 1.5)
        #expect(state.isPlaying)
        #expect(state.descriptionText() == "playing@1.5")
        #expect(PlaybackState.playingNormal().descriptionText() == "playing@1.0")
    }

    @Test
    private func `mixed include/exclude selection via protocol`() {
        let pipeline: any OperationPipelineProtocol = OperationPipeline(name: "pipe")
        let output = pipeline.run("in")
        #expect(output == "pipe:in")
    }

    @Test
    private func `constrained generic without where clause via protocol`() {
        var box: some FlexibleBoxProtocol<Int> = FlexibleBox(value: 42)
        #expect(box.value == 42)
        box.value = 99
        #expect(box.value == 99)
    }

    @Test
    private func `throwing property getter via protocol`() throws {
        let counter: any ThrowingCounterProtocol = ThrowingCounter()
        counter.set(5)
        #expect(try counter.currentValue == 5)

        counter.set(-1)
        #expect(throws: ValueReadError.negativeValue) {
            _ = try counter.currentValue
        }
    }
}

@Suite("Mock DI conformance")
struct MockTests {
    @Test
    private func `mock repository tracks saves and deletes`() async throws {
        let mock = MockUserRepository()
        mock.fetchResult = "mock-alice"

        let repo: any UserRepositoryProtocol = mock
        let result = try await repo.fetch(by: "1")
        #expect(result == "mock-alice")

        try await repo.save("Bob", for: "2")
        #expect(mock.savedValues.count == 1)
        #expect(mock.savedValues.first?.value == "Bob")

        try await repo.delete(by: "3")
        #expect(mock.deletedIDs == ["3"])
    }

    @Test
    @MainActor
    private func `mock view model conforms on MainActor`() {
        let mock: any ProfileViewModelProtocol = MockProfileViewModel()
        #expect(mock.displayName == "Mock")
        mock.refresh()
        #expect(mock.isLoading)
    }

    @Test
    private func `mock API client returns canned responses`() async throws {
        let mock = MockAPIClient()
        let client: any APIClientProtocol = mock

        let data = try await client.get(path: "/test")
        #expect(String(data: data, encoding: .utf8) == "mock-response")
        #expect(mock.lastGetPath == "/test")
    }

    @Test
    private func `mock config provides default valid values`() {
        let config: any AppConfigProtocol = MockAppConfig()
        #expect(config.isValid())
        #expect(config.timeout == 30)
    }

    @Test
    private func `mock lookup table subscript access`() {
        var table: any LookupTableProtocol = MockLookupTable()
        table["key"] = 99
        #expect(table["key"] == 99)
    }

    @Test
    private func `mock session store actor conformance`() async {
        let store: any SessionStoreProtocol = MockSessionStore()
        await store.login(token: "mock-token")
        #expect(await store.currentToken == "mock-token")
        #expect(store.storeIdentifier() == "mock-session-store")
    }

    @Test
    private func `mock database connection tracks queries`() async throws {
        let mock = MockDatabaseConnection(host: "test", port: 1234)
        let conn: any DatabaseConnectionProtocol = mock

        #expect(conn.host == "test")
        let rows = try await conn.execute("SELECT *")
        #expect(rows == ["row1", "row2"])
        #expect(mock.executedQueries == ["SELECT *"])
    }

    @Test
    private func `mock operation pipeline records inputs`() {
        let mock = MockOperationPipeline(name: "mock")
        let pipeline: any OperationPipelineProtocol = mock
        let output = pipeline.run("payload")
        #expect(output == "mock:payload")
        #expect(mock.receivedInputs == ["payload"])
    }

    @Test
    private func `mock flexible box generic value storage`() {
        var box: some FlexibleBoxProtocol<String> = MockFlexibleBox(value: "a")
        #expect(box.value == "a")
        box.value = "b"
        #expect(box.value == "b")
    }

    @Test
    private func `mock throwing counter controls error behavior`() throws {
        let mock = MockThrowingCounter()
        let counter: any ThrowingCounterProtocol = mock

        counter.set(7)
        #expect(try counter.currentValue == 7)

        mock.shouldThrow = true
        #expect(throws: ValueReadError.negativeValue) {
            _ = try counter.currentValue
        }
    }

    @Test
    private func `public logger mock tracks messages`() {
        let mock = MockPublicLogger()
        let logger: any PublicLoggerProtocol = mock
        logger.log("info message")
        logger.error("error message")
        #expect(mock.loggedMessages == ["info message"])
        #expect(mock.loggedErrors == ["error message"])
    }

    @Test
    private func `service locator mock resolves types`() {
        let mock = MockServiceLocator()
        let locator: any ServiceLocatorProtocol = mock
        let resolved: Int? = locator.resolve(Int.self)
        #expect(resolved == nil)
        #expect(mock.resolvedTypes == ["Int"])
    }

    @Test
    private func `mock playback state conforms to protocol`() {
        let state: any PlaybackStateProtocol = MockPlaybackState.playing(rate: 2.0)
        #expect(state.isPlaying)
        #expect(state.descriptionText() == "mock-playing@2.0")
        #expect(MockPlaybackState.playingNormal().descriptionText() == "mock-playing@1.0")
    }

    @available(macOS 15, iOS 18, *)
    @Test
    private func `mock modern service conforms to protocol`() async {
        let service: any ModernServiceProtocol = MockModernService()
        let result = await service.performTask()
        #expect(result == "mock-done")
        #expect(service.status == "mock-active")
    }

    @Test
    private func `mock sorted collection conforms to protocol`() {
        let collection: some SortedCollectionProtocol<Int> = MockSortedCollection<Int>()
        collection.insert(3)
        collection.insert(1)
        #expect(collection.allItems() == [1, 3])
        #expect(collection.contains(1))
        #expect(!collection.contains(99))
    }

    @Test
    private func `generated proto mock supports stubbing and call tracking`() async throws {
        let mock = BillingServiceMock()
        mock.chargeSetReturnValue("stubbed")

        let service: any BillingServiceProtocol = mock
        let result = try await service.charge(cents: 199)

        #expect(result == "stubbed")
        #expect(mock.chargeCallCount == 1)
        #expect(mock.chargeReceivedArguments == [199])
    }

    #if DEBUG && canImport(Foundation)
    @Test
    private func `expr-conditional generated mock supports stubbing and call tracking`() {
        let mock = ConditionalBillingServiceMock()
        mock.pingSetReturnValue(77)

        let service: any ConditionalBillingServiceProtocol = mock
        let result = service.ping(1)

        #expect(result == 77)
        #expect(mock.pingCallCount == 1)
        #expect(mock.pingReceivedArguments == [1])
    }
    #endif

    @Test
    private func `sendable generated mock stays deterministic under concurrent access`() async {
        let mock = ConcurrentBillingServiceMock()
        let callCount = 1000
        mock.chargeSetReturnValue(0)

        await withTaskGroup(of: Void.self) { group in
            for value in 0..<callCount {
                group.addTask {
                    _ = mock.charge(cents: value)
                }
            }
        }

        #expect(mock.chargeCallCount == callCount)
        #expect(mock.chargeReceivedArguments.count == callCount)
        #expect(Set(mock.chargeReceivedArguments) == Set(0..<callCount))
    }

    @Test
    private func `sendable throwing generated mock supports synchronized error and return stubs`() throws {
        let mock = ConcurrentThrowingBillingServiceMock()
        mock.chargeSetReturnValue(42)

        #expect(try mock.charge(cents: 10) == 42)

        mock.chargeError = BillingError.offline
        #expect(throws: (any Error).self) {
            _ = try mock.charge(cents: 11)
        }
    }

    @Test
    private func `synchronization lock protects shared mutable state in concurrent tasks`() async {
        final class SharedCounter: @unchecked Sendable {
            var value = 0
        }

        let lock = ProtoMockSynchronizationLock()
        let counter = SharedCounter()
        let iterations = 1000

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    lock.withLock {
                        counter.value += 1
                    }
                }
            }
        }

        #expect(counter.value == iterations)
    }
}
