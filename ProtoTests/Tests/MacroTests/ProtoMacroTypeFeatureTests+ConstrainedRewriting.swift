import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroTypeFeatureTests {
    // MARK: - MemberTypeSyntax base type rewriting

    @Test
    private func `member type Foo.Bar rewritten to Self.Bar when Foo is the declaring type`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Container {
                struct Item {
                    var value: Int
                }
                func items() -> [Container.Item] {
                    []
                }
            }
            """,
            expandedSource: """
                final class Container {
                    struct Item {
                        var value: Int
                    }
                    func items() -> [Container.Item] {
                        []
                    }
                }

                protocol ContainerProtocol {
                    func items() -> [Self.Item]
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `unrelated type not replaced with Self`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Service {
                func fetchName() -> String {
                    ""
                }
            }
            """,
            expandedSource: """
                final class Service {
                    func fetchName() -> String {
                        ""
                    }
                }

                protocol ServiceProtocol {
                    func fetchName() -> String
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Three-level nested member type rewriting (SAFE-01)

    @Test
    private func `three-level nested member type Foo.Bar.Baz rewritten to Self.Bar.Baz`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Outer {
                struct Inner {
                    struct Leaf {
                        var value: Int
                    }
                }
                func getLeaf() -> Outer.Inner.Leaf {
                    Outer.Inner.Leaf(value: 0)
                }
            }
            """,
            expandedSource: """
                final class Outer {
                    struct Inner {
                        struct Leaf {
                            var value: Int
                        }
                    }
                    func getLeaf() -> Outer.Inner.Leaf {
                        Outer.Inner.Leaf(value: 0)
                    }
                }

                protocol OuterProtocol {
                    func getLeaf() -> Self.Inner.Leaf
                }
                """,
            macros: testMacros
        )
    }

    // MARK: - Protocol composition constraints (TEST-02)

    @Test
    private func `protocol composition constraint in where clause omitted by default`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Registry<T> where T: Hashable & Codable {
                func register(_ item: T) {
                }
            }
            """,
            expandedSource: """
                final class Registry<T> where T: Hashable & Codable {
                    func register(_ item: T) {
                    }
                }

                protocol RegistryProtocol {
                    associatedtype T
                    func register(_ item: T)
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `same-type requirement in where clause omitted by default`() {
        assertMacroExpansionTesting(
            """
            @Proto
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

                protocol MapperProtocol {
                    associatedtype Input
                    associatedtype Output
                    func map(_ input: Input) -> Output
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `nested type in generic position rewritten`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class Wrapper {
                struct Tag {}
                func tags() -> Array<Wrapper.Tag> {
                    []
                }
            }
            """,
            expandedSource: """
                final class Wrapper {
                    struct Tag {}
                    func tags() -> Array<Wrapper.Tag> {
                        []
                    }
                }

                protocol WrapperProtocol {
                    func tags() -> Array<Self.Tag>
                }
                """,
            macros: testMacros
        )
    }
}
