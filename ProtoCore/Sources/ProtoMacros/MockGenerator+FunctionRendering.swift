//
//  MockGenerator+FunctionRendering.swift
//  Proto
//
//  Created by Guillaume Coquard on 18.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftSyntax

// MARK: - Function Rendering

extension MockGenerator {
    struct RenderedFunctionMember {
        let helperDecls: [DeclSyntax]
        let memberImpl: DeclSyntax
        let needsReturnStub: Bool
        let initParameter: InitParameter?
        let usesInstanceSynchronization: Bool
        let usesStaticSynchronization: Bool
    }

    struct FunctionTraits {
        let localNames: [String?]
        let returnType: String?
        let returnsValue: Bool
        let throwsClause: ThrowsClauseSyntax?
        let isThrowing: Bool
        let supportsErrorInjection: Bool
        let shouldGenerateHelpers: Bool
        let isStatic: Bool
        let helperAccessPrefix: String
        let helperStaticPrefix: String
        let helperPrivatePrefix: String
        let argumentType: String?
        let argumentValue: String?
        let useSynchronizedState: Bool
    }

    struct HelperDeclarations {
        let decls: [DeclSyntax]
        let usesReturnStub: Bool
    }

    static func renderFunctionMember(
        _ functionDecl: FunctionDeclSyntax,
        helperName: String,
        mockName: String,
        visibilityKeyword: String?,
        mockIsActor: Bool,
        requiresSynchronizedState: Bool,
        mockAutoDefault: Bool,
        ignored: Bool
    ) -> RenderedFunctionMember {
        let traits = functionTraits(
            for: functionDecl,
            visibilityKeyword: visibilityKeyword,
            mockIsActor: mockIsActor,
            requiresSynchronizedState: requiresSynchronizedState,
            ignored: ignored
        )
        let helperDeclarations = makeHelperDeclarations(
            for: functionDecl,
            helperName: helperName,
            traits: traits
        )
        let bodyLines = makeFunctionBodyLines(
            for: functionDecl,
            helperName: helperName,
            mockName: mockName,
            traits: traits,
            mockAutoDefault: mockAutoDefault
        )
        let bodySource = "{\n" + bodyLines.map { "        \($0)" }.joined(separator: "\n") + "\n    }"

        var memberDecl = functionDecl.trimmed
        memberDecl.attributes = mockAttributes(attributes: functionDecl.attributes)
        memberDecl.modifiers = mockModifiers(
            modifiers: functionDecl.modifiers,
            visibilityKeyword: visibilityKeyword,
            mockIsActor: mockIsActor
        )
        memberDecl.body = CodeBlockSyntax(stringLiteral: bodySource)
        memberDecl.leadingTrivia = []
        memberDecl.trailingTrivia = []

        let initParameter: InitParameter? =
            if traits.shouldGenerateHelpers, !traits.isStatic {
                InitParameter(
                    helperName: helperName,
                    handlerType: functionHandlerType(functionDecl),
                    returnType: traits.returnsValue ? traits.returnType : nil,
                    errorType: traits.supportsErrorInjection
                        ? (traits.throwsClause?.type?.trimmedDescription ?? "any Error")
                        : nil
                )
            } else {
                nil
            }

        return RenderedFunctionMember(
            helperDecls: helperDeclarations.decls,
            memberImpl: DeclSyntax(memberDecl),
            needsReturnStub: helperDeclarations.usesReturnStub,
            initParameter: initParameter,
            usesInstanceSynchronization: traits.useSynchronizedState && !traits.isStatic,
            usesStaticSynchronization: traits.useSynchronizedState && traits.isStatic
        )
    }

