import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroTypeFeatureTests {
    @Test
    private func `constrained .to() single parameter`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.to("Element")))
            final class SortedCollection<Element> where Element: Comparable & Hashable {
                func insert(_ element: Element) {
                }
            }
            """,
            expandedSource: """
                final class SortedCollection<Element> where Element: Comparable & Hashable {
                    func insert(_ element: Element) {
                    }
                }

                protocol SortedCollectionProtocol<Element> {
                    associatedtype Element
                    func insert(_ element: Element)
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `constrained .to() multiple parameters`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.to("Key", "Value")))
            final class Store<Key: Hashable, Value> {
                func get(_ key: Key) -> Value? {
                    nil
                }
            }
            """,
            expandedSource: """
                final class Store<Key: Hashable, Value> {
                    func get(_ key: Key) -> Value? {
                        nil
                    }
                }

                protocol StoreProtocol<Key, Value> {
                    associatedtype Key: Hashable
                    associatedtype Value
                    func get(_ key: Key) -> Value?
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `constrained .to() repeated calls merged`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.to("Key"), .to("Value")))
            final class Store<Key: Hashable, Value> {
                func get(_ key: Key) -> Value? {
                    nil
                }
            }
            """,
            expandedSource: """
                final class Store<Key: Hashable, Value> {
                    func get(_ key: Key) -> Value? {
                        nil
                    }
                }

                protocol StoreProtocol<Key, Value> {
                    associatedtype Key: Hashable
                    associatedtype Value
                    func get(_ key: Key) -> Value?
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `bare .constrained constrains all parameters`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained)
            final class Box<T> {
                var value: T
            }
            """,
            expandedSource: """
                final class Box<T> {
                    var value: T
                }

                protocol BoxProtocol<T> {
                    associatedtype T
                    var value: T {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `bare constrained omits where clause by default`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained)
            final class Box<T> where T: Equatable {
                var value: T
            }
            """,
            expandedSource: """
                final class Box<T> where T: Equatable {
                    var value: T
                }

                protocol BoxProtocol<T> {
                    associatedtype T
                    var value: T {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `constrained .to() omits where clause by default`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.to("Key")))
            final class Cache<Key: Hashable, Value> where Value: Codable {
                func get(_ key: Key) -> Value? {
                    nil
                }
            }
            """,
            expandedSource: """
                final class Cache<Key: Hashable, Value> where Value: Codable {
                    func get(_ key: Key) -> Value? {
                        nil
                    }
                }

                protocol CacheProtocol<Key> {
                    associatedtype Key: Hashable
                    associatedtype Value
                    func get(_ key: Key) -> Value?
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - .withWhereClause tests

    @Test
    private func `constrained .withWhereClause keeps all where clauses`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.withWhereClause))
            final class Box<T> where T: Equatable {
                var value: T
            }
            """,
            expandedSource: """
                final class Box<T> where T: Equatable {
                    var value: T
                }

                protocol BoxProtocol<T> where T: Equatable {
                    associatedtype T
                    var value: T {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `constrained .to() with .withWhereClause per-parameter`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.to("Key", .withWhereClause), .to("Value")))
            final class Cache<Key: Hashable, Value> where Key: Codable, Value: Codable {
                func get(_ key: Key) -> Value? {
                    nil
                }
            }
            """,
            expandedSource: """
                final class Cache<Key: Hashable, Value> where Key: Codable, Value: Codable {
                    func get(_ key: Key) -> Value? {
                        nil
                    }
                }

                protocol CacheProtocol<Key, Value> where Key: Codable {
                    associatedtype Key: Hashable
                    associatedtype Value
                    func get(_ key: Key) -> Value?
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `constrained .to() single name preserves where clause for that param only`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.to("Input", .withWhereClause), .to("Output")))
            final class Mapper<Input, Output> where Input: Collection, Output: Collection, \
            Input.Element == Output.Element {
                func map(_ input: Input) -> Output {
                    preconditionFailure()
                }
            }
            """,
            expandedSource: """
                final class Mapper<Input, Output> where Input: Collection, Output: Collection, \
                Input.Element == Output.Element {
                    func map(_ input: Input) -> Output {
                        preconditionFailure()
                    }
                }

                protocol MapperProtocol<Input, Output> where Input: Collection, Input.Element == Output.Element {
                    associatedtype Input
                    associatedtype Output
                    func map(_ input: Input) -> Output
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Constrained type name validation

    @Test
    private func `constrained .to() with non-existent generic parameter warns`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.to("Nonexistent")))
            final class Box<T> {
                var value: T
            }
            """,
            expandedSource: """
                final class Box<T> {
                    var value: T
                }

                protocol BoxProtocol<Nonexistent> {
                    associatedtype T
                    var value: T {
                        get
                        set
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'Nonexistent' does not match any generic parameter; it will be ignored",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    // MARK: - Duplicate constrained names deduplicated

    @Test
    private func `duplicate constrained .to() names are deduplicated`() {
        assertMacroExpansionTesting(
            """
            @Proto(.constrained(.to("Key"), .to("Key")))
            final class Store<Key: Hashable, Value> {
                func get(_ key: Key) -> Value? {
                    nil
                }
            }
            """,
            expandedSource: """
                final class Store<Key: Hashable, Value> {
                    func get(_ key: Key) -> Value? {
                        nil
                    }
                }

                protocol StoreProtocol<Key> {
                    associatedtype Key: Hashable
                    associatedtype Value
                    func get(_ key: Key) -> Value?
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Self Type Replacement

    @Test
    private func `static method return type replaced with Self`() {
        assertMacroExpansionTesting(
            """
            @Proto(.include(.static))
            final class Manager {
                static func shared() -> Manager {
                    Manager()
                }
            }
            """,
            expandedSource: """
                final class Manager {
                    static func shared() -> Manager {
                        Manager()
                    }
                }

                protocol ManagerProtocol {
                    static func shared() -> Self
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `builder pattern return type replaced with Self`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Builder {
                func withName(_ name: String) -> Builder {
                    return self
                }
            }
            """,
            expandedSource: """
                final class Builder {
                    func withName(_ name: String) -> Builder {
                        return self
                    }
                }

                protocol BuilderProtocol {
                    func withName(_ name: String) -> Self
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `parameter type replaced with Self`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Node {
                func connect(to other: Node) {
                }
            }
            """,
            expandedSource: """
                final class Node {
                    func connect(to other: Node) {
                    }
                }

                protocol NodeProtocol {
                    func connect(to other: Self)
                }
                """,
            macros: testMacros
        )
    }
}
