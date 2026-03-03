import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroActorTests {
    // MARK: - @ProtoMember(.sync) on actor

    @Test
    private func `protoMember .sync removes async from actor property`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor DataStore {
                @ProtoMember(.sync) var items: [String] = []
            }
            """,
            expandedSource: """
                actor DataStore {
                    var items: [String] = []
                }

                protocol DataStoreProtocol: Actor {
                    var items: [String] {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .throws on actor property adds throws`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor DataStore {
                @ProtoMember(.throws) var items: [String] = []
            }
            """,
            expandedSource: """
                actor DataStore {
                    var items: [String] = []
                }

                protocol DataStoreProtocol: Actor {
                    var items: [String] {
                        get async throws
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .throws .sync on actor strips async`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor DataStore {
                @ProtoMember(.throws, .sync) var items: [String] = []
            }
            """,
            expandedSource: """
                actor DataStore {
                    var items: [String] = []
                }

                protocol DataStoreProtocol: Actor {
                    var items: [String] {
                        get throws
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .nonisolated on actor function`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor DataStore {
                @ProtoMember(.nonisolated) func fetch() -> String {
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
                    nonisolated func fetch() -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .isolated overrides nonisolated`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor DataStore {
                @ProtoMember(.isolated) nonisolated func fetch() -> String {
                    ""
                }
            }
            """,
            expandedSource: """
                actor DataStore {
                    nonisolated func fetch() -> String {
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
    private func `protoMember .sync removes async from actor method`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor DataStore {
                @ProtoMember(.sync) func fetch() -> String {
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
                    func fetch() -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .immutable .sync on actor property`() {
        assertMacroExpansionTesting(
            """
            @Proto
            actor DataStore {
                @ProtoMember(.immutable, .sync) var items: [String] = []
            }
            """,
            expandedSource: """
                actor DataStore {
                    var items: [String] = []
                }

                protocol DataStoreProtocol: Actor {
                    var items: [String] {
                        get
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .async with .noIsolation adds async`() {
        assertMacroExpansionTesting(
            """
            @Proto(.noIsolation)
            actor DataStore {
                func fetch() -> String {
                    ""
                }
                @ProtoMember(.async) func load() -> Data {
                    Data()
                }
            }
            """,
            expandedSource: """
                actor DataStore {
                    func fetch() -> String {
                        ""
                    }
                    func load() -> Data {
                        Data()
                    }
                }

                protocol DataStoreProtocol {
                    func fetch() -> String
                    func load() async -> Data
                }
                """,
            macros: testMacros
        )
    }
}
