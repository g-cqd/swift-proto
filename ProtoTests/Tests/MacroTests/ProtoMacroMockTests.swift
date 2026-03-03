import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite("Proto mock generation")
struct ProtoMacroMockTests {
    @Test
    func `mock generates companion mock with function helpers`() {
        assertMacroExpansionTesting(
            Fixture.mockServiceInput,
            expandedSource: Fixture.mockServiceExpandedSource,
            macros: testMacros
        )
    }

    @Test
    func `ProtoMockIgnored omits function helper generation`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock)
            final class Worker {
                @ProtoMockIgnored
                func run(_ task: String) -> Int {
                    1
                }
            }
            """,
            expandedSource: """
                final class Worker {
                    func run(_ task: String) -> Int {
                        1
                    }
                }

                protocol WorkerProtocol {
                    func run(_ task: String) -> Int
                }

                final class WorkerMock: WorkerProtocol {
                    func run(_ task: String) -> Int {
                        ProtoMockFailureHandling.fail("No mock helper generated for run on WorkerMock")
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    func `mock respects protocol visibility for generated mock API`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock)
            public final class Logger {
                public func log(_ message: String) {
                }
            }
            """,
            expandedSource: """
                public final class Logger {
                    public func log(_ message: String) {
                    }
                }

                public protocol LoggerProtocol {
                    func log(_ message: String)
                }

                public final class LoggerMock: LoggerProtocol {
                    public private(set) var logCallCount = 0
                    public private(set) var logReceivedArguments: [String] = []
                    public var logHandler: ((String) -> Void)?

                    public init(
                        logHandler: ((String) -> Void)? = nil
                    ) {
                        self.logHandler = logHandler
                    }

                    public func log(_ message: String) {
                        logCallCount += 1
                        logReceivedArguments.append(message)
                        if let handler = logHandler {
                            handler(message)
                            return
                        }
                    }
                }
                """,
            macros: testMacros
        )
    }
}

private extension ProtoMacroMockTests {
    enum Fixture {
        static let mockServiceInput = """
            @Proto(.mock)
            final class Service {
                func fetch(id: String) async throws -> String {
                    "value"
                }

                func ping() {
                }
            }
            """

        static let mockServiceExpandedSource = """
            final class Service {
                func fetch(id: String) async throws -> String {
                    "value"
                }

                func ping() {
                }
            }

            protocol ServiceProtocol {
                func fetch(id: String) async throws -> String
                func ping()
            }

            final class ServiceMock: ServiceProtocol {
                private enum ProtoMockReturnStub<Value> {
                    case unset
                    case value(Value)
                }

                private(set) var fetchCallCount = 0
                private(set) var fetchReceivedArguments: [String] = []
                var fetchHandler: ((String) async throws -> String)?
                var fetchError: (any Error)?
                private var fetchReturnStub: ProtoMockReturnStub<String> = .unset
                func fetchSetReturnValue(_ value: String) {
                    fetchReturnStub = .value(value)
                }
                private(set) var pingCallCount = 0
                var pingHandler: (() -> Void)?

                init(
                    fetchHandler: ((String) async throws -> String)? = nil,
                    fetchError: (any Error)? = nil,
                    fetchReturnValue: String? = nil,
                    pingHandler: (() -> Void)? = nil
                ) {
                    self.fetchHandler = fetchHandler
                    self.fetchError = fetchError
                    if let fetchReturnValue {
                        fetchReturnStub = .value(fetchReturnValue)
                    }
                    self.pingHandler = pingHandler
                }

                func fetch(id: String) async throws -> String {
                    fetchCallCount += 1
                    fetchReceivedArguments.append(id)
                    if let handler = fetchHandler {
                        return try await handler(id)
                    }
                    if let error = fetchError {
                        throw error
                    }
                    if case .value(let value) = fetchReturnStub {
                        return value
                    }
                    ProtoMockFailureHandling.fail("Unstubbed call to fetch on ServiceMock")
                }
                func ping() {
                    pingCallCount += 1
                    if let handler = pingHandler {
                        handler()
                        return
                    }
                }
            }
            """
    }
}
