import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite("Actor protocol generation")
struct ProtoMacroActorTests {
    @Test
    private func `actor method made async in protocol`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor DataStore {
                func fetch() -> String {
                    ""
                }
            }
            """,
            expandedSource: """
                actor DataStore {
                    func fetch() -> String {
                        ""
                    }
                }

                protocol DataStoreProtocol: Actor {
                    func fetch() async -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `already-async actor method preserved`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor DataStore {
                func load() async throws -> Data {
                    Data()
                }
            }
            """,
            expandedSource: """
                actor DataStore {
                    func load() async throws -> Data {
                        Data()
                    }
                }

                protocol DataStoreProtocol: Actor {
                    func load() async throws -> Data
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `nonisolated actor method stays synchronous`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor DataStore {
                nonisolated func identifier() -> String {
                    "id"
                }
            }
            """,
            expandedSource: """
                actor DataStore {
                    nonisolated func identifier() -> String {
                        "id"
                    }
                }

                protocol DataStoreProtocol: Actor {
                    nonisolated func identifier() -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `actor property gets async getter`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor DataStore {
                var items: [String] = []
            }
            """,
            expandedSource: """
                actor DataStore {
                    var items: [String] = []
                }

                protocol DataStoreProtocol: Actor {
                    var items: [String] {
                        get async
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `actor let property gets async getter`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor DataStore {
                let id: String = "store"
            }
            """,
            expandedSource: """
                actor DataStore {
                    let id: String = "store"
                }

                protocol DataStoreProtocol: Actor {
                    var id: String {
                        get async
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `nonisolated actor property stays synchronous`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor DataStore {
                nonisolated var identifier: String {
                    "id"
                }
            }
            """,
            expandedSource: """
                actor DataStore {
                    nonisolated var identifier: String {
                        "id"
                    }
                }

                protocol DataStoreProtocol: Actor {
                    nonisolated var identifier: String {
                        get
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `actor static method not made async`() {
        assertMacroExpansionTesting(
            """
            @Proto(.include(.static))
            actor DataStore {
                static func create() -> DataStore {
                    DataStore()
                }
                func fetch() -> String {
                    ""
                }
            }
            """,
            expandedSource: """
                actor DataStore {
                    static func create() -> DataStore {
                        DataStore()
                    }
                    func fetch() -> String {
                        ""
                    }
                }

                protocol DataStoreProtocol: Actor {
                    static func create() -> Self
                    func fetch() async -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `actor static property not made async`() {
        assertMacroExpansionTesting(
            """
            @Proto(.include(.static))
            actor DataStore {
                static var defaultName: String {
                    "store"
                }
                var items: [String] = []
            }
            """,
            expandedSource: """
                actor DataStore {
                    static var defaultName: String {
                        "store"
                    }
                    var items: [String] = []
                }

                protocol DataStoreProtocol: Actor {
                    static var defaultName: String {
                        get
                    }
                    var items: [String] {
                        get async
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `actor subscript gets async getter`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor DataStore {
                subscript(index: Int) -> String {
                    return ""
                }
            }
            """,
            expandedSource: """
                actor DataStore {
                    subscript(index: Int) -> String {
                        return ""
                    }
                }

                protocol DataStoreProtocol: Actor {
                    subscript(index: Int) -> String {
                        get async
                    }
                }
                """,
            macros: testMacros
        )
    }
}
