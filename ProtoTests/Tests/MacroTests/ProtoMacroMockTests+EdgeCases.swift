import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroMockTests {
    // MARK: - @escaping @Sendable handler type preserves @Sendable

    @Test
    func `mock strips @escaping but preserves @Sendable in captured argument type`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock)
            final class Scheduler {
                func run(_ block: @escaping @Sendable () -> Void) {
                }
            }
            """,
            expandedSource: """
                final class Scheduler {
                    func run(_ block: @escaping @Sendable () -> Void) {
                    }
                }

                protocol SchedulerProtocol {
                    func run(_ block: @escaping @Sendable () -> Void)
                }

                final class SchedulerMock: SchedulerProtocol {
                    private(set) var runCallCount = 0
                    private(set) var runReceivedArguments: [@Sendable () -> Void] = []
                    var runHandler: ((@Sendable () -> Void) -> Void)?

                    init(
                        runHandler: ((@Sendable () -> Void) -> Void)? = nil
                    ) {
                        self.runHandler = runHandler
                    }

                    func run(_ block: @escaping @Sendable () -> Void) {
                        runCallCount += 1
                        runReceivedArguments.append(block)
                        if let handler = runHandler {
                            handler(block)
                            return
                        }
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Enum with static + computed properties

    @Test
    func `mock for enum with static and computed members`() {
        assertMacroExpansionTesting(
            EdgeCaseFixture.enumStaticInput,
            expandedSource: EdgeCaseFixture.enumStaticExpanded,
            macros: testMacros
        )
    }

    // MARK: - private(set) property in mock context produces get-only stub

    @Test
    func `mock with private(set) property generates get-only stub`() {
        assertMacroExpansionTesting(
            EdgeCaseFixture.privateSetInput,
            expandedSource: EdgeCaseFixture.privateSetExpanded,
            macros: testMacros
        )
    }

    // MARK: - Backtick-escaped identifiers (TEST-03)

    @Test
    func `mock with backtick-escaped method name generates helpers`() {
        assertMacroExpansionTesting(
            EdgeCaseFixture.backtickIdentifierInput,
            expandedSource: EdgeCaseFixture.backtickIdentifierExpanded,
            macros: testMacros
        )
    }

    // MARK: - Async throws getter property (F-004)

    @Test
    func `mock with async throws getter generates effectful stub`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock)
            final class Store {
                var data: String {
                    get async throws { "" }
                }
            }
            """,
            expandedSource: """
                final class Store {
                    var data: String {
                        get async throws { "" }
                    }
                }

                protocol StoreProtocol {
                    var data: String {
                        get async throws
                    }
                }

                final class StoreMock: StoreProtocol {
                    var data: String {
                        get async throws {
                            ProtoMockFailureHandling.fail("Unstubbed property 'data' on StoreMock")
                        }
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Generic function in mock (TEST-01 additional)

    @Test
    func `mock with generic function generates correct handler type`() {
        assertMacroExpansionTesting(
            EdgeCaseFixture.genericFunctionInput,
            expandedSource: EdgeCaseFixture.genericFunctionExpanded,
            macros: testMacros
        )
    }

    // MARK: - Multiple unnamed parameters (F-004)

    @Test
    func `mock with all unnamed parameters omits argument capture`() {
        assertMacroExpansionTesting(
            EdgeCaseFixture.unnamedParametersInput,
            expandedSource: EdgeCaseFixture.unnamedParametersExpanded,
            macros: testMacros
        )
    }
}