    static func functionTraits(
        for functionDecl: FunctionDeclSyntax,
        visibilityKeyword: String?,
        mockIsActor: Bool,
        requiresSynchronizedState: Bool,
        ignored: Bool
    ) -> FunctionTraits {
        let isStatic = ProtocolGenerator.hasModifier(functionDecl.modifiers, named: "static")
        let isNonisolated = ProtocolGenerator.hasModifier(functionDecl.modifiers, named: "nonisolated")
        let parameters = Array(functionDecl.signature.parameterClause.parameters)
        let localNames = localParameterNames(parameters)
        let hasResolvableParameterNames = localNames.allSatisfy { $0 != nil }
        let returnType = functionDecl.signature.returnClause?.type.trimmedDescription
        let returnsValue = returnType != nil && returnType != "Void" && returnType != "()"
        let throwsClause = functionDecl.signature.effectSpecifiers?.throwsClause
        let isThrowing = throwsClause != nil
        let isRethrowing = throwsClause?.throwsSpecifier.tokenKind == .keyword(.rethrows)

        return FunctionTraits(
            localNames: localNames,
            returnType: returnType,
            returnsValue: returnsValue,
            throwsClause: throwsClause,
            isThrowing: isThrowing,
            supportsErrorInjection: isThrowing && !isRethrowing,
            shouldGenerateHelpers: !ignored && hasResolvableParameterNames && !(mockIsActor && isNonisolated),
            isStatic: isStatic,
            helperAccessPrefix: visibilityKeyword.map { "\($0) " } ?? "",
            helperStaticPrefix: isStatic ? "static " : "",
            helperPrivatePrefix: isStatic ? "private static " : "private ",
            argumentType: capturedArgumentType(for: parameters),
            argumentValue: capturedArgumentValue(for: localNames),
            useSynchronizedState: requiresSynchronizedState
        )
    }

    static func makeHelperDeclarations(
        for functionDecl: FunctionDeclSyntax,
        helperName: String,
        traits: FunctionTraits
    ) -> HelperDeclarations {
        guard traits.shouldGenerateHelpers else {
            return HelperDeclarations(decls: [], usesReturnStub: false)
        }

        let baseDecls = baseHelperDeclarations(
            for: functionDecl,
            helperName: helperName,
            traits: traits
        )
        guard
            let returnDecls = returnValueHelperDeclarations(
                helperName: helperName,
                traits: traits
            )
        else {
            return HelperDeclarations(decls: baseDecls, usesReturnStub: false)
        }

        return HelperDeclarations(
            decls: baseDecls + returnDecls,
            usesReturnStub: true
        )
    }

    static func makeFunctionBodyLines(
        for functionDecl: FunctionDeclSyntax,
        helperName: String,
        mockName: String,
        traits: FunctionTraits,
        mockAutoDefault: Bool
    ) -> [String] {
        guard traits.shouldGenerateHelpers else {
            let escapedHelper = escapeForStringLiteral(helperName)
            let escapedMock = escapeForStringLiteral(mockName)
            return [
                "ProtoMockFailureHandling.fail(\"No mock helper generated for \(escapedHelper) on \(escapedMock)\")"
            ]
        }

        if traits.useSynchronizedState {
            return synchronizedFunctionBodyLines(
                for: functionDecl,
                helperName: helperName,
                mockName: mockName,
                traits: traits,
                mockAutoDefault: mockAutoDefault
            )
        }

        return unsynchronizedFunctionBodyLines(
            for: functionDecl,
            helperName: helperName,
            mockName: mockName,
            traits: traits,
            mockAutoDefault: mockAutoDefault
        )
    }

    static func synchronizedFunctionBodyLines(
        for functionDecl: FunctionDeclSyntax,
        helperName: String,
        mockName: String,
        traits: FunctionTraits,
        mockAutoDefault: Bool
    ) -> [String] {
        let lockAccessor = synchronizationLockAccessor(for: traits)
        let callCountStorage = synchronizedStorageName(for: helperName, suffix: "CallCount")
        let receivedStorage = synchronizedStorageName(for: helperName, suffix: "ReceivedArguments")
        let handlerStorage = synchronizedStorageName(for: helperName, suffix: "Handler")
        let errorStorage = synchronizedStorageName(for: helperName, suffix: "Error")
        let returnStorage = synchronizedStorageName(for: helperName, suffix: "ReturnStub")

        var lines = ["\(lockAccessor).withLock { \(callCountStorage) += 1 }"]
        if let argumentValue = traits.argumentValue {
            lines.append("\(lockAccessor).withLock { \(receivedStorage).append(\(argumentValue)) }")
        }

        lines.append("let handler = \(lockAccessor).withLock { \(handlerStorage) }")
        lines.append(
            contentsOf: handlerInvocationLines(
                for: functionDecl,
                handlerBinding: "handler",
                returnsValue: traits.returnsValue,
                localNames: traits.localNames,
                isThrowing: traits.isThrowing
            )
        )

        if traits.supportsErrorInjection {
            lines.append("let error = \(lockAccessor).withLock { \(errorStorage) }")
            lines.append("if let error {")
            lines.append("    throw error")
            lines.append("}")
        }

        if traits.returnsValue {
            lines.append("let returnStub = \(lockAccessor).withLock { \(returnStorage) }")
            lines.append("if case .value(let value) = returnStub {")
            lines.append("    return value")
            lines.append("}")
            if mockAutoDefault, let defaultExpr = autoDefaultExpression(for: traits.returnType) {
                lines.append("return \(defaultExpr)")
            } else {
                let escapedHelper = escapeForStringLiteral(helperName)
                let escapedMock = escapeForStringLiteral(mockName)
                lines.append("ProtoMockFailureHandling.fail(\"Unstubbed call to \(escapedHelper) on \(escapedMock)\")")
            }
        }

        return lines
    }

