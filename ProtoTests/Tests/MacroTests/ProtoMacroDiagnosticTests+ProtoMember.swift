import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroDiagnosticTests {
    // MARK: - @ProtoMember diagnostics

    @Test
    private func `async and sync conflict emits error`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                @ProtoMember(.async, .sync) func work() {
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
                    message: "Conflicting options: '.async' and '.sync' cannot be combined",
                    line: 3,
                    column: 5,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `mutable and immutable conflict emits error`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                @ProtoMember(.mutable, .immutable) var name: String
            }
            """,
            expandedSource: """
                final class Service {
                    var name: String
                }

                protocol ServiceProtocol {
                    var name: String {
                        get
                        set
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Conflicting options: '.mutable' and '.immutable' cannot be combined",
                    line: 3,
                    column: 5,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `immutable on function emits warning`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                @ProtoMember(.immutable) func work() {
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
                    message: "'.immutable' has no effect on functions or initializers",
                    line: 3,
                    column: 5,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `mutable on function emits warning`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                @ProtoMember(.mutable) func work() {
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
                    message: "'.mutable' has no effect on functions or initializers",
                    line: 3,
                    column: 5,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `mutating on property emits warning`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                @ProtoMember(.mutating) var name: String
            }
            """,
            expandedSource: """
                final class Service {
                    var name: String
                }

                protocol ServiceProtocol {
                    var name: String {
                        get
                        set
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'.mutating' has no effect on properties or subscripts",
                    line: 3,
                    column: 5,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `mutable with throws conflict emits warning`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                @ProtoMember(.mutable, .throws) var name: String
            }
            """,
            expandedSource: """
                final class Service {
                    var name: String
                }

                protocol ServiceProtocol {
                    var name: String {
                        get throws
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Async/throwing getters cannot have setters; '.mutable' ignored",
                    line: 3,
                    column: 5,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `nonisolated and isolated conflict emits error`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor Service {
                @ProtoMember(.nonisolated, .isolated) func work() {
                }
            }
            """,
            expandedSource: """
                actor Service {
                    func work() {
                    }
                }

                protocol ServiceProtocol: Actor {
                    func work() async
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Conflicting options: '.nonisolated' and '.isolated' cannot be combined",
                    line: 3,
                    column: 5,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `nonisolated on non-actor member emits warning`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                @ProtoMember(.nonisolated) func work() {
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
                    message: "'.nonisolated' only affects actor-generated protocol requirements",
                    line: 3,
                    column: 5,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `isolated on non-actor member emits warning`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                @ProtoMember(.isolated) func work() {
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
                    message: "'.isolated' only affects actor-generated protocol requirements",
                    line: 3,
                    column: 5,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `isolated on static member emits warning`() {
        assertMacroExpansionTesting(
            """
            @Proto(.include(.static))
            actor Service {
                @ProtoMember(.isolated) static func make() -> Service {
                    Service()
                }
            }
            """,
            expandedSource: """
                actor Service {
                    static func make() -> Service {
                        Service()
                    }
                }

                protocol ServiceProtocol: Actor {
                    static func make() -> Self
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'.isolated' has no effect on static members",
                    line: 3,
                    column: 5,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    // MARK: - @ProtoMember(.mutating) on subscript warns

    @Test
    private func `@ProtoMember(.mutating) on subscript emits warning`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Store {
                @ProtoMember(.mutating) subscript(key: String) -> Int {
                    get { 0 }
                    set { }
                }
            }
            """,
            expandedSource: """
                final class Store {
                    subscript(key: String) -> Int {
                        get { 0 }
                        set { }
                    }
                }

                protocol StoreProtocol {
                    subscript(key: String) -> Int {
                        get
                        set
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'.mutating' has no effect on properties or subscripts",
                    line: 3,
                    column: 5,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    // MARK: - Unknown @ProtoMember option

    @Test
    private func `unknown @ProtoMember option emits diagnostic`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                @ProtoMember(.custom) func work() {
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
                    message: "Unknown @ProtoMember option; expected '.immutable', '.mutable', '.async', "
                        + "'.throws', '.sync', '.mutating', '.nonisolated', or '.isolated'",
                    line: 3,
                    column: 18,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `@Proto on protocol emits error`() {
        assertMacroExpansionTesting(
            """
            @Proto
            protocol Existing {
                func work()
            }
            """,
            expandedSource: """
                protocol Existing {
                    func work()
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

    @Test
    private func `empty parentheses equivalent to bare @Proto`() {
        assertMacroExpansionTesting(
            """
            @Proto()
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
            macros: testMacros
        )
    }
}
