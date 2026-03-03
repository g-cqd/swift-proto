import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroDiagnosticTests {
    @Test
    private func `mock .custom() with non-string argument emits diagnostic`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock(.custom("FLAG", 1)))
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

                #if FLAG
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
                #endif
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Expected a string literal argument",
                    line: 1,
                    column: 30,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    // MARK: - Invalid .mock(...) sub-options (F-003)

    @Test
    private func `unknown mock flag emits diagnostic`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock(.unknown))
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
                    message: "Invalid mock option; expected '.debug', '.release', "
                        + "'.custom(\"...\")', '.expr(\"...\")' or '.scope(...)'",
                    line: 1,
                    column: 14,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `unknown mock parameterized option emits diagnostic`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock(.filter("X")))
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
                    message: "Invalid mock option; expected '.debug', '.release', "
                        + "'.custom(\"...\")', '.expr(\"...\")' or '.scope(...)'",
                    line: 1,
                    column: 14,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `mock with non-expression argument emits diagnostic`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock(42))
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
                    message: "Invalid mock option; expected '.debug', '.release', "
                        + "'.custom(\"...\")', '.expr(\"...\")' or '.scope(...)'",
                    line: 1,
                    column: 14,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `mock expr with non-string argument emits diagnostic`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock(.expr(42)))
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
                    message: "Expected a string literal argument",
                    line: 1,
                    column: 20,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `mock expr with empty string emits diagnostic`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock(.expr("   ")))
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
                    message: "Invalid compilation expression '   '; expression must be "
                        + "non-empty, single-line, and must not contain ';'",
                    line: 1,
                    column: 14,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `mock expr with semicolon emits diagnostic`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock(.expr("DEBUG; os(iOS)")))
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
                    message: "Invalid compilation expression 'DEBUG; os(iOS)'; expression must be "
                        + "non-empty, single-line, and must not contain ';'",
                    line: 1,
                    column: 14,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `enum without members produces empty protocol`() {
        assertMacroExpansionTesting(
            """
            @Proto
            enum Direction {
                case north
                case south
            }
            """,
            expandedSource: """
                enum Direction {
                    case north
                    case south
                }

                protocol DirectionProtocol {
                }
                """,
            macros: testMacros
        )
    }
}
