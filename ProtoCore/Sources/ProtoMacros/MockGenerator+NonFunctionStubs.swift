//
//  MockGenerator+NonFunctionStubs.swift
//  Proto
//
//  Created by Guillaume Coquard on 18.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftSyntax

// MARK: - Non-Function Stubs

//
// Generated stubs for properties, initializers, and subscripts fail fast via
// `ProtoMockFailureHandling.fail(...)`. This records a `Testing` issue when
// available and then terminates with `preconditionFailure`.

extension MockGenerator {
    static func renderPropertyStub(
        _ variableDecl: VariableDeclSyntax,
        mockName: String,
        visibilityKeyword: String?,
        mockIsActor: Bool,
        mockAutoDefault: Bool = false
    ) -> DeclSyntax? {
        guard let binding = variableDecl.bindings.first,
            let typeAnnotation = binding.typeAnnotation
        else {
            return nil
        }

        let name = binding.pattern.trimmedDescription
        let getterEffects = getterEffectSpecifiers(in: binding.accessorBlock)
        let hasSetter = binding.accessorBlock.map(ProtocolGenerator.accessorBlockHasSetter) ?? false
        let typeName = typeAnnotation.type.trimmedDescription

        var transformedBinding = binding.trimmed
        transformedBinding.typeAnnotation = typeAnnotation
        transformedBinding.initializer = nil
        transformedBinding.trailingComma = nil

        if mockAutoDefault, let defaultExpr = autoDefaultExpression(for: typeName) {
            transformedBinding.accessorBlock = autoDefaultAccessorBlock(
                getterEffects: getterEffects,
                hasSetter: hasSetter,
                defaultExpression: defaultExpr
            )
        } else {
            let escapedName = escapeForStringLiteral(name)
            let escapedMockName = escapeForStringLiteral(mockName)
            transformedBinding.accessorBlock = failureAccessorBlock(
                getterEffects: getterEffects,
                hasSetter: hasSetter,
                failureMessage: "Unstubbed property '\(escapedName)' on \(escapedMockName)"
            )
        }

        var declaration = variableDecl.trimmed
        declaration.attributes = mockAttributes(attributes: variableDecl.attributes)
        declaration.modifiers = mockModifiers(
            modifiers: variableDecl.modifiers,
            visibilityKeyword: visibilityKeyword,
            mockIsActor: mockIsActor
        )
        declaration.bindings = PatternBindingListSyntax([transformedBinding])
        declaration.leadingTrivia = []
        declaration.trailingTrivia = []
        return DeclSyntax(declaration)
    }

    static func renderInitializerStub(
        _ initializerDecl: InitializerDeclSyntax,
        mockName: String,
        visibilityKeyword: String?,
        mockIsActor: Bool,
        mockAutoDefault: Bool = false
    ) -> DeclSyntax {
        var declaration = initializerDecl.trimmed
        declaration.attributes = mockAttributes(attributes: initializerDecl.attributes)
        declaration.modifiers = mockModifiers(
            modifiers: initializerDecl.modifiers,
            visibilityKeyword: visibilityKeyword,
            mockIsActor: mockIsActor
        )
        if mockAutoDefault {
            declaration.body = emptyBody(closingIndent: 4)
        } else {
            let escapedMockName = escapeForStringLiteral(mockName)
            declaration.body = failureBody(
                message: "Unstubbed initializer on \(escapedMockName)",
                statementIndent: 8,
                closingIndent: 4
            )
        }
        declaration.leadingTrivia = []
        declaration.trailingTrivia = []
        return DeclSyntax(declaration)
    }

