import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroMockTests {
    // MARK: - Auto-default: basic function returning protocol type

    @Test
    func `auto-default returns mock for function returning protocol type`() {
        assertMacroExpansionTesting(
            AutoDefaultFixture.basicFunctionInput,
            expandedSource: AutoDefaultFixture.basicFunctionExpanded,
            macros: testMacros
        )
    }

    // MARK: - Auto-default: optional protocol return type

    @Test
    func `auto-default returns mock for optional protocol return type`() {
        assertMacroExpansionTesting(
            AutoDefaultFixture.optionalFunctionInput,
            expandedSource: AutoDefaultFixture.optionalFunctionExpanded,
            macros: testMacros
        )
    }

    // MARK: - Auto-default: array protocol return type

    @Test
    func `auto-default returns array mock for array protocol return type`() {
        assertMacroExpansionTesting(
            AutoDefaultFixture.arrayFunctionInput,
            expandedSource: AutoDefaultFixture.arrayFunctionExpanded,
            macros: testMacros
        )
    }

    // MARK: - Auto-default: non-matching type still calls fail

    @Test
    func `auto-default still calls fail for non-protocol return types`() {
        assertMacroExpansionTesting(
            AutoDefaultFixture.nonMatchingFunctionInput,
            expandedSource: AutoDefaultFixture.nonMatchingFunctionExpanded,
            macros: testMacros
        )
    }

    // MARK: - Auto-default: void function unchanged

    @Test
    func `auto-default does not affect void functions`() {
        assertMacroExpansionTesting(
            AutoDefaultFixture.voidFunctionInput,
            expandedSource: AutoDefaultFixture.voidFunctionExpanded,
            macros: testMacros
        )
    }

    // MARK: - Auto-default: property stub

    @Test
    func `auto-default returns mock for property with protocol type`() {
        assertMacroExpansionTesting(
            AutoDefaultFixture.propertyInput,
            expandedSource: AutoDefaultFixture.propertyExpanded,
            macros: testMacros
        )
    }

    // MARK: - Auto-default: subscript stub

    @Test
    func `auto-default returns mock for subscript with protocol return type`() {
        assertMacroExpansionTesting(
            AutoDefaultFixture.subscriptInput,
            expandedSource: AutoDefaultFixture.subscriptExpanded,
            macros: testMacros
        )
    }

    // MARK: - Auto-default: initializer stub (empty body)

    @Test
    func `auto-default generates empty body for initializer stubs`() {
        assertMacroExpansionTesting(
            AutoDefaultFixture.initializerInput,
            expandedSource: AutoDefaultFixture.initializerExpanded,
            macros: testMacros
        )
    }

    // MARK: - Auto-default combined with #if DEBUG

    @Test
    func `auto-default combined with debug wraps in if DEBUG`() {
        assertMacroExpansionTesting(
            AutoDefaultFixture.combinedDebugInput,
            expandedSource: AutoDefaultFixture.combinedDebugExpanded,
            macros: testMacros
        )
    }

    // MARK: - Auto-default with Sendable generates synchronized body

    @Test
    func `auto-default with sendable generates synchronized auto-default body`() {
        assertMacroExpansionTesting(
            AutoDefaultFixture.sendableInput,
            expandedSource: AutoDefaultFixture.sendableExpanded,
            macros: testMacros
        )
    }
}
