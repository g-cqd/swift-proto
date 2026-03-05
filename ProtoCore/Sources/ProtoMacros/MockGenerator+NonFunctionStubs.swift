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
// Generated stubs for properties, initializers, and subscripts.
//
// Properties: By default, get-only properties receive private backing storage
// and a setter method (e.g. `setName(_:)`). When `mockPropertySetters` is
// false, or the property already has a setter, a failure stub or auto-default
// is used instead. Mutable properties use a standard stored property stub.
//
// Initializers and subscripts: Fail fast via
// `ProtoMockFailureHandling.fail(...)`. This records a `Testing` issue when
// available and then terminates with `preconditionFailure`.

extension MockGenerator {
    static func renderPropertyStub(
        _ variableDecl: VariableDeclSyntax,
        mockName: String,
        visibilityKeyword: String?,
        mockIsActor: Bool,
        mockAutoDefault: Bool = false,
        mockPropertySetters: Bool = true
    ) -> [DeclSyntax] {
        guard let binding = variableDecl.bindings.first,
            let typeAnnotation = binding.typeAnnotation
        else {
            return []
        }

        let name = binding.pattern.trimmedDescription
        let getterEffects = getterEffectSpecifiers(in: binding.accessorBlock)
        let hasSetter = binding.accessorBlock.map(ProtocolGenerator.accessorBlockHasSetter) ?? false
        let typeName = typeAnnotation.type.trimmedDescription
        let needsBackingStorage = mockPropertySetters && !hasSetter
        let hasDefaultExpr = mockAutoDefault ? autoDefaultExpression(for: typeName) : nil

        var result: [DeclSyntax] = []

        if needsBackingStorage {
            result.append(renderBackingStorage(
                propertyName: name,
                typeName: typeName,
                hasDefaultExpr: hasDefaultExpr
            ))
        }

        var transformedBinding = binding.trimmed
        transformedBinding.typeAnnotation = typeAnnotation
        transformedBinding.initializer = nil
        transformedBinding.trailingComma = nil

        if needsBackingStorage {
            transformedBinding.accessorBlock = backingStorageAccessorBlock(
                propertyName: name,
                typeName: typeName,
                getterEffects: getterEffects,
                mockName: mockName,
                hasDefaultExpr: hasDefaultExpr
            )
        } else if mockAutoDefault, let defaultExpr = autoDefaultExpression(for: typeName) {
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
        result.append(DeclSyntax(declaration))

        if needsBackingStorage {
            result.append(renderPropertySetterMethod(
                propertyName: name,
                typeName: typeName,
                getterEffects: getterEffects,
                visibilityKeyword: visibilityKeyword
            ))
        }

        return result
    }

    private static func renderBackingStorage(
        propertyName: String,
        typeName: String,
        hasDefaultExpr: String?
    ) -> DeclSyntax {
        if let defaultExpr = hasDefaultExpr {
            return DeclSyntax(stringLiteral: "private var _\(propertyName)Value: \(typeName) = \(defaultExpr)")
        } else {
            return DeclSyntax(stringLiteral: "private var _\(propertyName)Value: \(typeName)?")
        }
    }

    private static func backingStorageAccessorBlock(
        propertyName: String,
        typeName: String,
        getterEffects: AccessorEffectSpecifiersSyntax?,
        mockName: String,
        hasDefaultExpr: String?
    ) -> AccessorBlockSyntax {
        var getter = AccessorDeclSyntax(accessorSpecifier: .keyword(.get))
        getter.effectSpecifiers = getterEffects

        let getterBody: String
        if hasDefaultExpr != nil {
            getterBody = "{\n            _\(propertyName)Value\n        }"
        } else {
            let escapedPropertyName = escapeForStringLiteral(propertyName)
            let escapedMockName = escapeForStringLiteral(mockName)
            getterBody = "{\n"
                + "            guard let value = _" + propertyName + "Value else {\n"
                + "                ProtoMockFailureHandling.fail(\"Unstubbed property '" + escapedPropertyName + "' on " + escapedMockName + "\")\n"
                + "            }\n"
                + "            return value\n"
                + "        }"
        }

        getter.body = CodeBlockSyntax(stringLiteral: getterBody)
        getter.leadingTrivia = .newline + .spaces(8)

        return AccessorBlockSyntax(
            leftBrace: .leftBraceToken(leadingTrivia: .space),
            accessors: .accessors(AccessorDeclListSyntax([getter])),
            rightBrace: .rightBraceToken(leadingTrivia: .newline + .spaces(4))
        )
    }

    private static func renderPropertySetterMethod(
        propertyName: String,
        typeName: String,
        getterEffects: AccessorEffectSpecifiersSyntax?,
        visibilityKeyword: String?
    ) -> DeclSyntax {
        let isAsync = getterEffects?.asyncSpecifier != nil

        let visibilityPrefix = visibilityKeyword.map { "\($0) " } ?? ""
        let setterName = "set\(propertyName.prefix(1).uppercased() + propertyName.dropFirst())"
        let asyncKeyword = isAsync ? " async" : ""

        let source = "\(visibilityPrefix)func \(setterName)(_ value: \(typeName))\(asyncKeyword) {\n"
            + "        _\(propertyName)Value = value\n"
            + "    }"

        return DeclSyntax(stringLiteral: source)
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
