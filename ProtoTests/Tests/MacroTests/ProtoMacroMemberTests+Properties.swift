import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroMemberTests {
    @Test
    private func `@ProtoExclude skips marked method`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                func fetchData() -> String {
                    return ""
                }
                @ProtoExclude
                func debugHelper() {
                }
            }
            """,
            expandedSource: """
                final class Service {
                    func fetchData() -> String {
                        return ""
                    }
                    func debugHelper() {
                    }
                }

                protocol ServiceProtocol {
                    func fetchData() -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `private member excluded from protocol`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                func internalMethod() -> String {
                    return ""
                }
                private func helper() {
                }
            }
            """,
            expandedSource: """
                final class Service {
                    func internalMethod() -> String {
                        return ""
                    }
                    private func helper() {
                    }
                }

                protocol ServiceProtocol {
                    func internalMethod() -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `multiple bindings split into separate properties`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Settings {
                var width: Int, height: Int
            }
            """,
            expandedSource: """
                final class Settings {
                    var width: Int, height: Int
                }

                protocol SettingsProtocol {
                    var width: Int {
                        get
                        set
                    }
                    var height: Int {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .immutable makes var get-only`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class User {
                @ProtoMember(.immutable) var name: String
            }
            """,
            expandedSource: """
                final class User {
                    var name: String
                }

                protocol UserProtocol {
                    var name: String {
                        get
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .immutable on let stays get-only`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class User {
                @ProtoMember(.immutable) let id: UUID
            }
            """,
            expandedSource: """
                final class User {
                    let id: UUID
                }

                protocol UserProtocol {
                    var id: UUID {
                        get
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .mutable on let adds setter`() {
        assertMacroExpansionTesting(
            """
            @Proto
            struct Config {
                @ProtoMember(.mutable) let maxRetries: Int
            }
            """,
            expandedSource: """
                struct Config {
                    let maxRetries: Int
                }

                protocol ConfigProtocol {
                    var maxRetries: Int {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .mutating adds mutating to function`() {
        assertMacroExpansionTesting(
            """
            @Proto
            struct Counter {
                @ProtoMember(.mutating) func increment() {
                }
            }
            """,
            expandedSource: """
                struct Counter {
                    func increment() {
                    }
                }

                protocol CounterProtocol {
                    mutating func increment()
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .async adds async to function`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Loader {
                @ProtoMember(.async) func load() -> Data {
                    Data()
                }
            }
            """,
            expandedSource: """
                final class Loader {
                    func load() -> Data {
                        Data()
                    }
                }

                protocol LoaderProtocol {
                    func load() async -> Data
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .throws adds throws to function`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Loader {
                @ProtoMember(.throws) func load() -> Data {
                    Data()
                }
            }
            """,
            expandedSource: """
                final class Loader {
                    func load() -> Data {
                        Data()
                    }
                }

                protocol LoaderProtocol {
                    func load() throws -> Data
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - willSet/didSet generates { get set }

    @Test
    private func `willSet property generates get set`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Observed {
                var value: Int {
                    willSet { print(newValue) }
                }
            }
            """,
            expandedSource: """
                final class Observed {
                    var value: Int {
                        willSet { print(newValue) }
                    }
                }

                protocol ObservedProtocol {
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
    private func `didSet property generates get set`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Observed {
                var value: Int {
                    didSet { print(oldValue) }
                }
            }
            """,
            expandedSource: """
                final class Observed {
                    var value: Int {
                        didSet { print(oldValue) }
                    }
                }

                protocol ObservedProtocol {
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
    private func `willSet + didSet property generates get set`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Observed {
                var value: Int {
                    willSet { }
                    didSet { }
                }
            }
            """,
            expandedSource: """
                final class Observed {
                    var value: Int {
                        willSet { }
                        didSet { }
                    }
                }

                protocol ObservedProtocol {
                    var value: Int {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Property wrapper attributes stripped

    @Test
    private func `@State attribute stripped from protocol requirement`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class ViewModel {
                @State var name: String
            }
            """,
            expandedSource: """
                final class ViewModel {
                    @State var name: String
                }

                protocol ViewModelProtocol {
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
    private func `@Published attribute stripped from protocol requirement`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class ViewModel {
                @Published var count: Int
            }
            """,
            expandedSource: """
                final class ViewModel {
                    @Published var count: Int
                }

                protocol ViewModelProtocol {
                    var count: Int {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - weak/unowned/lazy stripped

    @Test
    private func `weak modifier stripped from protocol requirement`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                weak var delegate: AnyObject?
            }
            """,
            expandedSource: """
                final class Service {
                    weak var delegate: AnyObject?
                }

                protocol ServiceProtocol {
                    var delegate: AnyObject? {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `lazy modifier stripped from protocol requirement`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Cache {
                lazy var data: [String] = []
            }
            """,
            expandedSource: """
                final class Cache {
                    lazy var data: [String] = []
                }

                protocol CacheProtocol {
                    var data: [String] {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - unowned modifier stripped

    @Test
    private func `unowned modifier stripped from protocol requirement`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                unowned var owner: AnyObject
            }
            """,
            expandedSource: """
                final class Service {
                    unowned var owner: AnyObject
                }

                protocol ServiceProtocol {
                    var owner: AnyObject {
                        get
                        set
                    }
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - @objc members

    @Test
    private func `@objc attribute preserved on protocol requirement`() {
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

    // MARK: - @discardableResult preservation

    @Test
    private func `@discardableResult attribute preserved on protocol requirement`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Builder {
                @discardableResult
                func build() -> String {
                    ""
                }
            }
            """,
            expandedSource: """
                final class Builder {
                    @discardableResult
                    func build() -> String {
                        ""
                    }
                }

                protocol BuilderProtocol {
                    @discardableResult
                    func build() -> String
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `protoMember .async adds async getter to property`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Store {
                @ProtoMember(.async) var count: Int
            }
            """,
            expandedSource: """
                final class Store {
                    var count: Int
                }

                protocol StoreProtocol {
                    var count: Int {
                        get async
                    }
                }
                """,
            macros: testMacros
        )
    }
}
