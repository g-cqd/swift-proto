//
//  ProtoMacroConfig+Parsing.swift
//  Proto
//
//  Created by Guillaume Coquard on 17.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Parsing State & Default

extension ProtoMacroConfig {
    static let `default` = ProtoMacroConfig(
        scope: nil,
        includeMethods: true,
        includeProperties: true,
        includeSubscripts: true,
        includeStatic: false,
        includeInit: false,
        includeMock: false,
        mockCompilationConditions: [],
        mockScope: nil,
        mockAutoDefault: false,
        mockPropertySetters: true,
        primaryBehavior: .unconstrained,
        whereClauseBehavior: .omit,
        conformsTo: [],
        isolation: .full
    )

    struct ParsingState {
        var scope: MemberExtractor.AccessLevel?
        var includeMethods = true
        var includeProperties = true
        var includeSubscripts = true
        var includeStatic = false
        var includeInit = false
        var includeMock = false
        var mockCompilationConditions = [String]()
        var mockScope: MemberExtractor.AccessLevel?
        var mockAutoDefault = false
        var mockPropertySetters = true
        var primaryBehavior: PrimaryTypeBehavior = .unconstrained
        var whereClauseBehavior: WhereClauseBehavior = .omit
        var conformsTo = [String]()
        var isolation: IsolationBehavior = .full

        func build() -> ProtoMacroConfig {
            ProtoMacroConfig(
                scope: scope,
                includeMethods: includeMethods,
                includeProperties: includeProperties,
                includeSubscripts: includeSubscripts,
                includeStatic: includeStatic,
                includeInit: includeInit,
                includeMock: includeMock,
                mockCompilationConditions: mockCompilationConditions,
                mockScope: mockScope,
                mockAutoDefault: mockAutoDefault,
                mockPropertySetters: mockPropertySetters,
                primaryBehavior: primaryBehavior,
                whereClauseBehavior: whereClauseBehavior,
                conformsTo: conformsTo,
                isolation: isolation
            )
        }
    }
}

// MARK: - Argument Processing

extension ProtoMacroConfig {
    static func processArgument(
        _ expr: ExprSyntax,
        state: inout ParsingState,
        context: some MacroExpansionContext
    ) {
        // Case 1: Simple flag — `.mock`, `.sendable`, `.noIsolation`,
        // `.unconstrained`, `.constrained`
        if let memberAccess = expr.as(MemberAccessExprSyntax.self), memberAccess.base == nil {
            processSimpleFlag(memberAccess, state: &state, context: context)
            return
        }

        // Case 2: Parameterized option — `.scope(...)`, `.include(...)`, etc.
        if let funcCall = expr.as(FunctionCallExprSyntax.self),
            let callee = funcCall.calledExpression.as(MemberAccessExprSyntax.self),
            callee.base == nil
        {
            processParameterizedOption(
                funcCall,
                callee: callee,
                state: &state,
                context: context
            )
            return
        }

        // Unrecognized argument shape
        context.diagnose(
            Diagnostic(
                node: Syntax(expr),
                message: ProtoDiagnostic.unknownOption
            )
        )
    }

    private static func processSimpleFlag(
        _ memberAccess: MemberAccessExprSyntax,
        state: inout ParsingState,
        context: some MacroExpansionContext
    ) {
        let name = memberAccess.declName.baseName.trimmedDescription
        switch name {
        case "noIsolation":
            state.isolation = .none
        case "sendable":
            state.conformsTo.append("Sendable")
        case "mock":
            state.includeMock = true
        case "unconstrained":
            state.primaryBehavior = .unconstrained
        case "constrained":
            state.primaryBehavior = .all
        default:
            context.diagnose(
                Diagnostic(
                    node: Syntax(memberAccess),
                    message: ProtoDiagnostic.unknownOption
                )
            )
        }
    }

