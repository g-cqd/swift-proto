extension ProtoMacroMockTests {
    enum SharedHelperGapFixture {}
}

// MARK: - Auto-default with Optional<> generic form

extension ProtoMacroMockTests.SharedHelperGapFixture {
    static let optionalGenericInput = """
        @Proto(.mock(.auto))
        final class Service {
            func fetch() -> Optional<UserProtocol> {
                fatalError()
            }
        }
        """

    static let optionalGenericExpanded = """
        final class Service {
            func fetch() -> Optional<UserProtocol> {
                fatalError()
            }
        }

        protocol ServiceProtocol: Proto.Metatype {
            func fetch() -> Optional<UserProtocol>
        }

        final class ServiceMock: ServiceProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var fetchCallCount = 0
            var fetchHandler: (() -> Optional<UserProtocol>)?
            private var fetchReturnStub: ProtoMockReturnStub<Optional<UserProtocol>> = .unset
            func fetchSetReturnValue(_ value: Optional<UserProtocol>) {
                fetchReturnStub = .value(value)
            }

            init(
                fetchHandler: (() -> Optional<UserProtocol>)? = nil,
                fetchReturnValue: Optional<UserProtocol>? = UserMock()
            ) {
                self.fetchHandler = fetchHandler
                if let fetchReturnValue {
                    fetchReturnStub = .value(fetchReturnValue)
                }
            }

            func fetch() -> Optional<UserProtocol> {
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
        """
}

// MARK: - Auto-default with Array<> generic form

extension ProtoMacroMockTests.SharedHelperGapFixture {
    static let arrayGenericInput = """
        @Proto(.mock(.auto))
        final class Service {
            func list() -> Array<ItemProtocol> {
                []
            }
        }
        """

    static let arrayGenericExpanded = """
        final class Service {
            func list() -> Array<ItemProtocol> {
                []
            }
        }

        protocol ServiceProtocol: Proto.Metatype {
            func list() -> Array<ItemProtocol>
        }

        final class ServiceMock: ServiceProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var listCallCount = 0
            var listHandler: (() -> Array<ItemProtocol>)?
            private var listReturnStub: ProtoMockReturnStub<Array<ItemProtocol>> = .unset
            func listSetReturnValue(_ value: Array<ItemProtocol>) {
                listReturnStub = .value(value)
            }

            init(
                listHandler: (() -> Array<ItemProtocol>)? = nil,
                listReturnValue: Array<ItemProtocol>? = [ItemMock()]
            ) {
                self.listHandler = listHandler
                if let listReturnValue {
                    listReturnStub = .value(listReturnValue)
                }
            }

            func list() -> Array<ItemProtocol> {
                listCallCount += 1
                if let handler = listHandler {
                    return handler()
                }
                if case .value(let value) = listReturnStub {
                    return value
                }
                return [ItemMock()]
            }
        }
        """
}

// MARK: - Actor mock with nonisolated

extension ProtoMacroMockTests.SharedHelperGapFixture {
    static let actorNonisolatedInput = """
        @Proto(.mock)
        actor Session {
            nonisolated func identifier() -> String {
                "abc"
            }

            func save(data: String) {
            }
        }
        """

    static let actorNonisolatedExpanded = """
        actor Session {
            nonisolated func identifier() -> String {
                "abc"
            }

            func save(data: String) {
            }
        }

        protocol SessionProtocol: Actor {
            nonisolated func identifier() -> String
            func save(data: String) async
        }

        actor SessionMock: SessionProtocol {
            private(set) var saveCallCount = 0
            private(set) var saveReceivedArguments: [String] = []
            var saveHandler: ((String) async -> Void)?

            init(
                saveHandler: ((String) async -> Void)? = nil
            ) {
                self.saveHandler = saveHandler
            }

            nonisolated func identifier() -> String {
                ProtoMockFailureHandling.fail("No mock helper generated for identifier on SessionMock")
            }
            func save(data: String) async {
                saveCallCount += 1
                saveReceivedArguments.append(data)
                if let handler = saveHandler {
                    await handler(data)
                    return
                }
            }
        }
        """
}

// MARK: - Mock with .scope(.package) on public class

extension ProtoMacroMockTests.SharedHelperGapFixture {
    static let mockScopePackageInput = """
        @Proto(.mock(.scope(.package)))
        public final class Logger {
            public func log(_ message: String) {
            }
        }
        """

    static let mockScopePackageExpanded = """
        public final class Logger {
            public func log(_ message: String) {
            }
        }

        public protocol LoggerProtocol {
            func log(_ message: String)
        }

        package final class LoggerMock: LoggerProtocol {
            package private(set) var logCallCount = 0
            package private(set) var logReceivedArguments: [String] = []
            package var logHandler: ((String) -> Void)?

            package init(
                logHandler: ((String) -> Void)? = nil
            ) {
                self.logHandler = logHandler
            }

            package func log(_ message: String) {
                logCallCount += 1
                logReceivedArguments.append(message)
                if let handler = logHandler {
                    handler(message)
                    return
                }
            }
        }
        """
}
