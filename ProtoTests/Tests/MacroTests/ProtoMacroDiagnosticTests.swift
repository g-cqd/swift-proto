import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite("Proto macro diagnostics")
struct ProtoMacroDiagnosticTests {
    @Test
    private func `unknown option emits warning`() {
        let unknownOptionMessage =
            "Unknown option; expected '.include(...)', '.exclude(...)', "
            + "'.scope(...)', '.conforms(to:)', '.sendable', '.mock', '.mock(...)', '.noIsolation', '.isolation(...)', "
            + "'.constrained', '.constrained(...)', or '.unconstrained'"
        assertMacroExpansionTesting(
            """
            @Proto(.unknown)
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
                    message: unknownOptionMessage,
                    line: 1,
                    column: 8,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `unknown parameterized option emits warning`() {
        let unknownOptionMessage =
            "Unknown option; expected '.include(...)', '.exclude(...)', "
            + "'.scope(...)', '.conforms(to:)', '.sendable', '.mock', '.mock(...)', '.noIsolation', '.isolation(...)', "
            + "'.constrained', '.constrained(...)', or '.unconstrained'"
        assertMacroExpansionTesting(
            """
            @Proto(.custom("value"))
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
                    message: unknownOptionMessage,
                    line: 1,
                    column: 8,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `invalid scope value emits error`() {
        let expectedMessage =
            "Invalid scope value; expected '.private', '.fileprivate', "
            + "'.internal', '.package', '.public', or '.open'"
        assertMacroExpansionTesting(
            """
            @Proto(.scope(.custom))
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
                    message: expectedMessage,
                    line: 1,
                    column: 15,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `invalid isolation value emits error`() {
        let expectedMessage = "Invalid isolation value; expected '.full', '.actorOnly', '.asyncOnly', or '.none'"
        assertMacroExpansionTesting(
            """
            @Proto(.isolation(.custom))
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
                    message: expectedMessage,
                    line: 1,
                    column: 8,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `invalid member selection value emits error`() {
        let expectedMessage =
            "Invalid member selection; expected '.members', '.methods', "
            + "'.properties', '.subscripts', '.static', or '.initializer'"
        assertMacroExpansionTesting(
            """
            @Proto(.include(.unknown))
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
                    message: expectedMessage,
                    line: 1,
                    column: 17,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `invalid constrained option emits error`() {
        let expectedMessage = "Invalid constrained option; expected '.to(...)' or '.withWhereClause'"
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.custom))
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
                    message: expectedMessage,
                    line: 1,
                    column: 21,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `mixed .withWhereClause with .to() at root level emits error`() {
        let expectedMessage =
            "'.withWhereClause' cannot be combined with '.to(...)' at root level; "
            + "use per-parameter '.to(\"T\", .withWhereClause)' instead"
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.to("Key"), .withWhereClause))
            final class Cache<Key: Hashable, Value> where Value: Codable {
                func get(_ key: Key) -> Value? {
                    nil
                }
            }
            """,
            expandedSource: """
                final class Cache<Key: Hashable, Value> where Value: Codable {
                    func get(_ key: Key) -> Value? {
                        nil
                    }
                }

                protocol CacheProtocol<Key> {
                    associatedtype Key: Hashable
                    associatedtype Value
                    func get(_ key: Key) -> Value?
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: expectedMessage,
                    line: 1,
                    column: 21,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }
}
