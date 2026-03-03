import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroMemberTests {
    // MARK: - Negative double literal (TypeInference lines 82-83)

    @Test
    private func `negative double literal infers Double`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Config {
                var rate = -3.14
            }
            """,
            expandedSource: """
                final class Config {
                    var rate = -3.14
                }

                protocol ConfigProtocol {
                    var rate: Double {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Tuple with uninferrable element (TypeInference line 133)

    @Test
    private func `tuple with uninferrable element omits property`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class State {
                var pair = (1, nil)
            }
            """,
            expandedSource: """
                final class State {
                    var pair = (1, nil)
                }

                protocol StateProtocol {
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Property type cannot be inferred; add an explicit type annotation",
                    line: 3,
                    column: 5,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    // MARK: - Lowercase function call not inferred (TypeInference line 92/100)

    @Test
    private func `lowercase function call not inferred as constructor`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class State {
                var result = makeValue()
            }
            """,
            expandedSource: """
                final class State {
                    var result = makeValue()
                }

                protocol StateProtocol {
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Property type cannot be inferred; add an explicit type annotation",
                    line: 3,
                    column: 5,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    // MARK: - Setter access level filtering (MemberExtractor lines 107-114)

    @Test
    private func `public class with package(set) emits get-only`() {
        assertMacroExpansionTesting(
            """
            @Proto
            public final class Store {
                public package(set) var name: String = ""
            }
            """,
            expandedSource: """
                public final class Store {
                    public package(set) var name: String = ""
                }

                public protocol StoreProtocol {
                    var name: String {
                        get
                    }
                }
                """,
            macros: testMacros
        )
    }
}
