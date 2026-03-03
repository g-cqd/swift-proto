import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroDiagnosticTests {
    // MARK: - unknownConstrainedTypeName (ProtoDiagnostic lines 69-70, 95-96)

    @Test
    private func `unknownConstrainedTypeName on multi-param generic`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.to("NonExistent")))
            final class Wrapper<T, U> {
                func transform(_ value: T) -> U {
                    fatalError()
                }
            }
            """,
            expandedSource: """
                final class Wrapper<T, U> {
                    func transform(_ value: T) -> U {
                        fatalError()
                    }
                }

                protocol WrapperProtocol<NonExistent> {
                    associatedtype T
                    associatedtype U
                    func transform(_ value: T) -> U
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'NonExistent' does not match any generic parameter; it will be ignored",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    // MARK: - interpolatedStringNotSupportedInMockExpr (ProtoDiagnostic lines 73-74)

    @Test
    private func `mock expr with interpolated segments`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock(.expr("\\(a) && \\(b)")))
            final class Service {
                func work() {
                }
            }
            """,
            expandedSource: """
                final class Service {
                    func work() {
                    }
                }

                protocol ServiceProtocol {
                    func work()
                }

                final class ServiceMock: ServiceProtocol {
                    private(set) var workCallCount = 0
                    var workHandler: (() -> Void)?

                    init(
                        workHandler: (() -> Void)? = nil
                    ) {
                        self.workHandler = workHandler
                    }

                    func work() {
                        workCallCount += 1
                        if let handler = workHandler {
                            handler()
                            return
                        }
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "String interpolation is not supported in '.expr(...)'; use a plain string literal",
                    line: 1,
                    column: 20,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    // MARK: - invalidCompilationCondition (ProtoDiagnostic lines 81-82, 97-98)

    @Test
    private func `mock custom with invalid flag characters`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock(.custom("MY-FLAG")))
            final class Service {
                func work() {
                }
            }
            """,
            expandedSource: """
                final class Service {
                    func work() {
                    }
                }

                protocol ServiceProtocol {
                    func work()
                }

                final class ServiceMock: ServiceProtocol {
                    private(set) var workCallCount = 0
                    var workHandler: (() -> Void)?

                    init(
                        workHandler: (() -> Void)? = nil
                    ) {
                        self.workHandler = workHandler
                    }

                    func work() {
                        workCallCount += 1
                        if let handler = workHandler {
                            handler()
                            return
                        }
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Invalid compilation condition 'MY-FLAG'; "
                        + "must contain only letters, digits, and underscores",
                    line: 1,
                    column: 14,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    // MARK: - invalidCompilationExpression (ProtoDiagnostic lines 83-85, 99-100)

    @Test
    private func `mock expr with only semicolon`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock(.expr(";")))
            final class Service {
                func work() {
                }
            }
            """,
            expandedSource: """
                final class Service {
                    func work() {
                    }
                }

                protocol ServiceProtocol {
                    func work()
                }

                final class ServiceMock: ServiceProtocol {
                    private(set) var workCallCount = 0
                    var workHandler: (() -> Void)?

                    init(
                        workHandler: (() -> Void)? = nil
                    ) {
                        self.workHandler = workHandler
                    }

                    func work() {
                        workCallCount += 1
                        if let handler = workHandler {
                            handler()
                            return
                        }
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Invalid compilation expression ';'; expression must be "
                        + "non-empty, single-line, and must not contain ';'",
                    line: 1,
                    column: 14,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    // MARK: - collectQualifiedName recursion (Parsing lines 444-454)

    @Test
    private func `conforms(to:) with qualified name`() {
        assertMacroExpansionTesting(
            """
            @Proto(.conforms(to: Foundation.Codable.self))
            final class Service {
                func work() {
                }
            }
            """,
            expandedSource: """
                final class Service {
                    func work() {
                    }
                }

                protocol ServiceProtocol: Foundation.Codable {
                    func work()
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Constraint merging (Parsing lines 211-219)

    @Test
    private func `multiple .constrained() calls merge names`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.to("Key")), .constrained(.to("Value")))
            final class Store<Key: Hashable, Value> {
                func get(_ key: Key) -> Value? {
                    nil
                }
            }
            """,
            expandedSource: """
                final class Store<Key: Hashable, Value> {
                    func get(_ key: Key) -> Value? {
                        nil
                    }
                }

                protocol StoreProtocol<Key, Value> {
                    associatedtype Key: Hashable
                    associatedtype Value
                    func get(_ key: Key) -> Value?
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - .withWhereClause defaults to .all (Parsing lines 220-222)

    @Test
    private func `constrained .withWhereClause without .to() defaults to all and keeps where`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.withWhereClause))
            final class Processor<T> where T: Hashable {
                func process(_ item: T) {
                }
            }
            """,
            expandedSource: """
                final class Processor<T> where T: Hashable {
                    func process(_ item: T) {
                    }
                }

                protocol ProcessorProtocol<T> where T: Hashable {
                    associatedtype T
                    func process(_ item: T)
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Mock scope early return guard (MockParsing line 140)

    @Test
    private func `mock scope with no arguments`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock, .mock(.scope()))
            final class Service {
                func work() {
                }
            }
            """,
            expandedSource: """
                final class Service {
                    func work() {
                    }
                }

                protocol ServiceProtocol {
                    func work()
                }

                final class ServiceMock: ServiceProtocol {
                    private(set) var workCallCount = 0
                    var workHandler: (() -> Void)?

                    init(
                        workHandler: (() -> Void)? = nil
                    ) {
                        self.workHandler = workHandler
                    }

                    func work() {
                        workCallCount += 1
                        if let handler = workHandler {
                            handler()
                            return
                        }
                    }
                }
                """,
            macros: testMacros
        )
    }
}
