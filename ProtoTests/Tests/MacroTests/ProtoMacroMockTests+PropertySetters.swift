import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroMockTests {
    // MARK: - Basic property setter generation

    @Test
    func `mock generates backing storage and setter method for get-only property`() {
        assertMacroExpansionTesting(
            PropertySetterFixture.basicInput,
            expandedSource: PropertySetterFixture.basicExpanded,
            macros: testMacros
        )
    }

    // MARK: - noPropertySetters suppresses setter generation

    @Test
    func `mock with noPropertySetters omits backing storage and setter method`() {
        assertMacroExpansionTesting(
            PropertySetterFixture.noSettersInput,
            expandedSource: PropertySetterFixture.noSettersExpanded,
            macros: testMacros
        )
    }

    // MARK: - Async getter produces async setter

    @Test
    func `mock with async getter generates async setter method`() {
        assertMacroExpansionTesting(
            PropertySetterFixture.asyncGetterInput,
            expandedSource: PropertySetterFixture.asyncGetterExpanded,
            macros: testMacros
        )
    }

    // MARK: - Mutable property skips setter method

    @Test
    func `mock with mutable property does not generate setter method`() {
        assertMacroExpansionTesting(
            PropertySetterFixture.mutablePropertyInput,
            expandedSource: PropertySetterFixture.mutablePropertyExpanded,
            macros: testMacros
        )
    }

    // MARK: - Auto-default with backing storage

    @Test
    func `mock with auto-default and property setter uses initialized backing storage`() {
        assertMacroExpansionTesting(
            PropertySetterFixture.autoDefaultInput,
            expandedSource: PropertySetterFixture.autoDefaultExpanded,
            macros: testMacros
        )
    }

    // MARK: - Public visibility on setter method

    @Test
    func `mock setter method inherits public visibility`() {
        assertMacroExpansionTesting(
            PropertySetterFixture.publicVisibilityInput,
            expandedSource: PropertySetterFixture.publicVisibilityExpanded,
            macros: testMacros
        )
    }
}
