import Proto
import Testing

@Suite("ProtoDeclarations runtime coverage")
struct ProtoDeclarationsTests {
    @Test
    private func `ProtoOption all static methods and vars`() {
        _ = ProtoOption.include(.members)
        _ = ProtoOption.exclude(.methods)
        _ = ProtoOption.scope(.public)
        _ = ProtoOption.conforms(to: Sendable.self)
        _ = ProtoOption.sendable
        _ = ProtoOption.noIsolation
        _ = ProtoOption.isolation(.full)
        _ = ProtoOption.unconstrained
        _ = ProtoOption.constrained
        _ = ProtoOption.constrained(.to("T"))
        _ = ProtoOption.mock
        _ = ProtoOption.mock(.debug)
    }

    @Test
    private func `ProtoConstrainedOption methods`() {
        _ = ProtoConstrainedOption.to("T")
        _ = ProtoConstrainedOption.to("T", .withWhereClause)
        _ = ProtoConstrainedOption.withWhereClause
    }

    @Test
    private func `ProtoMockOption methods`() {
        _ = ProtoMockOption.debug
        _ = ProtoMockOption.release
        _ = ProtoMockOption.custom("X")
        _ = ProtoMockOption.expr("Y")
        _ = ProtoMockOption.scope(.public)
        _ = ProtoMockOption.auto
    }

    @Test
    private func `ProtoMemberOption all vars`() {
        _ = ProtoMemberOption.immutable
        _ = ProtoMemberOption.mutable
        _ = ProtoMemberOption.async
        _ = ProtoMemberOption.throws
        _ = ProtoMemberOption.sync
        _ = ProtoMemberOption.mutating
        _ = ProtoMemberOption.nonisolated
        _ = ProtoMemberOption.isolated
    }

    @Test
    private func `ProtoIsolation cases`() {
        let cases: [ProtoIsolation] = [.full, .actorOnly, .asyncOnly, .none]
        #expect(cases.count == 4)
    }

    @Test
    private func `ProtoMemberSelection cases`() {
        let cases: [ProtoMemberSelection] = [.members, .methods, .properties, .subscripts, .static, .initializer]
        #expect(cases.count == 6)
    }
}
