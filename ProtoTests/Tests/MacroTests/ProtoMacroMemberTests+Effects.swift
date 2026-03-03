import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroMemberTests {
    @Test
    private func `protoMember .throws adds throwing getter to property`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Store {
                @ProtoMember(.throws) var count: Int
            }
            """,
            expandedSource: """
                final class Store {
                    var count: Int
                }

                protocol StoreProtocol {
                    var count: Int {
                        get throws
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .async .throws on property combined`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Store {
                @ProtoMember(.async, .throws) var count: Int
            }
            """,
            expandedSource: """
                final class Store {
                    var count: Int
                }

                protocol StoreProtocol {
                    var count: Int {
                        get async throws
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `default parameter values stripped from protocol`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                func configure(timeout: Int = 30, retries: Int = 3, label: String = "default") {
                }
            }
            """,
            expandedSource: """
                final class Service {
                    func configure(timeout: Int = 30, retries: Int = 3, label: String = "default") {
                    }
                }

                protocol ServiceProtocol {
                    func configure(timeout: Int, retries: Int, label: String)
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `@ProtoExclude skips marked property`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class User {
                var name: String
                @ProtoExclude var debugId: Int
            }
            """,
            expandedSource: """
                final class User {
                    var name: String
                    var debugId: Int
                }

                protocol UserProtocol {
                    var name: String {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `@ProtoExclude skips marked subscript`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Store {
                func get(_ key: String) -> Int { 0 }
                @ProtoExclude subscript(index: Int) -> String { "" }
            }
            """,
            expandedSource: """
                final class Store {
                    func get(_ key: String) -> Int { 0 }
                    subscript(index: Int) -> String { "" }
                }

                protocol StoreProtocol {
                    func get(_ key: String) -> Int
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .async on already-async is no-op`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Loader {
                @ProtoMember(.async) func load() async -> Data {
                    Data()
                }
            }
            """,
            expandedSource: """
                final class Loader {
                    func load() async -> Data {
                        Data()
                    }
                }

                protocol LoaderProtocol {
                    func load() async -> Data
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .throws on already-throwing is no-op`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Loader {
                @ProtoMember(.throws) func load() throws -> Data {
                    Data()
                }
            }
            """,
            expandedSource: """
                final class Loader {
                    func load() throws -> Data {
                        Data()
                    }
                }

                protocol LoaderProtocol {
                    func load() throws -> Data
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `explicit get/set accessors preserved`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Store {
                var count: Int {
                    get { 0 }
                    set { }
                }
            }
            """,
            expandedSource: """
                final class Store {
                    var count: Int {
                        get { 0 }
                        set { }
                    }
                }

                protocol StoreProtocol {
                    var count: Int {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Existing effectful getters preserved

    @Test
    private func `existing get throws preserved without @ProtoMember`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Store {
                var value: Int {
                    get throws { 0 }
                }
            }
            """,
            expandedSource: """
                final class Store {
                    var value: Int {
                        get throws { 0 }
                    }
                }

                protocol StoreProtocol {
                    var value: Int {
                        get throws
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `existing get async preserved without @ProtoMember`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Store {
                var value: Int {
                    get async { 0 }
                }
            }
            """,
            expandedSource: """
                final class Store {
                    var value: Int {
                        get async { 0 }
                    }
                }

                protocol StoreProtocol {
                    var value: Int {
                        get async
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `existing get async throws preserved without @ProtoMember`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Store {
                var value: Int {
                    get async throws { 0 }
                }
            }
            """,
            expandedSource: """
                final class Store {
                    var value: Int {
                        get async throws { 0 }
                    }
                }

                protocol StoreProtocol {
                    var value: Int {
                        get async throws
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Untyped non-inferable property diagnostic

    @Test
    private func `untyped property with non-inferable initializer emits diagnostic`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                var value = someFunc()
            }
            """,
            expandedSource: """
                final class Service {
                    var value = someFunc()
                }

                protocol ServiceProtocol {
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
}
