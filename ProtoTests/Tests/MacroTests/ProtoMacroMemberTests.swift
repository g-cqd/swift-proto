import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite("Member extraction and transformation")
struct ProtoMacroMemberTests {
    @Test
    private func `empty class generates empty protocol`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Empty {
            }
            """,
            expandedSource: """
                final class Empty {
                }

                protocol EmptyProtocol {
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `single method included in protocol`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class UserService {
                func fetchUser() -> String {
                    return ""
                }
            }
            """,
            expandedSource: """
                final class UserService {
                    func fetchUser() -> String {
                        return ""
                    }
                }

                protocol UserServiceProtocol {
                    func fetchUser() -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `stored properties generate get/set accessors`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class User {
                let id: UUID
                var name: String
            }
            """,
            expandedSource: """
                final class User {
                    let id: UUID
                    var name: String
                }

                protocol UserProtocol {
                    var id: UUID {
                        get
                    }
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
    private func `computed property generates get-only accessor`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Counter {
                var count: Int {
                    return 0
                }
            }
            """,
            expandedSource: """
                final class Counter {
                    var count: Int {
                        return 0
                    }
                }

                protocol CounterProtocol {
                    var count: Int {
                        get
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `enum cases skipped but members included`() {
        assertMacroExpansionTesting(
            """
            @Proto
            enum Direction {
                case north
                case south

                var label: String {
                    ""
                }

                func opposite() -> Direction {
                    .north
                }
            }
            """,
            expandedSource: """
                enum Direction {
                    case north
                    case south

                    var label: String {
                        ""
                    }

                    func opposite() -> Direction {
                        .north
                    }
                }

                protocol DirectionProtocol {
                    var label: String {
                        get
                    }
                    func opposite() -> Self
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `enum static members included with .include(.static)`() {
        assertMacroExpansionTesting(
            """
            @Proto(.include(.static))
            enum Theme {
                case light
                case dark

                static func preferred() -> Theme {
                    .light
                }
            }
            """,
            expandedSource: """
                enum Theme {
                    case light
                    case dark

                    static func preferred() -> Theme {
                        .light
                    }
                }

                protocol ThemeProtocol {
                    static func preferred() -> Self
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `async throws method preserved`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Loader {
                func load() async throws -> Data {
                    return Data()
                }
            }
            """,
            expandedSource: """
                final class Loader {
                    func load() async throws -> Data {
                        return Data()
                    }
                }

                protocol LoaderProtocol {
                    func load() async throws -> Data
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `@MainActor propagated to protocol`() {
        assertMacroExpansionTesting(
            """
            @MainActor
            @Proto
            final class ViewModel {
                func update() {
                }
            }
            """,
            expandedSource: """
                @MainActor
                final class ViewModel {
                    func update() {
                    }
                }

                @MainActor
                protocol ViewModelProtocol {
                    func update()
                }
                """,
            macros: testMacros
        )
    }
}
