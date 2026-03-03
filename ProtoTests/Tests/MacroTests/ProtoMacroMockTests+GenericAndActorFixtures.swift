extension ProtoMacroMockTests {
    enum GenericAndActorFixture {}
}

// MARK: - Generic class mock

extension ProtoMacroMockTests.GenericAndActorFixture {
    static let genericClassInput = """
        @Proto(.mock)
        final class Box<T> {
            func store(item: T) {
            }

            func retrieve() -> T {
                preconditionFailure()
            }
        }
        """

    static let genericClassExpanded = """
        final class Box<T> {
            func store(item: T) {
            }

            func retrieve() -> T {
                preconditionFailure()
            }
        }

        protocol BoxProtocol {
            associatedtype T
            func store(item: T)
            func retrieve() -> T
        }

        final class BoxMock<T> : BoxProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var storeCallCount = 0
            private(set) var storeReceivedArguments: [T] = []
            var storeHandler: ((T) -> Void)?
            private(set) var retrieveCallCount = 0
            var retrieveHandler: (() -> T)?
            private var retrieveReturnStub: ProtoMockReturnStub<T> = .unset
            func retrieveSetReturnValue(_ value: T) {
                retrieveReturnStub = .value(value)
            }

            init(
                storeHandler: ((T) -> Void)? = nil,
                retrieveHandler: (() -> T)? = nil,
                retrieveReturnValue: T? = nil
            ) {
                self.storeHandler = storeHandler
                self.retrieveHandler = retrieveHandler
                if let retrieveReturnValue {
                    retrieveReturnStub = .value(retrieveReturnValue)
                }
            }

            func store(item: T) {
                storeCallCount += 1
                storeReceivedArguments.append(item)
                if let handler = storeHandler {
                    handler(item)
                    return
                }
            }
            func retrieve() -> T {
                retrieveCallCount += 1
                if let handler = retrieveHandler {
                    return handler()
                }
                if case .value(let value) = retrieveReturnStub {
                    return value
                }
                ProtoMockFailureHandling.fail("Unstubbed call to retrieve on BoxMock")
            }
        }
        """
}

// MARK: - Actor mock

extension ProtoMacroMockTests.GenericAndActorFixture {
    static let actorMockInput = """
        @Proto(.mock)
        actor Cache {
            func get(key: String) -> String? {
                nil
            }

            func set(key: String, value: String) {
            }
        }
        """

    static let actorMockExpanded = """
        actor Cache {
            func get(key: String) -> String? {
                nil
            }

            func set(key: String, value: String) {
            }
        }

        protocol CacheProtocol: Actor {
            func get(key: String) async -> String?
            func set(key: String, value: String) async
        }

        actor CacheMock: CacheProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var getCallCount = 0
            private(set) var getReceivedArguments: [String] = []
            var getHandler: ((String) async -> String?)?
            private var getReturnStub: ProtoMockReturnStub<String?> = .unset
            func getSetReturnValue(_ value: String?) {
                getReturnStub = .value(value)
            }
            private(set) var setCallCount = 0
            private(set) var setReceivedArguments: [(String, String)] = []
            var setHandler: ((String, String) async -> Void)?

            init(
                getHandler: ((String) async -> String?)? = nil,
                getReturnValue: String?? = nil,
                setHandler: ((String, String) async -> Void)? = nil
            ) {
                self.getHandler = getHandler
                if let getReturnValue {
                    getReturnStub = .value(getReturnValue)
                }
                self.setHandler = setHandler
            }

            func get(key: String) async -> String? {
                getCallCount += 1
                getReceivedArguments.append(key)
                if let handler = getHandler {
                    return await handler(key)
                }
                if case .value(let value) = getReturnStub {
                    return value
                }
                ProtoMockFailureHandling.fail("Unstubbed call to get on CacheMock")
            }
            func set(key: String, value: String) async {
                setCallCount += 1
                setReceivedArguments.append((key, value))
                if let handler = setHandler {
                    await handler(key, value)
                    return
                }
            }
        }
        """
}

// MARK: - Mock + constrained

