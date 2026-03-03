//
//  ProtoMacroConfig+MockParsing.swift
//  Proto
//
//  Created by Guillaume Coquard on 19.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Mock Option Parsing

extension ProtoMacroConfig {
    /// Process `.mock(...)` sub-options.
    ///
    /// Supported sub-options:
    /// - `.debug` → append `"DEBUG"` to compilation conditions
    /// - `.release` → append `"RELEASE"` to compilation conditions
    /// - `.custom("X")` → append `"X"` to compilation conditions
    /// - `.expr("X && Y")` → append raw compilation condition expression
    /// - `.scope(.Y)` → set mock access level override
    static func parseMockOptions(
        _ arguments: LabeledExprListSyntax,
        state: inout ParsingState,
        context: some MacroExpansionContext
    ) {
        for argument in arguments {
            parseSingleMockOption(argument.expression, state: &state, context: context)
        }
    }

    private static func parseSingleMockOption(
        _ expression: ExprSyntax,
        state: inout ParsingState,
        context: some MacroExpansionContext
    ) {
        if let memberAccess = expression.as(MemberAccessExprSyntax.self),
            memberAccess.base == nil
        {
            parseMockFlag(memberAccess, state: &state, context: context)
            return
        }

        if let optionCall = expression.as(FunctionCallExprSyntax.self),
            let callee = optionCall.calledExpression.as(MemberAccessExprSyntax.self),
            callee.base == nil
        {
            parseMockParameterizedOption(optionCall, callee: callee, state: &state, context: context)
            return
        }

        context.diagnose(
            Diagnostic(
                node: Syntax(expression),
                message: ProtoDiagnostic.invalidMockOptionValue
            )
        )
    }

    private static func parseMockFlag(
        _ memberAccess: MemberAccessExprSyntax,
        state: inout ParsingState,
        context: some MacroExpansionContext
    ) {
        switch memberAccess.declName.baseName.trimmedDescription {
        case "debug":
            state.mockCompilationConditions.append("DEBUG")
        case "release":
            state.mockCompilationConditions.append("RELEASE")
        case "auto":
            state.mockAutoDefault = true
        default:
            context.diagnose(
                Diagnostic(
                    node: Syntax(memberAccess),
                    message: ProtoDiagnostic.invalidMockOptionValue
                )
            )
        }
    }

    private static func parseMockParameterizedOption(
        _ optionCall: FunctionCallExprSyntax,
        callee: MemberAccessExprSyntax,
        state: inout ParsingState,
        context: some MacroExpansionContext
    ) {
        switch callee.declName.baseName.trimmedDescription {
        case "custom":
            let flags = parseStringArguments(from: optionCall.arguments, in: context)
            for flag in flags {
                if isValidCompilationCondition(flag) {
                    state.mockCompilationConditions.append(flag)
                } else {
                    context.diagnose(
                        Diagnostic(
                            node: Syntax(optionCall),
                            message: ProtoDiagnostic.invalidCompilationCondition(flag)
                        )
                    )
                }
            }
        case "expr":
            let expressions = parseCompilationExpressions(from: optionCall.arguments, in: context)
            for expression in expressions {
                if isValidCompilationExpression(expression) {
                    state.mockCompilationConditions.append(expression)
                } else {
                    context.diagnose(
                        Diagnostic(
                            node: Syntax(optionCall),
                            message: ProtoDiagnostic.invalidCompilationExpression(expression)
                        )
                    )
                }
            }
        case "scope":
            parseScopeOption(optionCall.arguments, into: &state.mockScope, context: context)
        default:
            context.diagnose(
                Diagnostic(
                    node: Syntax(optionCall),
                    message: ProtoDiagnostic.invalidMockOptionValue
                )
            )
        }
    }

    /// Validates that a compilation condition string contains only valid identifier characters.
    private static func isValidCompilationCondition(_ flag: String) -> Bool {
        !flag.isEmpty && flag.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    /// Validates that a raw compilation expression is non-empty, single-line,
    /// and cannot contain statement separators.
    private static func isValidCompilationExpression(_ expression: String) -> Bool {
        let hasVisibleCharacter = expression.contains { !$0.isWhitespace }
        return hasVisibleCharacter
            && !expression.contains(where: \.isNewline)
            && !expression.contains(";")
    }

    private static func parseScopeOption(
        _ arguments: LabeledExprListSyntax,
        into target: inout MemberExtractor.AccessLevel?,
        context: some MacroExpansionContext
    ) {
        guard let firstArg = arguments.first else { return }
        let parsed = parseScope(from: firstArg.expression)
        if parsed == nil {
            context.diagnose(
                Diagnostic(
                    node: Syntax(firstArg.expression),
                    message: ProtoDiagnostic.invalidScopeValue
                )
            )
        }
        target = parsed
    }

    /// Parses string literal arguments for `.expr(...)`, preserving line breaks
    /// to allow explicit validation (single-line only).
    private static func parseCompilationExpressions(
        from arguments: LabeledExprListSyntax,
        in context: some MacroExpansionContext
    ) -> [String] {
        arguments.compactMap { arg in
            guard let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self) else {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(arg.expression),
                        message: ProtoDiagnostic.invalidStringArgument
                    )
                )
                return nil
            }

            let stringSegments = stringLiteral.segments.compactMap { $0.as(StringSegmentSyntax.self) }
            guard stringSegments.count == stringLiteral.segments.count else {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(arg.expression),
                        message: ProtoDiagnostic.interpolatedStringNotSupportedInMockExpr
                    )
                )
                return nil
            }

            return stringSegments.map(\.content.text).joined()
        }
    }
}
