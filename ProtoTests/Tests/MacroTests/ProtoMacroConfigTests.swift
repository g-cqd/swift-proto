import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite("Proto macro configuration")
struct ProtoMacroConfigTests {
    @Test
    private func `static members excluded by default`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Manager {
                static func shared() -> Manager {
                    return Manager()
                }
                func doWork() {
                }
            }
            """,
            expandedSource: """
                final class Manager {
                    static func shared() -> Manager {
                        return Manager()
                    }
                    func doWork() {
                    }
                }

                protocol ManagerProtocol {
                    func doWork()
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `static members included with .include(.static)`() {
        assertMacroExpansionTesting(
            """
            @Proto(.include(.static))
            final class Manager {
                static func shared() -> Manager {
                    return Manager()
                }
                func doWork() {
                }
            }
            """,
            expandedSource: """
                final class Manager {
                    static func shared() -> Manager {
                        return Manager()
                    }
                    func doWork() {
                    }
                }

                protocol ManagerProtocol {
                    static func shared() -> Self
                    func doWork()
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `initializer included with .include(.initializer)`() {
        assertMacroExpansionTesting(
            """
            @Proto(.include(.initializer))
            final class Service {
                init(name: String) {
                }
                func work() {
                }
            }
            """,
            expandedSource: """
                final class Service {
                    init(name: String) {
                    }
                    func work() {
                    }
                }

                protocol ServiceProtocol {
                    init(name: String)
                    func work()
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `include both initializer and static members`() {
        assertMacroExpansionTesting(
            """
            @Proto(.include(.initializer, .static))
            final class Builder {
                init(seed: Int) {
                }
                static func make() -> Builder {
                    Builder(seed: 0)
                }
                func build() -> Int {
                    1
                }
            }
            """,
            expandedSource: """
                final class Builder {
                    init(seed: Int) {
                    }
                    static func make() -> Builder {
                        Builder(seed: 0)
                    }
                    func build() -> Int {
                        1
                    }
                }

                protocol BuilderProtocol {
                    init(seed: Int)
                    static func make() -> Self
                    func build() -> Int
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `exclude static overrides include static`() {
        assertMacroExpansionTesting(
            """
            @Proto(.include(.static), .exclude(.static))
            final class Registry {
                static func shared() -> Registry {
                    Registry()
                }
                func resolve() -> String {
                    ""
                }
            }
            """,
            expandedSource: """
                final class Registry {
                    static func shared() -> Registry {
                        Registry()
                    }
                    func resolve() -> String {
                        ""
                    }
                }

                protocol RegistryProtocol {
                    func resolve() -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `exclude properties keeps only methods`() {
        assertMacroExpansionTesting(
            """
            @Proto(.exclude(.properties))
            struct Config {
                var timeout: Int
                func validate() -> Bool {
                    true
                }
            }
            """,
            expandedSource: """
                struct Config {
                    var timeout: Int
                    func validate() -> Bool {
                        true
                    }
                }

                protocol ConfigProtocol {
                    func validate() -> Bool
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `exclude members then include methods only`() {
        assertMacroExpansionTesting(
            """
            @Proto(.exclude(.members), .include(.methods))
            final class Service {
                var name: String = ""
                func work() {
                }
                subscript(index: Int) -> String {
                    name
                }
            }
            """,
            expandedSource: """
                final class Service {
                    var name: String = ""
                    func work() {
                    }
                    subscript(index: Int) -> String {
                        name
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