extension ProtoMacroMockTests.GenericAndActorFixture {
    static let mockConstrainedInput = """
        @Proto(.mock, .constrained)
        final class Repository<Entity> {
            func save(entity: Entity) {
            }

            func findAll() -> [Entity] {
                []
            }
        }
        """

    static let mockConstrainedExpanded = """
        final class Repository<Entity> {
            func save(entity: Entity) {
            }

            func findAll() -> [Entity] {
                []
            }
        }

        protocol RepositoryProtocol<Entity> {
            associatedtype Entity
            func save(entity: Entity)
            func findAll() -> [Entity]
        }

        final class RepositoryMock<Entity> : RepositoryProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var saveCallCount = 0
            private(set) var saveReceivedArguments: [Entity] = []
            var saveHandler: ((Entity) -> Void)?
            private(set) var findAllCallCount = 0
            var findAllHandler: (() -> [Entity])?
            private var findAllReturnStub: ProtoMockReturnStub<[Entity]> = .unset
            func findAllSetReturnValue(_ value: [Entity]) {
                findAllReturnStub = .value(value)
            }

            init(
                saveHandler: ((Entity) -> Void)? = nil,
                findAllHandler: (() -> [Entity])? = nil,
                findAllReturnValue: [Entity]? = nil
            ) {
                self.saveHandler = saveHandler
                self.findAllHandler = findAllHandler
                if let findAllReturnValue {
                    findAllReturnStub = .value(findAllReturnValue)
                }
            }

            func save(entity: Entity) {
                saveCallCount += 1
                saveReceivedArguments.append(entity)
                if let handler = saveHandler {
                    handler(entity)
                    return
                }
            }
            func findAll() -> [Entity] {
                findAllCallCount += 1
                if let handler = findAllHandler {
                    return handler()
                }
                if case .value(let value) = findAllReturnStub {
                    return value
                }
                ProtoMockFailureHandling.fail("Unstubbed call to findAll on RepositoryMock")
            }
        }
        """
}

// MARK: - Mock + conforms(to:)

extension ProtoMacroMockTests.GenericAndActorFixture {
    static let mockConformsInput = """
        @Proto(.mock, .conforms(to: Sendable.self, Identifiable.self))
        final class Gateway {
            func send(data: String) async throws {
            }
        }
        """

    static let mockConformsExpanded = """
        final class Gateway {
            func send(data: String) async throws {
            }
        }

        protocol GatewayProtocol: Sendable, Identifiable {
            func send(data: String) async throws
        }

        final class GatewayMock: @unchecked Sendable, GatewayProtocol {
            private let _protoMockLock = ProtoMockSynchronizationLock()

            var sendCallCount: Int {
                _protoMockLock.withLock {
                    _sendCallCount
                }
            }
            private var _sendCallCount = 0
            var sendReceivedArguments: [String] {
                _protoMockLock.withLock {
                    _sendReceivedArguments
                }
            }
            private var _sendReceivedArguments: [String] = []
            var sendHandler: ((String) async throws -> Void)? {
                get {
                    _protoMockLock.withLock {
                        _sendHandler
                    }
                }
                set {
                    _protoMockLock.withLock {
                        _sendHandler = newValue
                    }
                }
            }
            private var _sendHandler: ((String) async throws -> Void)?
            var sendError: (any Error)? {
                get {
                    _protoMockLock.withLock {
                        _sendError
                    }
                }
                set {
                    _protoMockLock.withLock {
                        _sendError = newValue
                    }
                }
            }
            private var _sendError: (any Error)?

            init(
                sendHandler: ((String) async throws -> Void)? = nil,
                sendError: (any Error)? = nil
            ) {
                self.sendHandler = sendHandler
                self.sendError = sendError
            }

            func send(data: String) async throws {
                _protoMockLock.withLock {
                    _sendCallCount += 1
                }
                _protoMockLock.withLock {
                    _sendReceivedArguments.append(data)
                }
                let handler = _protoMockLock.withLock {
                    _sendHandler
                }
                if let handler = handler {
                    try await handler(data)
                    return
                }
                let error = _protoMockLock.withLock {
                    _sendError
                }
                if let error {
                    throw error
                }
            }
        }
        """
}
