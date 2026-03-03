import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroDiagnosticTests {
    @Test
    private func `invalid constrained type list emits error`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.to(1)))
            final class Service<T> {
                func work(_ value: T) {
                }
            }
            """,
            expandedSource: """
                final class Service<T> {
                    func work(_ value: T) {
                    }
                }

                protocol ServiceProtocol<T> {
                    associatedtype T
                    func work(_ value: T)
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Expected a string literal argument",
                    line: 1,
                    column: 25,
                    severity: .error
                ),
                DiagnosticSpec(
                    message: "Invalid constrained type list; expected one or more string names in '.to(...)'",
                    line: 1,
                    column: 21,
                    severity: .error
                ),
            ],
            macros: testMacros
        )
    }

    @Test
    private func `scope .open normalized to public protocol`() {
        assertMacroExpansionTesting(
            """
            @Proto(.scope(.open))
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

                public protocol ServiceProtocol {
                    func work()
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `open class inferred scope normalized to public`() {
        assertMacroExpansionTesting(
            """
            @Proto
            open class Service {
                open func work() {
                }
            }
            """,
            expandedSource: """
                open class Service {
                    open func work() {
                    }
                }

                public protocol ServiceProtocol {
                    func work()
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - @Proto on extension

    @Test
    private func `@Proto on extension emits requiresNominalType diagnostic`() {
        assertMacroExpansionTesting(
            """
            @Proto
            extension String {
                func work() {
                }
            }
            """,
            expandedSource: """
                extension String {
                    func work() {
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Proto can only be applied to a class, struct, enum, or actor",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    // MARK: - @Proto on XProtocol → XProtocolProtocol

    @Test
    private func `@Proto on type named XProtocol generates XProtocolProtocol`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class MyProtocol {
                func work() {
                }
            }
            """,
            expandedSource: """
                final class MyProtocol {
                    func work() {
                    }
                }

                protocol MyProtocolProtocol {
                    func work()
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Interpolated string in .to() emits error

    @Test
    private func `interpolated string in .to() emits error`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.to("Key\\(suffix)")))
            final class Store<Key: Hashable> {
                func get(_ key: Key) -> String { "" }
            }
            """,
            expandedSource: """
                final class Store<Key: Hashable> {
                    func get(_ key: Key) -> String { "" }
                }

                protocol StoreProtocol<Key> {
                    associatedtype Key: Hashable
                    func get(_ key: Key) -> String
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "String interpolation is not supported in '.to(...)'; use a plain string literal",
                    line: 1,
                    column: 25,
                    severity: .error
                ),
                DiagnosticSpec(
                    message: "Invalid constrained type list; expected one or more string names in '.to(...)'",
                    line: 1,
                    column: 21,
                    severity: .error
                ),
            ],
            macros: testMacros
        )
    }

    // MARK: - Invalid .conforms(to:) arguments

    @Test
    private func `conforms(to:) with string literal emits error`() {
        assertMacroExpansionTesting(
            """
            @Proto(.conforms(to: "Sendable"))
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
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Invalid argument for '.conforms(to:)'; expected a type literal like 'Sendable.self'",
                    line: 1,
                    column: 22,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `conforms(to:) with function call emits error`() {
        assertMacroExpansionTesting(
            """
            @Proto(.conforms(to: getType()))
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
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Invalid argument for '.conforms(to:)'; expected a type literal like 'Sendable.self'",
                    line: 1,
                    column: 22,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `conforms(to:) with mixed valid and invalid arguments`() {
        assertMacroExpansionTesting(
            """
            @Proto(.conforms(to: Sendable.self, "Bad"))
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

                protocol ServiceProtocol: Sendable {
                    func work()
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Invalid argument for '.conforms(to:)'; expected a type literal like 'Sendable.self'",
                    line: 1,
                    column: 37,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    // MARK: - Mixed-validity string arguments (F-002)

    @Test
    private func `constrained .to() with mixed valid and invalid arguments diagnoses each invalid`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.to("Key", 1)))
            final class Store<Key: Hashable> {
                func get(_ key: Key) -> String { "" }
            }
            """,
            expandedSource: """
                final class Store<Key: Hashable> {
                    func get(_ key: Key) -> String { "" }
                }

                protocol StoreProtocol<Key> {
                    associatedtype Key: Hashable
                    func get(_ key: Key) -> String
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Expected a string literal argument",
                    line: 1,
                    column: 32,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }
}
