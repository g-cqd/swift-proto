import SwiftSyntax
import Testing

@testable import ProtoMacros

@Suite("Direct unit tests for internal helpers")
struct ProtoMacroDirectUnitTests {
    // MARK: - sanitizeHelperIdentifier

    @Test
    func `sanitizeHelperIdentifier all-underscore returns member`() {
        let result = MockGenerator.sanitizeHelperIdentifier("___")
        #expect(result == "member")
    }

    @Test
    func `sanitizeHelperIdentifier leading digit prepends underscore`() {
        let result = MockGenerator.sanitizeHelperIdentifier("3abc")
        #expect(result == "_3abc")
    }

    // MARK: - autoDefaultExpression

    @Test
    func `autoDefaultExpression Optional generic form`() {
        let result = MockGenerator.autoDefaultExpression(for: "Optional<FooProtocol>")
        #expect(result == "FooMock()")
    }

    @Test
    func `autoDefaultExpression Array generic form`() {
        let result = MockGenerator.autoDefaultExpression(for: "Array<FooProtocol>")
        #expect(result == "[FooMock()]")
    }

    // MARK: - visibilityKeyword

    @Test
    func `visibilityKeyword for package`() {
        let result = MockGenerator.visibilityKeyword(for: .package)
        #expect(result == "package")
    }

    @Test
    func `visibilityKeyword for open`() {
        let result = MockGenerator.visibilityKeyword(for: .open)
        #expect(result == "public")
    }

    // MARK: - modifierToken

    @Test
    func `modifierToken for package`() {
        let token = MockGenerator.modifierToken(for: "package")
        #expect(token.tokenKind == .keyword(.package))
    }

    @Test
    func `modifierToken for open`() {
        let token = MockGenerator.modifierToken(for: "open")
        #expect(token.tokenKind == .keyword(.open))
    }

    @Test
    func `modifierToken for unknown keyword`() {
        let token = MockGenerator.modifierToken(for: "unknown")
        #expect(token.tokenKind == .identifier("unknown"))
    }
}