    private static func processParameterizedOption(
        _ funcCall: FunctionCallExprSyntax,
        callee: MemberAccessExprSyntax,
        state: inout ParsingState,
        context: some MacroExpansionContext
    ) {
        let name = callee.declName.baseName.trimmedDescription
        switch name {
        case "scope":
            parseScopeOption(funcCall.arguments, state: &state, context: context)
        case "include":
            applySelections(
                from: funcCall.arguments,
                isIncluded: true,
                state: &state,
                context: context
            )
        case "exclude":
            applySelections(
                from: funcCall.arguments,
                isIncluded: false,
                state: &state,
                context: context
            )
        case "conforms":
            state.conformsTo += parseTypeSelfArguments(from: funcCall.arguments, in: context)
        case "constrained":
            processConstrainedOption(funcCall.arguments, state: &state, context: context)
        case "mock":
            state.includeMock = true
            parseMockOptions(funcCall.arguments, state: &state, context: context)
        case "isolation":
            parseIsolationOption(funcCall, state: &state, context: context)
        default:
            context.diagnose(
                Diagnostic(
                    node: Syntax(funcCall),
                    message: ProtoDiagnostic.unknownOption
                )
            )
        }
    }

    private static func parseScopeOption(
        _ arguments: LabeledExprListSyntax,
        state: inout ParsingState,
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
        state.scope = parsed
    }

    private static func parseIsolationOption(
        _ funcCall: FunctionCallExprSyntax,
        state: inout ParsingState,
        context: some MacroExpansionContext
    ) {
        guard let firstArg = funcCall.arguments.first,
            let parsed = parseIsolation(from: firstArg.expression)
        else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(funcCall),
                    message: ProtoDiagnostic.invalidIsolationValue
                )
            )
            return
        }
        state.isolation = parsed
    }

    /// Process `.constrained(...)` sub-options.
    ///
    /// Determines primary type behavior and where-clause behavior from the
    /// parsed constrained options. The where clause is omitted by default;
    /// `.withWhereClause` at root level keeps all constraints, and
    /// per-parameter `.to("T", .withWhereClause)` keeps only that parameter's
    /// constraints. Mixing root `.withWhereClause` with `.to(...)` is an error.
    private static func processConstrainedOption(
        _ arguments: LabeledExprListSyntax,
        state: inout ParsingState,
        context: some MacroExpansionContext
    ) {
        let constrained = parseConstrainedOptions(from: arguments, in: context)
        if !constrained.toNames.isEmpty {
            // Merge new names with existing, deduplicating while preserving order
            var allNames: [String] =
                if case .explicit(let existing) = state.primaryBehavior {
                    existing
                } else {
                    []
                }
            for name in constrained.toNames where !allNames.contains(name) {
                allNames.append(name)
            }
            state.primaryBehavior = .explicit(allNames)
        } else {
            state.primaryBehavior = .all
        }

        // Determine where-clause behavior
        if constrained.hasRootWhereClause, !constrained.toNames.isEmpty {
            // .constrained(.to("Key"), .withWhereClause) is invalid
            context.diagnose(
                Diagnostic(
                    node: Syntax(arguments),
                    message: ProtoDiagnostic.mixedWhereClauseWithTo
                )
            )
        } else if constrained.hasRootWhereClause {
            state.whereClauseBehavior = .keepAll
        } else if !constrained.whereClauseNames.isEmpty {
            // Merge with existing keepFor names if any
            var names = constrained.whereClauseNames
            if case .keepFor(let existing) = state.whereClauseBehavior {
                names.formUnion(existing)
            }
            state.whereClauseBehavior = .keepFor(names)
        }
        // Otherwise leave as .omit (the default)
    }
}

// MARK: - Selection Helpers

extension ProtoMacroConfig {
    private static func applySelections(
        from arguments: LabeledExprListSyntax,
        isIncluded: Bool,
        state: inout ParsingState,
        context: some MacroExpansionContext
    ) {
        for selection in parseMemberSelections(from: arguments, in: context) {
            apply(selection: selection, isIncluded: isIncluded, state: &state)
        }
    }

