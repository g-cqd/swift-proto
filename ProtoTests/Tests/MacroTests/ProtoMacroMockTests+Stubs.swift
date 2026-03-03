import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroMockTests {
    // MARK: - Property stub generation

    @Test
    func `mock generates property stubs for computed properties`() {
        assertMacroExpansionTesting(
            StubFixture.propertyStubInput,
            expandedSource: StubFixture.propertyStubExpanded,
            macros: testMacros
        )
    }

    // MARK: - Subscript stub generation

    @Test
    func `mock generates subscript stubs`() {
        assertMacroExpansionTesting(
            StubFixture.subscriptStubInput,
            expandedSource: StubFixture.subscriptStubExpanded,
            macros: testMacros
        )
    }

    // MARK: - Initializer stub generation

    @Test
    func `mock generates initializer stubs`() {
        assertMacroExpansionTesting(
            StubFixture.initializerStubInput,
            expandedSource: StubFixture.initializerStubExpanded,
            macros: testMacros
        )
    }

    // MARK: - Overloaded method disambiguation

    @Test
    func `mock disambiguates overloaded method helper names`() {
        assertMacroExpansionTesting(
            StubFixture.overloadedInput,
            expandedSource: StubFixture.overloadedExpanded,
            macros: testMacros
        )
    }

    // MARK: - @unchecked Sendable mock generation

    @Test
    func `mock with Sendable conformance generates unchecked Sendable`() {
        assertMacroExpansionTesting(
            FeatureFixture.sendableInput,
            expandedSource: FeatureFixture.sendableExpanded,
            macros: testMacros
        )
    }

    @Test
    func `mock with sendable shorthand generates unchecked Sendable`() {
        assertMacroExpansionTesting(
            FeatureFixture.sendableShorthandInput,
            expandedSource: FeatureFixture.sendableExpanded,
            macros: testMacros
        )
    }

    @Test
    func `mock with static Sendable members generates synchronized static helpers`() {
        assertMacroExpansionTesting(
            FeatureFixture.staticSendableInput,
            expandedSource: FeatureFixture.staticSendableExpanded,
            macros: testMacros
        )
    }

    // MARK: - Static member mock helpers

    @Test
    func `mock with static members generates static helpers`() {
        assertMacroExpansionTesting(
            FeatureFixture.staticInput,
            expandedSource: FeatureFixture.staticExpanded,
            macros: testMacros
        )
    }

    // MARK: - Error injection — typed throws

    @Test
    func `mock with typed throws generates typed error property`() {
        assertMacroExpansionTesting(
            FeatureFixture.typedThrowsInput,
            expandedSource: FeatureFixture.typedThrowsExpanded,
            macros: testMacros
        )
    }

    // MARK: - rethrows handler type normalized to throws

    @Test
    func `mock with rethrows normalizes handler type to throws`() {
        assertMacroExpansionTesting(
            FeatureFixture.rethrowsInput,
            expandedSource: FeatureFixture.rethrowsExpanded,
            macros: testMacros
        )
    }

    // MARK: - .mock(.debug) wraps in #if DEBUG

    @Test
    func `mock with debug option wraps in if DEBUG`() {
        assertMacroExpansionTesting(
            MockOptionFixture.mockDebugInput,
            expandedSource: MockOptionFixture.mockDebugExpanded,
            macros: testMacros
        )
    }

    // MARK: - .mock(.custom("TESTING")) wraps in #if TESTING

    @Test
    func `mock with custom flag wraps in if custom condition`() {
        assertMacroExpansionTesting(
            MockOptionFixture.mockCustomFlagInput,
            expandedSource: MockOptionFixture.mockCustomFlagExpanded,
            macros: testMacros
        )
    }

    // MARK: - .mock(.expr("DEBUG && os(iOS)")) wraps in #if expression

    @Test
    func `mock with expr condition wraps in if expression`() {
        assertMacroExpansionTesting(
            MockOptionFixture.mockExprInput,
            expandedSource: MockOptionFixture.mockExprExpanded,
            macros: testMacros
        )
    }

    // MARK: - .mock(.scope(.package)) overrides mock access level

    @Test
    func `mock with scope override generates package access`() {
        assertMacroExpansionTesting(
            MockOptionFixture.mockScopeInput,
            expandedSource: MockOptionFixture.mockScopeExpanded,
            macros: testMacros
        )
    }

    // MARK: - .mock(.debug, .release, .custom("X")) joins conditions with ||

    @Test
    func `mock with multiple conditions joins with logical or`() {
        assertMacroExpansionTesting(
            MockOptionFixture.mockMultipleConditionsInput,
            expandedSource: MockOptionFixture.mockMultipleConditionsExpanded,
            macros: testMacros
        )
    }

    // MARK: - .mock(.debug, .scope(.package)) combines condition and scope

    @Test
    func `mock with debug and scope combines condition and access level`() {
        assertMacroExpansionTesting(
            MockOptionFixture.mockDebugWithScopeInput,
            expandedSource: MockOptionFixture.mockDebugWithScopeExpanded,
            macros: testMacros
        )
    }
}
