extension ProtoMacroMockTests.AutoDefaultFixture {
    // MARK: - Initializer: init(...) → empty body (no fail)

    static let initializerInput = """
        @Proto(.mock(.auto), .include(.initializer))
        final class Service {
            init(name: String) {
            }

            func fetch() -> String {
                ""
            }
        }
        """

    static let initializerExpanded = """
        final class Service {
            init(name: String) {
            }

            func fetch() -> String {
                ""
            }
        }

        protocol ServiceProtocol: Proto.Metatype {
            init(name: String)
            func fetch() -> String
        }

        final class ServiceMock: ServiceProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var fetchCallCount = 0
            var fetchHandler: (() -> String)?
            private var fetchReturnStub: ProtoMockReturnStub<String> = .unset
            func fetchSetReturnValue(_ value: String) {
                fetchReturnStub = .value(value)
            }

            init(
                fetchHandler: (() -> String)? = nil,
                fetchReturnValue: String? = nil
            ) {
                self.fetchHandler = fetchHandler
                if let fetchReturnValue {
                    fetchReturnStub = .value(fetchReturnValue)
                }
            }

            init(name: String) {
            }
            func fetch() -> String {
                fetchCallCount += 1
                if let handler = fetchHandler {
                    return handler()
                }
                if case .value(let value) = fetchReturnStub {
                    return value
                }
                ProtoMockFailureHandling.fail("Unstubbed call to fetch on ServiceMock")
            }
        }
        """

    // MARK: - Combined: .mock(.auto, .debug) → #if DEBUG + auto-defaults

    static let combinedDebugInput = """
        @Proto(.mock(.auto, .debug))
        final class Service {
            func fetch() -> UserProtocol {
                fatalError()
            }
        }
        """

    static let combinedDebugExpanded = """
        final class Service {
            func fetch() -> UserProtocol {
                fatalError()
            }
        }

        protocol ServiceProtocol: Proto.Metatype {
            func fetch() -> UserProtocol
        }

        #if DEBUG
        final class ServiceMock: ServiceProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var fetchCallCount = 0
            var fetchHandler: (() -> UserProtocol)?
            private var fetchReturnStub: ProtoMockReturnStub<UserProtocol> = .unset
            func fetchSetReturnValue(_ value: UserProtocol) {
                fetchReturnStub = .value(value)
            }

            init(
                fetchHandler: (() -> UserProtocol)? = nil,
                fetchReturnValue: UserProtocol? = UserMock()
            ) {
                self.fetchHandler = fetchHandler
                if let fetchReturnValue {
                    fetchReturnStub = .value(fetchReturnValue)
                }
            }

            func fetch() -> UserProtocol {
                fetchCallCount += 1
                if let handler = fetchHandler {
                    return handler()
                }
                if case .value(let value) = fetchReturnStub {
                    return value
                }
                return UserMock()
            }
        }
        #endif
        """

    // MARK: - Sendable: .mock(.auto), .sendable → synchronized body + auto-defaults

    static let sendableInput = """
        @Proto(.mock(.auto), .sendable)
        final class Service {
            func fetch() -> UserProtocol {
                fatalError()
            }
        }
        """

    static let sendableExpanded = """
        final class Service {
            func fetch() -> UserProtocol {
                fatalError()
            }
        }

        protocol ServiceProtocol: Sendable, Proto.Metatype {
            func fetch() -> UserProtocol
        }

        final class ServiceMock: @unchecked Sendable, ServiceProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private let _protoMockLock = ProtoMockSynchronizationLock()

            var fetchCallCount: Int {
                _protoMockLock.withLock {
                    _fetchCallCount
                }
            }
            private var _fetchCallCount = 0
            var fetchHandler: (() -> UserProtocol)? {
                get {
                    _protoMockLock.withLock {
                        _fetchHandler
                    }
                }
                set {
                    _protoMockLock.withLock {
                        _fetchHandler = newValue
                    }
                }
            }
            private var _fetchHandler: (() -> UserProtocol)?
            private var _fetchReturnStub: ProtoMockReturnStub<UserProtocol> = .unset
            func fetchSetReturnValue(_ value: UserProtocol) {
                _protoMockLock.withLock {
                        _fetchReturnStub = .value(value)
                }
            }

            init(
                fetchHandler: (() -> UserProtocol)? = nil,
                fetchReturnValue: UserProtocol? = UserMock()
            ) {
                self.fetchHandler = fetchHandler
                if let fetchReturnValue {
                    _protoMockLock.withLock {
                        _fetchReturnStub = .value(fetchReturnValue)
                    }
                }
            }

            func fetch() -> UserProtocol {
                _protoMockLock.withLock {
                    _fetchCallCount += 1
                }
                let handler = _protoMockLock.withLock {
                    _fetchHandler
                }
                if let handler = handler {
                    return handler()
                }
                let returnStub = _protoMockLock.withLock {
                    _fetchReturnStub
                }
                if case .value(let value) = returnStub {
                    return value
                }
                return UserMock()
            }
        }
        """
}