    private static func apply(
        selection: MemberSelection,
        isIncluded: Bool,
        state: inout ParsingState
    ) {
        switch selection {
        case .members:
            state.includeMethods = isIncluded
            state.includeProperties = isIncluded
            state.includeSubscripts = isIncluded
        case .methods:
            state.includeMethods = isIncluded
        case .properties:
            state.includeProperties = isIncluded
        case .subscripts:
            state.includeSubscripts = isIncluded
        case .static:
            state.includeStatic = isIncluded
        case .initializer:
            state.includeInit = isIncluded
        }
    }

    private static func parseMemberSelections(
        from arguments: LabeledExprListSyntax,
        in context: some MacroExpansionContext
    ) -> [MemberSelection] {
        arguments.compactMap { argument in
            parseMemberSelection(from: argument.expression, context: context)
        }
    }

    private static func parseMemberSelection(
        from expression: ExprSyntax,
        context: some MacroExpansionContext
    ) -> MemberSelection? {
        guard let memberAccess = expression.as(MemberAccessExprSyntax.self),
            memberAccess.base == nil
        else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(expression),
                    message: ProtoDiagnostic.invalidMemberSelectionValue
                )
            )
            return nil
        }

        let name = memberAccess.declName.baseName.trimmedDescription
        let selection = memberSelectionMap[name]

        if selection == nil {
            context.diagnose(
                Diagnostic(
                    node: Syntax(expression),
                    message: ProtoDiagnostic.invalidMemberSelectionValue
                )
            )
        }
        return selection
    }

    /// Maps member access names to selections.
    /// Both `"init"` and `"initializer"` map to `.initializer` so that
    /// `.include(.init)` and `.include(.initializer)` are interchangeable.
    private static let memberSelectionMap: [String: MemberSelection] = [
        "members": .members,
        "methods": .methods,
        "properties": .properties,
        "subscripts": .subscripts,
        "static": .static,
        "init": .initializer,
        "initializer": .initializer,
    ]
}

// MARK: - Value Parsers

extension ProtoMacroConfig {
    static func parseScope(from expression: ExprSyntax) -> MemberExtractor.AccessLevel? {
        guard let memberAccess = expression.as(MemberAccessExprSyntax.self) else { return nil }
        return MemberExtractor.AccessLevel(scopeName: memberAccess.declName.baseName.trimmedDescription)
    }

    private static func parseIsolation(from expression: ExprSyntax) -> IsolationBehavior? {
        guard let memberAccess = expression.as(MemberAccessExprSyntax.self) else { return nil }
        return switch memberAccess.declName.baseName.trimmedDescription {
        case "full":
            .full
        case "actorOnly":
            .actorOnly
        case "asyncOnly":
            .asyncOnly
        case "none":
            IsolationBehavior.none
        default:
            nil
        }
    }

    struct ConstrainedParseResult {
        var toNames: [String] = []
        var whereClauseNames: Set<String> = []
        var hasRootWhereClause = false
    }

    private static func parseConstrainedOptions(
        from arguments: LabeledExprListSyntax,
        in context: some MacroExpansionContext
    ) -> ConstrainedParseResult {
        var toNames: [String] = []
        var whereClauseNames: Set<String> = []
        var hasRootWhereClause = false

        for argument in arguments {
            let expression = argument.expression

            // Root-level `.withWhereClause`
            if let memberAccess = expression.as(MemberAccessExprSyntax.self),
                memberAccess.base == nil,
                memberAccess.declName.baseName.trimmedDescription == "withWhereClause"
            {
                hasRootWhereClause = true
                continue
            }

            // `.to(...)` call — may contain strings and/or `.withWhereClause` modifier
            if let optionCall = expression.as(FunctionCallExprSyntax.self),
                let optionCallee = optionCall.calledExpression.as(MemberAccessExprSyntax.self),
                optionCallee.base == nil,
                optionCallee.declName.baseName.trimmedDescription == "to"
            {
                let parsed = parseToArguments(from: optionCall.arguments, in: context)
                if parsed.names.isEmpty {
                    context.diagnose(
                        Diagnostic(
                            node: Syntax(expression),
                            message: ProtoDiagnostic.invalidConstrainedTypeList
                        )
                    )
                } else {
                    toNames += parsed.names
                    if parsed.hasWhereClause {
                        whereClauseNames.formUnion(parsed.names)
                    }
                }
                continue
            }

            context.diagnose(
                Diagnostic(
                    node: Syntax(expression),
                    message: ProtoDiagnostic.invalidConstrainedOptionValue
                )
            )
        }

        return ConstrainedParseResult(
            toNames: toNames,
            whereClauseNames: whereClauseNames,
            hasRootWhereClause: hasRootWhereClause
        )
    }

