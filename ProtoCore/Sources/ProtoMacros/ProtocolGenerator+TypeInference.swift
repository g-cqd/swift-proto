//
//  ProtocolGenerator+TypeInference.swift
//  Proto
//
//  Created by Guillaume Coquard on 18.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftSyntax

// MARK: - Type Inference from Initializer Expressions

extension ProtocolGenerator {
    /// Attempt to infer a `TypeAnnotationSyntax` from an initializer expression.
    ///
    /// Handles primitive literals (`String`, `Int`, `Double`, `Bool`), negated
    /// numeric literals, constructor calls (e.g. `Data()`, `Set<String>()`),
    /// array literals, dictionary literals, and tuple expressions.
    ///
    /// ## Limitations
    /// - **Function calls**: `someFunc()` returns `nil` — only uppercase constructors are recognized.
    /// - **Optional literals**: `nil` has no inferrable type.
    /// - **Closures / ternaries**: Not supported.
    /// - **Heterogeneous collections**: `[1, "a"]` infers from the first element only → `[Int]`.
    /// - **Single-element tuples**: `(x)` is treated as a parenthesized expression, not a tuple.
    /// - **Chained expressions**: `Foo().bar` is not recognized.
    ///
    /// When inference fails, the caller should emit ``ProtoMemberDiagnostic/uninferablePropertyType``.
    static func inferType(from initializer: InitializerClauseSyntax) -> TypeAnnotationSyntax? {
        guard let inferred = inferTypeFromExpr(initializer.value) else {
            return nil
        }
        return TypeAnnotationSyntax(
            colon: .colonToken(trailingTrivia: .space),
            type: inferred
        )
    }
}

// MARK: - Expression Dispatch

private extension ProtocolGenerator {
    static func inferTypeFromExpr(_ expr: ExprSyntax) -> TypeSyntax? {
        if expr.is(StringLiteralExprSyntax.self) {
            return simpleType("String")
        }
        if expr.is(IntegerLiteralExprSyntax.self) {
            return simpleType("Int")
        }
        if expr.is(FloatLiteralExprSyntax.self) {
            return simpleType("Double")
        }
        if expr.is(BooleanLiteralExprSyntax.self) {
            return simpleType("Bool")
        }
        if let prefix = expr.as(PrefixOperatorExprSyntax.self) {
            return inferFromPrefix(prefix)
        }
        if let call = expr.as(FunctionCallExprSyntax.self) {
            return inferFromCall(call)
        }
        if let array = expr.as(ArrayExprSyntax.self) {
            return inferFromArray(array)
        }
        if let dict = expr.as(DictionaryExprSyntax.self) {
            return inferFromDictionary(dict)
        }
        if let tuple = expr.as(TupleExprSyntax.self), tuple.elements.count >= 2 {
            return inferFromTuple(tuple)
        }
        return nil
    }
}

// MARK: - Specific Inference Strategies

private extension ProtocolGenerator {
    static func inferFromPrefix(_ prefix: PrefixOperatorExprSyntax) -> TypeSyntax? {
        if prefix.expression.is(IntegerLiteralExprSyntax.self) {
            return simpleType("Int")
        }
        if prefix.expression.is(FloatLiteralExprSyntax.self) {
            return simpleType("Double")
        }
        return nil
    }

    static func inferFromCall(_ call: FunctionCallExprSyntax) -> TypeSyntax? {
        // Simple constructor: Data(), UUID()
        if let declRef = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            let name = declRef.baseName.text
            guard let first = name.first, first.isUppercase else { return nil }
            return simpleType(name)
        }
        // Generic constructor: Set<String>(), Array<Int>()
        if let generic = call.calledExpression.as(GenericSpecializationExprSyntax.self),
            let declRef = generic.expression.as(DeclReferenceExprSyntax.self)
        {
            let name = declRef.baseName.text
            guard let first = name.first, first.isUppercase else { return nil }
            return TypeSyntax(
                IdentifierTypeSyntax(
                    name: .identifier(name),
                    genericArgumentClause: generic.genericArgumentClause
                )
            )
        }
        return nil
    }

    static func inferFromArray(_ array: ArrayExprSyntax) -> TypeSyntax? {
        guard let first = array.elements.first,
            let elementType = inferTypeFromExpr(first.expression)
        else { return nil }
        return TypeSyntax(ArrayTypeSyntax(element: elementType))
    }

    static func inferFromDictionary(_ dict: DictionaryExprSyntax) -> TypeSyntax? {
        guard case .elements(let elements) = dict.content,
            let first = elements.first,
            let keyType = inferTypeFromExpr(first.key),
            let valueType = inferTypeFromExpr(first.value)
        else { return nil }
        return TypeSyntax(
            DictionaryTypeSyntax(
                key: keyType,
                colon: .colonToken(trailingTrivia: .space),
                value: valueType
            )
        )
    }

    static func inferFromTuple(_ tuple: TupleExprSyntax) -> TypeSyntax? {
        let elements = tuple.elements
        var typeElements: [TupleTypeElementSyntax] = []
        for (index, element) in elements.enumerated() {
            guard let type = inferTypeFromExpr(element.expression) else { return nil }
            let isLast = index == elements.count - 1
            typeElements.append(
                TupleTypeElementSyntax(
                    firstName: element.label,
                    colon: element.label != nil ? .colonToken(trailingTrivia: .space) : nil,
                    type: type,
                    trailingComma: isLast ? nil : .commaToken(trailingTrivia: .space)
                )
            )
        }
        return TypeSyntax(TupleTypeSyntax(elements: TupleTypeElementListSyntax(typeElements)))
    }

    static func simpleType(_ name: String) -> TypeSyntax {
        TypeSyntax(IdentifierTypeSyntax(name: .identifier(name)))
    }
}