    static func unsynchronizedFunctionBodyLines(
        for functionDecl: FunctionDeclSyntax,
        helperName: String,
        mockName: String,
        traits: FunctionTraits,
        mockAutoDefault: Bool
    ) -> [String] {
        var lines = ["\(helperName)CallCount += 1"]
        if let argumentValue = traits.argumentValue {
            lines.append("\(helperName)ReceivedArguments.append(\(argumentValue))")
        }

        lines.append(
            contentsOf: handlerInvocationLines(
                for: functionDecl,
                handlerBinding: "\(helperName)Handler",
                returnsValue: traits.returnsValue,
                localNames: traits.localNames,
                isThrowing: traits.isThrowing
            )
        )

        if traits.supportsErrorInjection {
            lines.append("if let error = \(helperName)Error {")
            lines.append("    throw error")
            lines.append("}")
        }

        if traits.returnsValue {
            lines.append("if case .value(let value) = \(helperName)ReturnStub {")
            lines.append("    return value")
            lines.append("}")
            if mockAutoDefault, let defaultExpr = autoDefaultExpression(for: traits.returnType) {
                lines.append("return \(defaultExpr)")
            } else {
                let escapedHelper = escapeForStringLiteral(helperName)
                let escapedMock = escapeForStringLiteral(mockName)
                lines.append("ProtoMockFailureHandling.fail(\"Unstubbed call to \(escapedHelper) on \(escapedMock)\")")
            }
        }

        return lines
    }

    static func handlerInvocationLines(
        for functionDecl: FunctionDeclSyntax,
        handlerBinding: String,
        returnsValue: Bool,
        localNames: [String?],
        isThrowing: Bool
    ) -> [String] {
        let invocationArguments = localNames.compactMap(\.self).joined(separator: ", ")
        let invocation = "handler(\(invocationArguments))"
        let invokedHandler = handlerInvocationExpression(
            for: functionDecl,
            invocation: invocation,
            isThrowing: isThrowing
        )

        var lines = ["if let handler = \(handlerBinding) {"]
        if returnsValue {
            lines.append("    return \(invokedHandler)")
        } else {
            lines.append("    \(invokedHandler)")
            lines.append("    return")
        }
        lines.append("}")
        return lines
    }

    static func handlerInvocationExpression(
        for functionDecl: FunctionDeclSyntax,
        invocation: String,
        isThrowing: Bool
    ) -> String {
        if functionDecl.signature.effectSpecifiers?.asyncSpecifier != nil, isThrowing {
            return "try await \(invocation)"
        }
        if functionDecl.signature.effectSpecifiers?.asyncSpecifier != nil {
            return "await \(invocation)"
        }
        if isThrowing {
            return "try \(invocation)"
        }
        return invocation
    }

    static func functionHandlerType(_ functionDecl: FunctionDeclSyntax) -> String {
        let parameterTypes = functionDecl.signature.parameterClause.parameters.map {
            removeEscapingAttributes(from: $0.type).trimmedDescription
        }

        // Normalize effect specifiers for closure types:
        // `rethrows` is not valid in closure type positions, so replace with `throws`.
        let effectSpecifiers: String =
            if let specifiers = functionDecl.signature.effectSpecifiers {
                specifiers.with(
                    \.throwsClause,
                    specifiers.throwsClause.map { clause in
                        clause.throwsSpecifier.tokenKind == .keyword(.rethrows)
                            ? clause.with(\.throwsSpecifier, .keyword(.throws))
                            : clause
                    }
                ).trimmedDescription
            } else {
                ""
            }
        let resultType = functionDecl.signature.returnClause?.type.trimmedDescription ?? "Void"

        let parameterList =
            if parameterTypes.isEmpty {
                "()"
            } else {
                "(\(parameterTypes.joined(separator: ", ")))"
            }

        if effectSpecifiers.isEmpty {
            return "\(parameterList) -> \(resultType)"
        }
        return "\(parameterList) \(effectSpecifiers) -> \(resultType)"
    }
}
