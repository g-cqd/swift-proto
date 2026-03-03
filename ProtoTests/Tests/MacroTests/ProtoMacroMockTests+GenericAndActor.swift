import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroMockTests {
    // MARK: - Generic class mock generation

    @Test
    func `mock on generic class generates generic mock with associatedtype`() {
        assertMacroExpansionTesting(
            GenericAndActorFixture.genericClassInput,
            expandedSource: GenericAndActorFixture.genericClassExpanded,
            macros: testMacros
        )
    }

    // MARK: - Actor mock generation

    @Test
    func `mock on actor generates actor mock with Actor conformance`() {
        assertMacroExpansionTesting(
            GenericAndActorFixture.actorMockInput,
            expandedSource: GenericAndActorFixture.actorMockExpanded,
            macros: testMacros
        )
    }

    // MARK: - Mock + constrained generics

    @Test
    func `mock with constrained generates constrained protocol and generic mock`() {
        assertMacroExpansionTesting(
            GenericAndActorFixture.mockConstrainedInput,
            expandedSource: GenericAndActorFixture.mockConstrainedExpanded,
            macros: testMacros
        )
    }

    // MARK: - Mock + conforms(to:) with multiple conformances

    @Test
    func `mock with conforms to multiple protocols generates unchecked Sendable`() {
        assertMacroExpansionTesting(
            GenericAndActorFixture.mockConformsInput,
            expandedSource: GenericAndActorFixture.mockConformsExpanded,
            macros: testMacros
        )
    }

    // MARK: - Actor with generic parameters

    @Test
    func `actor with generic parameters generates protocol with associatedtypes`() {
        assertMacroExpansionTesting(
            ActorFixture.actorGenericInput,
            expandedSource: ActorFixture.actorGenericExpanded,
            macros: testMacros
        )
    }

    // MARK: - Actor mock with noIsolation generates class mock

    @Test
    func `actor mock with noIsolation generates class mock without Actor`() {
        assertMacroExpansionTesting(
            ActorFixture.actorMockNoIsolationInput,
            expandedSource: ActorFixture.actorMockNoIsolationExpanded,
            macros: testMacros
        )
    }
}
