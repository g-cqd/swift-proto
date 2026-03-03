import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroMockTests {
    // MARK: - Auto-default with Optional<> generic form (SharedHelpers lines 152-156)

    @Test
    func `auto-default with Optional generic form`() {
        assertMacroExpansionTesting(
            SharedHelperGapFixture.optionalGenericInput,
            expandedSource: SharedHelperGapFixture.optionalGenericExpanded,
            macros: testMacros
        )
    }

    // MARK: - Auto-default with Array<> generic form (SharedHelpers lines 166-172)

    @Test
    func `auto-default with Array generic form`() {
        assertMacroExpansionTesting(
            SharedHelperGapFixture.arrayGenericInput,
            expandedSource: SharedHelperGapFixture.arrayGenericExpanded,
            macros: testMacros
        )
    }

    // MARK: - Mock on actor preserves nonisolated (SharedHelpers line 50-51)

    @Test
    func `mock on actor preserves nonisolated modifier`() {
        assertMacroExpansionTesting(
            SharedHelperGapFixture.actorNonisolatedInput,
            expandedSource: SharedHelperGapFixture.actorNonisolatedExpanded,
            macros: testMacros
        )
    }

    // MARK: - Mock with .scope(.package) (SharedHelpers lines 94-95, 220-221)

    @Test
    func `mock with scope package generates package access level`() {
        assertMacroExpansionTesting(
            SharedHelperGapFixture.mockScopePackageInput,
            expandedSource: SharedHelperGapFixture.mockScopePackageExpanded,
            macros: testMacros
        )
    }
}
