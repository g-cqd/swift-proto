import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroMemberTests {
    // MARK: - Type inference from initializer

    @Test
    private func `infer String type from string literal`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class User {
                var displayName = ""
            }
            """,
            expandedSource: """
                final class User {
                    var displayName = ""
                }

                protocol UserProtocol {
                    var displayName: String {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `infer Bool type from boolean literal`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class State {
                var isLoading = false
            }
            """,
            expandedSource: """
                final class State {
                    var isLoading = false
                }

                protocol StateProtocol {
                    var isLoading: Bool {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `infer Int type from integer literal`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Counter {
                var count = 0
            }
            """,
            expandedSource: """
                final class Counter {
                    var count = 0
                }

                protocol CounterProtocol {
                    var count: Int {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `infer Double type from float literal`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Config {
                var rate = 0.5
            }
            """,
            expandedSource: """
                final class Config {
                    var rate = 0.5
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

    @Test
    private func `infer Int type from negative literal`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Config {
                let offset = -1
            }
            """,
            expandedSource: """
                final class Config {
                    let offset = -1
                }

                protocol ConfigProtocol {
                    var offset: Int {
                        get
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `infer type from constructor call`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                var data = Data()
            }
            """,
            expandedSource: """
                final class Service {
                    var data = Data()
                }

                protocol ServiceProtocol {
                    var data: Data {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `infer array type from array literal`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Store {
                var items = [1, 2, 3]
            }
            """,
            expandedSource: """
                final class Store {
                    var items = [1, 2, 3]
                }

                protocol StoreProtocol {
                    var items: [Int] {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `infer dictionary type from dictionary literal`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Registry {
                var map = ["key": 1]
            }
            """,
            expandedSource: """
                final class Registry {
                    var map = ["key": 1]
                }

                protocol RegistryProtocol {
                    var map: [String: Int] {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `infer multiple properties with mixed annotations`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class ViewModel {
                var title: String
                var isActive = false
                var count = 0
            }
            """,
            expandedSource: """
                final class ViewModel {
                    var title: String
                    var isActive = false
                    var count = 0
                }

                protocol ViewModelProtocol {
                    var title: String {
                        get
                        set
                    }
                    var isActive: Bool {
                        get
                        set
                    }
                    var count: Int {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Tuple + generic-constructor type inference

    @Test
    private func `infer tuple type from literal`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class State {
                var pair = (1, "hello")
            }
            """,
            expandedSource: """
                final class State {
                    var pair = (1, "hello")
                }

                protocol StateProtocol {
                    var pair: (Int, String) {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `infer generic constructor type from literal`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Store {
                var items = Set<String>()
            }
            """,
            expandedSource: """
                final class Store {
                    var items = Set<String>()
                }

                protocol StoreProtocol {
                    var items: Set<String> {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Optional literal inference failure

    @Test
    private func `nil literal cannot be inferred, emits diagnostic`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class State {
                var value = nil
            }
            """,
            expandedSource: """
                final class State {
                    var value = nil
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

    // MARK: - Mixed-type array infers from first element

    @Test
    private func `mixed-type array infers from first element`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class State {
                var items = [1, "a"]
            }
            """,
            expandedSource: """
                final class State {
                    var items = [1, "a"]
                }

                protocol StateProtocol {
                    var items: [Int] {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Single-element tuple skipped (count < 2)

    @Test
    private func `single-element parenthesized expression cannot be inferred`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class State {
                var value = (1)
            }
            """,
            expandedSource: """
                final class State {
                    var value = (1)
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

    @Test
    private func `infer let property type from literal`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Config {
                let name = "default"
            }
            """,
            expandedSource: """
                final class Config {
                    let name = "default"
                }

                protocol ConfigProtocol {
                    var name: String {
                        get
                    }
                }
                """,
            macros: testMacros
        )
    }
}