    /// Parse arguments of a `.to(...)` call.
    /// Accepts string literal names and an optional trailing `.withWhereClause` modifier.
    private static func parseToArguments(
        from arguments: LabeledExprListSyntax,
        in context: some MacroExpansionContext
    ) -> (names: [String], hasWhereClause: Bool) {
        var names: [String] = []
        var hasWhereClause = false

        for arg in arguments {
            // Check for `.withWhereClause` modifier
            if let memberAccess = arg.expression.as(MemberAccessExprSyntax.self),
                memberAccess.base == nil,
                memberAccess.declName.baseName.trimmedDescription == "withWhereClause"
            {
                hasWhereClause = true
                continue
            }

            // String literal name
            guard let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self) else {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(arg.expression),
                        message: ProtoDiagnostic.invalidStringArgument
                    )
                )
                continue
            }
            guard stringLiteral.segments.count == 1,
                let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self)
            else {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(arg.expression),
                        message: ProtoDiagnostic.interpolatedStringNotSupported
                    )
                )
                continue
            }
            names.append(segment.content.trimmedDescription)
        }

        return (names, hasWhereClause)
    }

    static func parseStringArguments(
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
            // Detect interpolated strings (multiple segments or non-string segments)
            guard stringLiteral.segments.count == 1,
                let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self)
            else {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(arg.expression),
                        message: ProtoDiagnostic.interpolatedStringNotSupported
                    )
                )
                return nil
            }
            return segment.content.trimmedDescription
        }
    }

    private static func parseTypeSelfArguments(
        from arguments: LabeledExprListSyntax,
        in context: some MacroExpansionContext
    ) -> [String] {
        arguments.compactMap { arg in
            guard let memberAccess = arg.expression.as(MemberAccessExprSyntax.self),
                memberAccess.declName.baseName.trimmedDescription == "self"
            else {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(arg.expression),
                        message: ProtoDiagnostic.invalidConformsToArgument
                    )
                )
                return nil
            }

            // Simple type: Foo.self
            if let base = memberAccess.base?.as(DeclReferenceExprSyntax.self) {
                return base.baseName.trimmedDescription
            }

            // Qualified type: Module.Type.self — collect member access chain
            if let qualifiedName = collectQualifiedName(from: memberAccess.base) {
                return qualifiedName
            }

            context.diagnose(
                Diagnostic(
                    node: Syntax(arg.expression),
                    message: ProtoDiagnostic.invalidConformsToArgument
                )
            )
            return nil
        }
    }

    /// Collects a dot-separated qualified name from a member access chain.
    /// For example, `Foundation.Codable` → `"Foundation.Codable"`.
    private static func collectQualifiedName(from expr: ExprSyntax?) -> String? {
        guard let expr else { return nil }
        if let declRef = expr.as(DeclReferenceExprSyntax.self) {
            return declRef.baseName.trimmedDescription
        }
        if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
            guard let baseName = collectQualifiedName(from: memberAccess.base) else { return nil }
            return "\(baseName).\(memberAccess.declName.baseName.trimmedDescription)"
        }
        return nil
    }
}
