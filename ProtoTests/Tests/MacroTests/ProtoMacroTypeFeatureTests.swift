import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite("Type features and generics")
struct ProtoMacroTypeFeatureTests {
    @Test
    private func `@Sendable closure parameter preserved`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Runner {
                func run(_ block: @Sendable () -> Void) {
                }
            }
            """,
            expandedSource: """
                final class Runner {
                    func run(_ block: @Sendable () -> Void) {
                    }
                }

                protocol RunnerProtocol {
                    func run(_ block: @Sendable () -> Void)
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `generic method preserved in protocol`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Transformer {
                func map<U>(_ transform: (String) -> U) -> U {
                    preconditionFailure()
                }
            }
            """,
            expandedSource: """
                final class Transformer {
                    func map<U>(_ transform: (String) -> U) -> U {
                        preconditionFailure()
                    }
                }

                protocol TransformerProtocol {
                    func map<U>(_ transform: (String) -> U) -> U
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `generic type generates associatedtype`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Box<T> {
                var value: T
            }
            """,
            expandedSource: """
                final class Box<T> {
                    var value: T
                }

                protocol BoxProtocol {
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
    private func `generic type with constraints preserved`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Cache<Key: Hashable, Value> {
                func get(_ key: Key) -> Value? {
                    nil
                }
            }
            """,
            expandedSource: """
                final class Cache<Key: Hashable, Value> {
                    func get(_ key: Key) -> Value? {
                        nil
                    }
                }

                protocol CacheProtocol {
                    associatedtype Key: Hashable
                    associatedtype Value
                    func get(_ key: Key) -> Value?
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `subscript included in protocol`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Collection {
                subscript(index: Int) -> String {
                    return ""
                }
            }
            """,
            expandedSource: """
                final class Collection {
                    subscript(index: Int) -> String {
                        return ""
                    }
                }

                protocol CollectionProtocol {
                    subscript(index: Int) -> String {
                        get
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `@available attribute propagated to protocol`() {
        assertMacroExpansionTesting(
            """
            @available(iOS 16, macOS 13, *)
            @Proto
            final class ModernService {
                func process() -> String {
                    ""
                }
            }
            """,
            expandedSource: """
                @available(iOS 16, macOS 13, *)
                final class ModernService {
                    func process() -> String {
                        ""
                    }
                }

                @available(iOS 16, macOS 13, *)
                protocol ModernServiceProtocol {
                    func process() -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `@available and @MainActor combined on protocol`() {
        assertMacroExpansionTesting(
            """
            @available(iOS 16, *)
            @MainActor
            @Proto
            final class ViewModel {
                func update() {
                }
            }
            """,
            expandedSource: """
                @available(iOS 16, *)
                @MainActor
                final class ViewModel {
                    func update() {
                    }
                }

                @available(iOS 16, *)
                @MainActor
                protocol ViewModelProtocol {
                    func update()
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `generic type with where clause omitted by default`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Store<T, U> where T: Equatable, U: Collection, U.Element == T {
                func find(_ item: T) -> U? {
                    nil
                }
            }
            """,
            expandedSource: """
                final class Store<T, U> where T: Equatable, U: Collection, U.Element == T {
                    func find(_ item: T) -> U? {
                        nil
                    }
                }

                protocol StoreProtocol {
                    associatedtype T
                    associatedtype U
                    func find(_ item: T) -> U?
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `inline constraints combined with where clause omitted by default`() {
        assertMacroExpansionTesting(
            """
            @Proto
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

                protocol CacheProtocol {
                    associatedtype Key: Hashable
                    associatedtype Value
                    func get(_ key: Key) -> Value?
                }
                """,
            macros: testMacros
        )
    }
}
