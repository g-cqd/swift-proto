import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroMockTests {
    // MARK: - Mock property with get/set generates failure getter and empty setter

    @Test
    func `mock property with get and set generates failure getter and empty setter`() {
        assertMacroExpansionTesting(
            NonFunctionStubGapFixture.storedPropertyMockInput,
            expandedSource: NonFunctionStubGapFixture.storedPropertyMockExpanded,
            macros: testMacros
        )
    }

    // MARK: - Auto-default property with getter and setter

    @Test
    func `auto-default mutable property generates auto-default getter and empty setter`() {
        assertMacroExpansionTesting(
            NonFunctionStubGapFixture.autoDefaultMutablePropertyInput,
            expandedSource: NonFunctionStubGapFixture.autoDefaultMutablePropertyExpanded,
            macros: testMacros
        )
    }
}