    static func renderSubscriptStub(
        _ subscriptDecl: SubscriptDeclSyntax,
        mockName: String,
        visibilityKeyword: String?,
        mockIsActor: Bool,
        mockAutoDefault: Bool = false
    ) -> DeclSyntax {
        let getterEffects = getterEffectSpecifiers(in: subscriptDecl.accessorBlock)
        let hasSetter = subscriptDecl.accessorBlock.map(ProtocolGenerator.accessorBlockHasSetter) ?? false
        let returnTypeName = subscriptDecl.returnClause.type.trimmedDescription

        var declaration = subscriptDecl.trimmed
        declaration.attributes = mockAttributes(attributes: subscriptDecl.attributes)
        declaration.modifiers = mockModifiers(
            modifiers: subscriptDecl.modifiers,
            visibilityKeyword: visibilityKeyword,
            mockIsActor: mockIsActor
        )

        if mockAutoDefault, let defaultExpr = autoDefaultExpression(for: returnTypeName) {
            declaration.accessorBlock = autoDefaultAccessorBlock(
                getterEffects: getterEffects,
                hasSetter: hasSetter,
                defaultExpression: defaultExpr
            )
        } else {
            let escapedSubMockName = escapeForStringLiteral(mockName)
            declaration.accessorBlock = failureAccessorBlock(
                getterEffects: getterEffects,
                hasSetter: hasSetter,
                failureMessage: "Unstubbed subscript on \(escapedSubMockName)"
            )
        }
        declaration.leadingTrivia = []
        declaration.trailingTrivia = []
        return DeclSyntax(declaration)
    }

    private static func failureAccessorBlock(
        getterEffects: AccessorEffectSpecifiersSyntax?,
        hasSetter: Bool,
        failureMessage: String
    ) -> AccessorBlockSyntax {
        var getter = AccessorDeclSyntax(accessorSpecifier: .keyword(.get))
        getter.effectSpecifiers = getterEffects
        getter.body = failureBody(
            message: failureMessage,
            statementIndent: 12,
            closingIndent: 8
        )

        var accessors = [getter]
        if hasSetter {
            var setter = AccessorDeclSyntax(accessorSpecifier: .keyword(.set))
            setter.body = emptyBody(closingIndent: 8)
            accessors.append(setter)
        }

        for index in accessors.indices {
            accessors[index].leadingTrivia = .newline + .spaces(8)
        }

        return AccessorBlockSyntax(
            leftBrace: .leftBraceToken(leadingTrivia: .space),
            accessors: .accessors(AccessorDeclListSyntax(accessors)),
            rightBrace: .rightBraceToken(leadingTrivia: .newline + .spaces(4))
        )
    }

    private static func autoDefaultAccessorBlock(
        getterEffects: AccessorEffectSpecifiersSyntax?,
        hasSetter: Bool,
        defaultExpression: String
    ) -> AccessorBlockSyntax {
        var getter = AccessorDeclSyntax(accessorSpecifier: .keyword(.get))
        getter.effectSpecifiers = getterEffects
        let source = "{\n            return \(defaultExpression)\n        }"
        getter.body = CodeBlockSyntax(stringLiteral: source)

        var accessors = [getter]
        if hasSetter {
            var setter = AccessorDeclSyntax(accessorSpecifier: .keyword(.set))
            setter.body = emptyBody(closingIndent: 8)
            accessors.append(setter)
        }

        for index in accessors.indices {
            accessors[index].leadingTrivia = .newline + .spaces(8)
        }

        return AccessorBlockSyntax(
            leftBrace: .leftBraceToken(leadingTrivia: .space),
            accessors: .accessors(AccessorDeclListSyntax(accessors)),
            rightBrace: .rightBraceToken(leadingTrivia: .newline + .spaces(4))
        )
    }

    private static func failureBody(
        message: String,
        statementIndent: Int,
        closingIndent: Int
    ) -> CodeBlockSyntax {
        let statementPadding = String(repeating: " ", count: statementIndent)
        let closingPadding = String(repeating: " ", count: closingIndent)
        let source = "{\n\(statementPadding)ProtoMockFailureHandling.fail(\"\(message)\")\n\(closingPadding)}"
        return CodeBlockSyntax(stringLiteral: source)
    }

    private static func emptyBody(closingIndent: Int) -> CodeBlockSyntax {
        let closingPadding = String(repeating: " ", count: closingIndent)
        return CodeBlockSyntax(stringLiteral: "{\n\(closingPadding)}")
    }
}
