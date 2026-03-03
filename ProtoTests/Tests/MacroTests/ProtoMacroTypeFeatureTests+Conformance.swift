import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroTypeFeatureTests {
    // MARK: - Typealias Resolution

    @Test
    private func `typealias resolved in protocol signature`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class UserService {
                typealias ID = String
                func find(by id: ID) -> ID {
                    ""
                }
            }
            """,
            expandedSource: """
                final class UserService {
                    typealias ID = String
                    func find(by id: ID) -> ID {
                        ""
                    }
                }

                protocol UserServiceProtocol {
                    func find(by id: String) -> String
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - conforms(to:)

    @Test
    private func `single .conforms(to:) adds inheritance`() {
        assertMacroExpansionTesting(
            """
            @Proto(.conforms(to: Identifiable.self))
            final class User {
                var id: String
            }
            """,
            expandedSource: """
                final class User {
                    var id: String
                }

                protocol UserProtocol: Identifiable {
                    var id: String {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `sendable shorthand adds Sendable inheritance`() {
        assertMacroExpansionTesting(
            """
            @Proto(.sendable)
            final class Worker {
                func run() {
                }
            }
            """,
            expandedSource: """
                final class Worker {
                    func run() {
                    }
                }

                protocol WorkerProtocol: Sendable {
                    func run()
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `sendable shorthand and conforms do not duplicate Sendable`() {
        assertMacroExpansionTesting(
            """
            @Proto(.sendable, .conforms(to: Sendable.self, Codable.self))
            final class Payload {
                var value: Int
            }
            """,
            expandedSource: """
                final class Payload {
                    var value: Int
                }

                protocol PayloadProtocol: Sendable, Codable {
                    var value: Int {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `multiple .conforms(to:) in single call`() {
        assertMacroExpansionTesting(
            """
            @Proto(.conforms(to: Sendable.self, Codable.self))
            final class Foo {
                var value: Int
            }
            """,
            expandedSource: """
                final class Foo {
                    var value: Int
                }

                protocol FooProtocol: Sendable, Codable {
                    var value: Int {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `repeated .conforms(to:) calls merged`() {
        assertMacroExpansionTesting(
            """
            @Proto(.conforms(to: Identifiable.self), .conforms(to: Equatable.self))
            final class User {
                var id: String
            }
            """,
            expandedSource: """
                final class User {
                    var id: String
                }

                protocol UserProtocol: Identifiable, Equatable {
                    var id: String {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `actor with .conforms(to:) adds after Actor`() {
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

    @Test
    private func `conforms to AnyObject adds class constraint`() {
        assertMacroExpansionTesting(
            """
            @Proto(.conforms(to: AnyObject.self))
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

                protocol ServiceProtocol: AnyObject {
                    func work()
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `@preconcurrency propagated to protocol`() {
        assertMacroExpansionTesting(
            """
            @preconcurrency
            @Proto
            final class LegacyService {
                func process() -> String {
                    ""
                }
            }
            """,
            expandedSource: """
                @preconcurrency
                final class LegacyService {
                    func process() -> String {
                        ""
                    }
                }

                @preconcurrency
                protocol LegacyServiceProtocol {
                    func process() -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `initializer default parameters stripped`() {
        assertMacroExpansionTesting(
            """
            @Proto(.include(.initializer))
            final class Service {
                init(timeout: Int = 30) {
                }
                func work() {
                }
            }
            """,
            expandedSource: """
                final class Service {
                    init(timeout: Int = 30) {
                    }
                    func work() {
                    }
                }

                protocol ServiceProtocol {
                    init(timeout: Int)
                    func work()
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Multi-hop typealias resolution

    @Test
    private func `multi-hop typealias chain resolved to concrete type`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class UserService {
                typealias UserID = String
                typealias ID = UserID
                func find(by id: ID) -> ID {
                    ""
                }
            }
            """,
            expandedSource: """
                final class UserService {
                    typealias UserID = String
                    typealias ID = UserID
                    func find(by id: ID) -> ID {
                        ""
                    }
                }

                protocol UserServiceProtocol {
                    func find(by id: String) -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `three-level typealias chain resolved to concrete type`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                typealias C = String
                typealias B = C
                typealias A = B
                func process(_ value: A) -> B {
                    ""
                }
            }
            """,
            expandedSource: """
                final class Service {
                    typealias C = String
                    typealias B = C
                    typealias A = B
                    func process(_ value: A) -> B {
                        ""
                    }
                }

                protocol ServiceProtocol {
                    func process(_ value: String) -> String
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Stress test with many members (TEST-04)

    @Test
    private func `type with 50 members generates protocol without issues`() {
        var memberDefs = ""
        var protocolDefs = ""
        for i in 0..<50 {
            memberDefs += "    func method\(i)(_ arg: Int) -> String { \"\" }\n"
            protocolDefs += "\n    func method\(i)(_ arg: Int) -> String"
        }
        let input = """
            @Proto
            final class BigService {
            \(memberDefs)}
            """
        let expected = """
            final class BigService {
            \(memberDefs)}

            protocol BigServiceProtocol {\(protocolDefs)
            }
            """
        assertMacroExpansionTesting(
            input,
            expandedSource: expected,
            macros: testMacros
        )
    }

    @Test
    private func `multiple combined options applied together`() {
        assertMacroExpansionTesting(
            """
            @Proto(.include(.static), .scope(.public), .conforms(to: Sendable.self))
            final class Service {
                static func shared() -> Service { Service() }
                func work() {
                }
                private func helper() {
                }
            }
            """,
            expandedSource: """
                final class Service {
                    static func shared() -> Service { Service() }
                    func work() {
                    }
                    private func helper() {
                    }
                }

                public protocol ServiceProtocol: Sendable {
                    static func shared() -> Self
                    func work()
                }
                """,
            macros: testMacros
        )
    }
}
