import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroMemberTests {
    // MARK: - Duplicate mutating guard

    @Test
    private func `already-mutating function with .mutating does not duplicate modifier`() {
        assertMacroExpansionTesting(
            """
            @Proto
            struct Counter {
                @ProtoMember(.mutating) mutating func increment() {
                }
            }
            """,
            expandedSource: """
                struct Counter {
                    mutating func increment() {
                    }
                }

                protocol CounterProtocol {
                    mutating func increment()
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - @ProtoMember on initializer warns

    @Test
    private func `@ProtoMember with options on initializer emits warning`() {
        assertMacroExpansionTesting(
            """
            @Proto(.include(.initializer))
            final class Service {
                @ProtoMember(.async) init(name: String) {
                }
            }
            """,
            expandedSource: """
                final class Service {
                    init(name: String) {
                    }
                }

                protocol ServiceProtocol {
                    init(name: String)
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@ProtoMember options have no effect on initializers",
                    line: 3,
                    column: 5,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    // MARK: - class func / class var handling

    @Test
    private func `class func included with .include(.static), class modifier stripped`() {
        assertMacroExpansionTesting(
            """
            @Proto(.include(.static))
            class Service {
                class func make() -> Service {
                    Service()
                }
            }
            """,
            expandedSource: """
                class Service {
                    class func make() -> Service {
                        Service()
                    }
                }

                protocol ServiceProtocol {
                    func make() -> Self
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Setter access-level filtering

    @Test
    private func `public type with private(set) property generates get-only requirement`() {
        assertMacroExpansionTesting(
            """
            @Proto
            public final class User {
                public private(set) var name: String = ""
            }
            """,
            expandedSource: """
                public final class User {
                    public private(set) var name: String = ""
                }

                public protocol UserProtocol {
                    var name: String {
                        get
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - deinit and nested type skipping

    @Test
    private func `deinit and nested types are skipped`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                func work() {
                }
                deinit {
                }
                struct Config {
                    var value: Int
                }
            }
            """,
            expandedSource: """
                final class Service {
                    func work() {
                    }
                    deinit {
                    }
                    struct Config {
                        var value: Int
                    }
                }

                protocol ServiceProtocol {
                    func work()
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Variadic parameters

    @Test
    private func `variadic parameters preserved in protocol requirement`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Logger {
                func log(_ items: Any...) {
                }
            }
            """,
            expandedSource: """
                final class Logger {
                    func log(_ items: Any...) {
                    }
                }

                protocol LoggerProtocol {
                    func log(_ items: Any...)
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Static operators with .include(.static)

    @Test
    private func `static operator included with .include(.static)`() {
        assertMacroExpansionTesting(
            """
            @Proto(.include(.static))
            struct Vector {
                var x: Double
                static func + (lhs: Vector, rhs: Vector) -> Vector {
                    Vector(x: lhs.x + rhs.x)
                }
            }
            """,
            expandedSource: """
                struct Vector {
                    var x: Double
                    static func + (lhs: Vector, rhs: Vector) -> Vector {
                        Vector(x: lhs.x + rhs.x)
                    }
                }

                protocol VectorProtocol {
                    var x: Double {
                        get
                        set
                    }
                    static func + (lhs: Self, rhs: Self) -> Self
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Typed throws preservation

    @Test
    private func `typed throws clause preserved in protocol requirement`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Parser {
                func parse(_ input: String) throws(ParseError) -> Int {
                    0
                }
            }
            """,
            expandedSource: """
                final class Parser {
                    func parse(_ input: String) throws(ParseError) -> Int {
                        0
                    }
                }

                protocol ParserProtocol {
                    func parse(_ input: String) throws(ParseError) -> Int
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - _read coroutine accessor

    @Test
    private func `_read accessor produces get-only requirement`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Store {
                var value: Int {
                    _read { yield 42 }
                }
            }
            """,
            expandedSource: """
                final class Store {
                    var value: Int {
                        _read { yield 42 }
                    }
                }

                protocol StoreProtocol {
                    var value: Int {
                        get
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `non-final class generates protocol`() {
        assertMacroExpansionTesting(
            """
            @Proto
            class Service {
                func work() {
                }
            }
            """,
            expandedSource: """
                class Service {
                    func work() {
                    }
                }

                protocol ServiceProtocol {
                    func work()
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - @objc members

    @Test
    private func `@objc attribute preserved on function`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                @objc func work() {
                }
            }
            """,
            expandedSource: """
                final class Service {
                    @objc func work() {
                    }
                }

                protocol ServiceProtocol {
                    @objc func work()
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Nested @Proto types skipped

    @Test
    private func `nested type not included in protocol`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Container {
                func process() -> String { "" }
                struct Nested {
                    var value: Int
                }
                enum Kind {
                    case a
                }
            }
            """,
            expandedSource: """
                final class Container {
                    func process() -> String { "" }
                    struct Nested {
                        var value: Int
                    }
                    enum Kind {
                        case a
                    }
                }

                protocol ContainerProtocol {
                    func process() -> String
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - @retroactive conformance stripped

    @Test
    private func `@retroactive attribute stripped from protocol requirement`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                @discardableResult func work() -> String {
                    ""
                }
            }
            """,
            expandedSource: """
                final class Service {
                    @discardableResult func work() -> String {
                        ""
                    }
                }

                protocol ServiceProtocol {
                    @discardableResult func work() -> String
                }
                """,
            macros: testMacros
        )
    }
}
