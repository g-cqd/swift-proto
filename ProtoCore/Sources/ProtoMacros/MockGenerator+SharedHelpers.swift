//
//  MockGenerator+SharedHelpers.swift
//  Proto
//
//  Created by Guillaume Coquard on 18.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftSyntax

// MARK: - Shared Helpers

extension MockGenerator {
    /// Modifiers stripped from mock member declarations (invalid on class/actor members).
    private static let strippedMockModifiers: Set<String> = [
        "mutating", "required", "convenience",
    ]

    static func mockAttributes(
        attributes: AttributeListSyntax,
        includeProtoMockIgnored: Bool = false
    ) -> AttributeListSyntax {
        var items = [AttributeListSyntax.Element]()
        for element in attributes {
            guard case .attribute(let attribute) = element else { continue }
            if !includeProtoMockIgnored, attribute.attributeName.trimmedDescription == "ProtoMockIgnored" {
                continue
            }
            items.append(element)
        }
        return AttributeListSyntax(items)
    }

    static func mockModifiers(
        modifiers: DeclModifierListSyntax,
        visibilityKeyword: String?,
        mockIsActor: Bool
    ) -> DeclModifierListSyntax {
        var result = [DeclModifierSyntax]()

        if let visibilityKeyword {
            result.append(DeclModifierSyntax(name: modifierToken(for: visibilityKeyword), trailingTrivia: .space))
        }

        for modifier in modifiers {
            let name = modifier.name.trimmedDescription
            if strippedMockModifiers.contains(name) {
                continue
            }
            if !mockIsActor, name == "nonisolated" {
                continue
            }
            var filtered = modifier.trimmed
            filtered.trailingTrivia = .space
            result.append(filtered)
        }

        return DeclModifierListSyntax(result)
    }

    static func getterEffectSpecifiers(
        in accessorBlock: AccessorBlockSyntax?
    ) -> AccessorEffectSpecifiersSyntax? {
        guard let accessorBlock,
            case .accessors(let accessors) = accessorBlock.accessors
        else {
            return nil
        }

        for accessor in accessors where accessor.accessorSpecifier.trimmedDescription == "get" {
            guard let specifiers = accessor.effectSpecifiers else { return nil }
            var result = AccessorEffectSpecifiersSyntax()
            if specifiers.asyncSpecifier != nil {
                result.asyncSpecifier = .keyword(.async, trailingTrivia: .space)
            }
            if specifiers.throwsClause != nil {
                result.throwsClause = ThrowsClauseSyntax(
                    throwsSpecifier: .keyword(.throws, trailingTrivia: .space)
                )
            }
            return result.asyncSpecifier != nil || result.throwsClause != nil ? result : nil
        }
        return nil
    }

    static func visibilityKeyword(for accessLevel: MemberExtractor.AccessLevel) -> String? {
        switch accessLevel {
        case .private:
            "private"
        case .fileprivate:
            "fileprivate"
        case .internal:
            nil
        case .package:
            "package"
        case .public, .open:
            "public"
        }
    }

    /// Escapes double quotes in a string for embedding in a string literal.
    static func escapeForStringLiteral(_ value: String) -> String {
        String(
            value.flatMap { character in
                character == "\"" ? ["\\", "\""] as [Character] : [character]
            }
        )
    }

    static func sanitizeHelperIdentifier(_ base: String) -> String {
        var sanitized = String(
            base.map { character in
                if character.isLetter || character.isNumber {
                    character
                } else {
                    "_"
                }
            }
        )

        while sanitized.first == "_" {
            sanitized.removeFirst()
        }
        while sanitized.last == "_" {
            sanitized.removeLast()
        }

        if sanitized.isEmpty {
            return "member"
        }
        if let first = sanitized.first, first.isNumber {
            return "_\(sanitized)"
        }
        return sanitized
    }

    /// Derives a mock default expression from a type name by Proto naming convention.
    /// Returns the expression string (e.g., `"FooMock()"`) or `nil` if the type doesn't match.
    static func autoDefaultExpression(for typeName: String?) -> String? {
        guard let typeName else { return nil }

        // Bare: "FooProtocol" → "FooMock()"
        if typeName.hasSuffix("Protocol") {
            let base = String(typeName.dropLast("Protocol".count))
            guard !base.isEmpty else { return nil }
            return "\(base)Mock()"
        }

        // Optional shorthand: "FooProtocol?" → "FooMock()"
        if typeName.hasSuffix("Protocol?") {
            let base = String(typeName.dropLast("Protocol?".count))
            guard !base.isEmpty else { return nil }
            return "\(base)Mock()"
        }

        // Optional<FooProtocol> → "FooMock()"
        if typeName.hasPrefix("Optional<"), typeName.hasSuffix(">") {
            let inner = String(typeName.dropFirst("Optional<".count).dropLast(1))
            return autoDefaultExpression(for: inner)
        }

        // Array shorthand: "[FooProtocol]" → "[FooMock()]"
        if typeName.hasPrefix("["), typeName.hasSuffix("]"), !typeName.contains(":") {
            let inner = String(typeName.dropFirst(1).dropLast(1))
            if let innerExpr = autoDefaultExpression(for: inner) {
                return "[\(innerExpr)]"
            }
        }

        // Array<FooProtocol> → "[FooMock()]"
        if typeName.hasPrefix("Array<"), typeName.hasSuffix(">") {
            let inner = String(typeName.dropFirst("Array<".count).dropLast(1))
            if let innerExpr = autoDefaultExpression(for: inner) {
                return "[\(innerExpr)]"
            }
        }

        return nil
    }

    static func localParameterNames(_ parameters: [FunctionParameterSyntax]) -> [String?] {
        parameters.map { parameter in
            let name = parameter.secondName?.trimmedDescription ?? parameter.firstName.trimmedDescription
            return name == "_" ? nil : name
        }
    }

    static func capturedArgumentType(for parameters: [FunctionParameterSyntax]) -> String? {
        guard !parameters.isEmpty else { return nil }

        if parameters.count == 1,
            let parameter = parameters.first
        {
            return removeEscapingAttributes(from: parameter.type).trimmedDescription
        }

        let types = parameters.map {
            removeEscapingAttributes(from: $0.type).trimmedDescription
        }
        return "(\(types.joined(separator: ", ")))"
    }

    static func capturedArgumentValue(for localNames: [String?]) -> String? {
        let names = localNames.compactMap(\.self)
        guard !names.isEmpty else { return nil }
        if names.count == 1 {
            return names[0]
        }
        return "(\(names.joined(separator: ", ")))"
    }

    static func removeEscapingAttributes(from type: TypeSyntax) -> TypeSyntax {
        RemoveEscapingAttributeRewriter().rewrite(type).as(TypeSyntax.self) ?? type
    }

    static func modifierToken(for keyword: String) -> TokenSyntax {
        switch keyword {
        case "private":
            .keyword(.private)
        case "fileprivate":
            .keyword(.fileprivate)
        case "internal":
            .keyword(.internal)
        case "package":
            .keyword(.package)
        case "public":
            .keyword(.public)
        case "open":
            .keyword(.open)
        default:
            .identifier(keyword)
        }
    }
}

/// Removes `@escaping` from attributed types so captured-argument storage types remain valid.
private final class RemoveEscapingAttributeRewriter: SyntaxRewriter {
    override func visit(_ node: AttributedTypeSyntax) -> TypeSyntax {
        let filtered = node.attributes.filter { element in
            guard let attribute = element.as(AttributeSyntax.self) else { return true }
            return attribute.attributeName.trimmedDescription != "escaping"
        }
        return TypeSyntax(node.with(\.attributes, filtered))
    }
}
