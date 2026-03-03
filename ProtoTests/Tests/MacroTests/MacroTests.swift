import ProtoMacros
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacrosTestSupport
import Testing

let testMacros: [String: Macro.Type] = [
    "Proto": ProtoMacro.self,
    "ProtoExclude": ProtoExcludeMacro.self,
    "ProtoMember": ProtoMemberMacro.self,
    "ProtoMockIgnored": ProtoMockIgnoredMacro.self,
]

/// SwiftSyntax's `assertMacroExpansion` reports failures via `XCTFail`.
/// Under Swift Testing `@Test`, those failures can be lost, so we bridge
/// to the generic assertion API and convert failures into `#expect` issues.
@discardableResult
func assertMacroExpansionTesting(
    _ originalSource: String,
    expandedSource expectedExpandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    macros: [String: Macro.Type],
    applyFixIts: [String]? = nil,
    fixedSource expectedFixedSource: String? = nil,
    testModuleName: String = "TestModule",
    testFileName: String = "test.swift",
    indentationWidth: Trivia = .spaces(4),
    fileID: StaticString = #fileID,
    file: StaticString = #filePath,
    line: UInt = #line
) -> Bool {
    let macroSpecs = macros.mapValues { MacroSpec(type: $0) }
    var failures: [String] = []

    SwiftSyntaxMacrosGenericTestSupport.assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        diagnostics: diagnostics,
        macroSpecs: macroSpecs,
        applyFixIts: applyFixIts,
        fixedSource: expectedFixedSource,
        testModuleName: testModuleName,
        testFileName: testFileName,
        indentationWidth: indentationWidth,
        failureHandler: { failures.append($0.message) },
        fileID: fileID,
        filePath: file,
        line: line,
        column: 0
    )

    if failures.isEmpty {
        return true
    }

    let joined = failures.joined(separator: "\n\n")
    Issue.record("Macro expansion assertion failed:\n\(joined)")
    return false
}
