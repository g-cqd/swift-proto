import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

// MARK: - Medium-priority test gap coverage

extension ProtoMacroActorTests {
    // MARK: - Sendable on actor produces no @unchecked Sendable

    @Test
    func `sendable conformance on actor omits unchecked Sendable`() {
        assertMacroExpansionTesting(
            """
            @Proto(.conforms(to: Sendable.self))
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

                protocol DataStoreProtocol: Actor, Sendable {
                    func fetch() async -> String
                }
                """,
            macros: testMacros
        )
    }
}

extension ProtoMacroMockTests {
    // MARK: - Mock with inout parameters

    @Test
    func `mock with inout parameter generates correct handler and argument type`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock)
            final class Mutator {
                func update(_ value: inout String) {
                }
            }
            """,
            expandedSource: """
                final class Mutator {
                    func update(_ value: inout String) {
                    }
                }

                protocol MutatorProtocol {
                    func update(_ value: inout String)
                }

                final class MutatorMock: MutatorProtocol {
                    private(set) var updateCallCount = 0
                    private(set) var updateReceivedArguments: [inout String] = []
                    var updateHandler: ((inout String) -> Void)?

                    init(
                        updateHandler: ((inout String) -> Void)? = nil
                    ) {
                        self.updateHandler = updateHandler
                    }

                    func update(_ value: inout String) {
                        updateCallCount += 1
                        updateReceivedArguments.append(value)
                        if let handler = updateHandler {
                            handler(value)
                            return
                        }
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - @ProtoMockIgnored on property

    @Test
    func `ProtoMockIgnored on property still generates stub`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock)
            final class Config {
                @ProtoMockIgnored
                var debugMode: Bool {
                    false
                }
            }
            """,
            expandedSource: """
                final class Config {
                    var debugMode: Bool {
                        false
                    }
                }

                protocol ConfigProtocol {
                    var debugMode: Bool {
                        get
                    }
                }

                final class ConfigMock: ConfigProtocol {
                    var debugMode: Bool {
                        get {
                            ProtoMockFailureHandling.fail("Unstubbed property 'debugMode' on ConfigMock")
                        }
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - @ProtoMockIgnored on subscript

    @Test
    func `ProtoMockIgnored on subscript still generates stub`() {
        assertMacroExpansionTesting(
            """
            @Proto(.mock)
            final class Container {
                @ProtoMockIgnored
                subscript(index: Int) -> String {
                    ""
                }
            }
            """,
            expandedSource: """
                final class Container {
                    subscript(index: Int) -> String {
                        ""
                    }
                }

                protocol ContainerProtocol {
                    subscript(index: Int) -> String {
                        get
                    }
                }

                final class ContainerMock: ContainerProtocol {
                    subscript(index: Int) -> String {
                        get {
                            ProtoMockFailureHandling.fail("Unstubbed subscript on ContainerMock")
                        }
                    }
                }
                """,
            macros: testMacros
        )
    }
}

extension ProtoMacroConfigTests {
    // MARK: - .exclude(.methods) individually

    @Test
    func `exclude methods keeps properties and subscripts`() {
        assertMacroExpansionTesting(
            """
            @Proto(.exclude(.methods))
            final class Service {
                var name: String = ""
                func work() {
                }
                subscript(index: Int) -> String {
                    ""
                }
            }
            """,
            expandedSource: """
                final class Service {
                    var name: String = ""
                    func work() {
                    }
                    subscript(index: Int) -> String {
                        ""
                    }
                }

                protocol ServiceProtocol {
                    var name: String {
                        get
                        set
                    }
                    subscript(index: Int) -> String {
                        get
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - .exclude(.subscripts) individually

    @Test
    func `exclude subscripts keeps methods and properties`() {
        assertMacroExpansionTesting(
            """
            @Proto(.exclude(.subscripts))
            final class Indexer {
                var count: Int = 0
                func reset() {
                }
                subscript(index: Int) -> String {
                    ""
                }
            }
            """,
            expandedSource: """
                final class Indexer {
                    var count: Int = 0
                    func reset() {
                    }
                    subscript(index: Int) -> String {
                        ""
                    }
                }

                protocol IndexerProtocol {
                    var count: Int {
                        get
                        set
                    }
                    func reset()
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - .scope(.private)

    @Test
    func `scope private generates private protocol`() {
        assertMacroExpansionTesting(
            """
            @Proto(.scope(.private))
            final class Helper {
                func assist() {
                }
            }
            """,
            expandedSource: """
                final class Helper {
                    func assist() {
                    }
                }

                private protocol HelperProtocol {
                    func assist()
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - .scope(.fileprivate)

    @Test
    func `scope fileprivate generates fileprivate protocol`() {
        assertMacroExpansionTesting(
            """
            @Proto(.scope(.fileprivate))
            final class Utility {
                func run() {
                }
            }
            """,
            expandedSource: """
                final class Utility {
                    func run() {
                    }
                }

                fileprivate protocol UtilityProtocol {
                    func run()
                }
                """,
            macros: testMacros
        )
    }
}

// MARK: - Type inference edge cases

extension ProtoMacroMemberTests {
    // MARK: - Empty array literal inference fails

    @Test
    func `empty array literal cannot be inferred`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Store {
                var items = []
            }
            """,
            expandedSource: """
                final class Store {
                    var items = []
                }

                protocol StoreProtocol {
                }
                """,
            diagnostics: [
                .init(message: "Property type cannot be inferred; add an explicit type annotation", line: 3, column: 5)
            ],
            macros: testMacros
        )
    }

    // MARK: - Empty dictionary literal inference fails

    @Test
    func `empty dictionary literal cannot be inferred`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Cache {
                var data = [:]
            }
            """,
            expandedSource: """
                final class Cache {
                    var data = [:]
                }

                protocol CacheProtocol {
                }
                """,
            diagnostics: [
                .init(message: "Property type cannot be inferred; add an explicit type annotation", line: 3, column: 5)
            ],
            macros: testMacros
        )
    }
}
