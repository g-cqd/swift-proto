import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroActorTests {
    // MARK: - Isolation config

    @Test
    private func `.noIsolation removes Actor inheritance and async`() {
        assertMacroExpansionTesting(
            """
            @Proto(.noIsolation)
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

                protocol DataStoreProtocol {
                    func fetch() -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `.isolation(.none) removes inheritance and async`() {
        assertMacroExpansionTesting(
            """
            @Proto(.isolation(.none))
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

                protocol DataStoreProtocol {
                    func fetch() -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `.isolation(.full) overrides .noIsolation`() {
        assertMacroExpansionTesting(
            """
            @Proto(.noIsolation, .isolation(.full))
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
    private func `.isolation(.actorOnly) keeps Actor without async`() {
        assertMacroExpansionTesting(
            """
            @Proto(.isolation(.actorOnly))
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
                    func fetch() -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `.isolation(.asyncOnly) adds async without Actor`() {
        assertMacroExpansionTesting(
            """
            @Proto(.isolation(.asyncOnly))
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

                protocol DataStoreProtocol {
                    func fetch() async -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `.noIsolation with .conforms(to: Actor) keeps Actor`() {
        assertMacroExpansionTesting(
            """
            @Proto(.noIsolation, .conforms(to: Actor.self))
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
                    func fetch() -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `.noIsolation property keeps get/set without async`() {
        assertMacroExpansionTesting(
            """
            @Proto(.noIsolation)
            actor DataStore {
                var items: [String] = []
            }
            """,
            expandedSource: """
                actor DataStore {
                    var items: [String] = []
                }

                protocol DataStoreProtocol {
                    var items: [String] {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }
}
