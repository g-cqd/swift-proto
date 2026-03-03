//
//  ProtocolGenerator+Helpers.swift
//  Proto
//
//  Created by Guillaume Coquard on 17.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftSyntax

// MARK: - Type Rewriter

/// Rewrites `IdentifierTypeSyntax` nodes, replacing the declaring type name
/// with `Self` and resolving typealias names to their underlying types.
final class TypeRewriter: SyntaxRewriter {
    private let typeName: String
    private let typeAliases: [String: TypeSyntax]

    init(typeName: String, typeAliases: [String: TypeSyntax] = [:]) {
        self.typeName = typeName
        self.typeAliases = typeAliases
    }

    override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
        let name = node.name.trimmedDescription
        var result = node
        if name == typeName {
            result = result.with(
                \.name,
                .identifier(
                    "Self",
                    leadingTrivia: node.name.leadingTrivia,
                    trailingTrivia: node.name.trailingTrivia
                )
            )
        } else if let resolved = typeAliases[name] {
            return resolved.with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        }

        // Recurse into generic argument clause (e.g. Array<Foo.Bar> → Array<Self.Bar>)
        if let genericArgs = result.genericArgumentClause {
            let rewritten = rewrite(Syntax(genericArgs))
            if let rewrittenClause = rewritten.as(GenericArgumentClauseSyntax.self) {
                result = result.with(\.genericArgumentClause, rewrittenClause)
            }
        }
        return TypeSyntax(result)
    }

    override func visit(_ node: MemberTypeSyntax) -> TypeSyntax {
        let baseName = node.baseType.as(IdentifierTypeSyntax.self)?.name.trimmedDescription
        var result = node
        if baseName == typeName {
            result = result.with(
                \.baseType,
                TypeSyntax(
                    IdentifierTypeSyntax(
                        name: .identifier(
                            "Self",
                            leadingTrivia: node.baseType.leadingTrivia,
                            trailingTrivia: node.baseType.trailingTrivia
                        )
                    )
                )
            )
        } else {
            // Recurse into the base type to handle deeper nesting (e.g. Foo.Bar.Baz)
            let rewrittenBase = rewrite(Syntax(node.baseType))
            if let rewrittenType = rewrittenBase.as(TypeSyntax.self) {
                result = result.with(\.baseType, rewrittenType)
            }
        }
        return TypeSyntax(result)
    }
}

extension ProtocolGenerator {
    /// Apply type rewriting to a declaration, replacing the declaring type name
    /// with `Self` and resolving type aliases.
    static func rewriteTypes<D: DeclSyntaxProtocol>(
        in decl: D,
        typeName: String,
        typeAliases: [String: TypeSyntax]
    ) -> D {
        guard !typeName.isEmpty else { return decl }
        let rewriter = TypeRewriter(typeName: typeName, typeAliases: typeAliases)
        return rewriter.rewrite(decl).cast(D.self)
    }
}

extension ProtocolGenerator {
    /// Generate `associatedtype` declarations from generic parameters.
    static func associatedtypeDecls(
        from genericParameterClause: GenericParameterClauseSyntax?
    ) -> [MemberBlockItemSyntax] {
        guard let genericParams = genericParameterClause else { return [] }
        return genericParams.parameters.map { param in
            var assocType = AssociatedTypeDeclSyntax(
                name: param.name.trimmed
            )
            if let inheritedType = param.inheritedType {
                assocType.inheritanceClause = InheritanceClauseSyntax(
                    colon: .colonToken(trailingTrivia: .space),
                    inheritedTypes: InheritedTypeListSyntax([
                        InheritedTypeSyntax(type: inheritedType.trimmed)
                    ])
                )
            }
            var memberItem = MemberBlockItemSyntax(decl: assocType)
            memberItem.leadingTrivia = .newline + .spaces(4)
            return memberItem
        }
    }

    /// Build a `PrimaryAssociatedTypeClauseSyntax` from an array of type names.
    /// Returns `nil` when the array is empty.
    static func primaryAssociatedTypeClause(
        from names: [String]
    ) -> PrimaryAssociatedTypeClauseSyntax? {
        guard !names.isEmpty else { return nil }
        let types = PrimaryAssociatedTypeListSyntax(
            names.enumerated().map { index, name in
                PrimaryAssociatedTypeSyntax(
                    name: .identifier(name),
                    trailingComma: index < names.count - 1 ? .commaToken(trailingTrivia: .space) : nil
                )
            }
        )
        return PrimaryAssociatedTypeClauseSyntax(
            primaryAssociatedTypes: types
        )
    }

    /// Build a compact accessor block for generated property/subscript requirements.
    ///
    /// Constructs `AccessorBlockSyntax` using SwiftSyntaxBuilder directly.
    /// Setters are invalid on async/throwing getters.
    static func compactAccessorBlock(
        hasSetter: Bool,
        needsAsync: Bool = false,
        needsThrows: Bool = false
    ) -> AccessorBlockSyntax {
        var accessors: [AccessorDeclSyntax] = []

        var getter = AccessorDeclSyntax(accessorSpecifier: .keyword(.get))
        if needsAsync || needsThrows {
            var specifiers = AccessorEffectSpecifiersSyntax()
            if needsAsync {
                specifiers.asyncSpecifier = .keyword(.async)
            }
            if needsThrows {
                specifiers.throwsClause = ThrowsClauseSyntax(
                    throwsSpecifier: .keyword(.throws)
                )
            }
            getter.effectSpecifiers = specifiers
        }
        accessors.append(getter)

        if hasSetter {
            accessors.append(AccessorDeclSyntax(accessorSpecifier: .keyword(.set)))
        }

        // Format with leading newline + 8 spaces for each accessor
        for i in accessors.indices {
            accessors[i].leadingTrivia = .newline + .spaces(8)
        }

        return AccessorBlockSyntax(
            leftBrace: .leftBraceToken(leadingTrivia: .space),
            accessors: .accessors(AccessorDeclListSyntax(accessors)),
            rightBrace: .rightBraceToken(leadingTrivia: .newline + .spaces(4))
        )
    }

    /// Extract existing getter effect specifiers (async/throws) from an accessor block.
    static func existingGetterEffects(
        _ block: AccessorBlockSyntax?
    ) -> (isAsync: Bool, isThrows: Bool) {
        guard let block, case .accessors(let list) = block.accessors else {
            return (false, false)
        }
        for accessor in list where accessor.accessorSpecifier.trimmedDescription == "get" {
            let isAsync = accessor.effectSpecifiers?.asyncSpecifier != nil
            let isThrows = accessor.effectSpecifiers?.throwsClause != nil
            return (isAsync, isThrows)
        }
        return (false, false)
    }

    /// Check if an accessor block contains a setter.
    /// `willSet`/`didSet` imply a stored property with a setter.
    static func accessorBlockHasSetter(_ block: AccessorBlockSyntax) -> Bool {
        switch block.accessors {
        case .accessors(let list):
            list.contains {
                let specifier = $0.accessorSpecifier.trimmedDescription
                return specifier == "set" || specifier == "willSet" || specifier == "didSet"
            }
        case .getter:
            false
        }
    }

    /// Filter out modifiers that shouldn't appear in protocol requirements.
    static func filterModifiers(_ modifiers: DeclModifierListSyntax) -> DeclModifierListSyntax {
        DeclModifierListSyntax {
            for modifier in modifiers where !strippedModifiers.contains(modifier.name.trimmedDescription) {
                modifier
            }
        }
    }

    static func hasModifier(_ modifiers: DeclModifierListSyntax, named name: String) -> Bool {
        modifiers.contains { $0.name.trimmedDescription == name }
    }

    static func applyIsolationModifiers(
        to modifiers: DeclModifierListSyntax,
        forceNonisolated: Bool,
        forceIsolated: Bool
    ) -> DeclModifierListSyntax {
        var list = Array(modifiers)

        if forceIsolated {
            list.removeAll { $0.name.trimmedDescription == "nonisolated" }
        } else if forceNonisolated, !hasModifier(DeclModifierListSyntax(list), named: "nonisolated") {
            list.insert(DeclModifierSyntax(name: .keyword(.nonisolated), trailingTrivia: .space), at: 0)
        }

        return DeclModifierListSyntax(list)
    }

    /// Filter out attributes that shouldn't appear in protocol requirements.
    static func filterAttributes(_ attributes: AttributeListSyntax) -> AttributeListSyntax {
        AttributeListSyntax {
            for element in attributes {
                if case .attribute(let attr) = element,
                    strippedAttributes.contains(attr.attributeName.trimmedDescription)
                {
                    // skip
                } else {
                    element
                }
            }
        }
    }

    /// Filter out default values in function signatures
    static func filterDefaultValues(signature: FunctionSignatureSyntax) -> FunctionSignatureSyntax {
        signature.with(\.parameterClause, filterDefaultValues(parameterClause: signature.parameterClause))
    }

    static func filterDefaultValues(parameterClause: FunctionParameterClauseSyntax) -> FunctionParameterClauseSyntax {
        FunctionParameterClauseSyntax {
            for parameter in parameterClause.parameters {
                filterDefaultValues(parameter: parameter)
            }
        }
    }

    /// Remove default values from parameters, as they aren't allowed in protocol requirements.
    private static func filterDefaultValues(parameter: FunctionParameterSyntax) -> FunctionParameterSyntax {
        guard parameter.defaultValue != nil else { return parameter }
        return
            parameter
            .with(\.defaultValue, nil)
            .with(\.type.trailingTrivia, [])
    }

    /// Get type-level attributes that should propagate to the protocol.
    static func propagatedAttributes(from attributes: AttributeListSyntax) -> AttributeListSyntax {
        var items: [AttributeListSyntax.Element] = []
        for element in attributes {
            guard case .attribute(let attr) = element else { continue }
            let name = attr.attributeName.trimmedDescription
            if propagatedAttributeNames.contains(name) {
                items.append(element)
            }
        }
        guard !items.isEmpty else {
            return []
        }
        if var last = items.last {
            last.trailingTrivia = .newline
            items[items.count - 1] = last
        }
        return AttributeListSyntax {
            for item in items {
                item
            }
        }
    }

    /// Map our access level to a Swift keyword.
    /// Note: `open` is not valid for protocols, so it is normalized to `public`.
    static func accessModifierKeyword(for level: MemberExtractor.AccessLevel) -> Keyword? {
        switch level {
        case .open, .public:
            .public
        case .package:
            .package
        case .internal:
            nil
        case .fileprivate:
            .fileprivate
        case .private:
            .private
        }
    }

    /// Build an `InheritanceClauseSyntax` from actor status and custom conformances.
    /// Returns `nil` when there are no inherited types.
    static func inheritanceClause(
        includeActorInheritance: Bool,
        conformsTo: [String]
    ) -> InheritanceClauseSyntax? {
        var typeNames: [String] = []
        if includeActorInheritance {
            typeNames.append("Actor")
        }
        for conformance in conformsTo where !typeNames.contains(conformance) {
            typeNames.append(conformance)
        }
        guard !typeNames.isEmpty else { return nil }

        let types = InheritedTypeListSyntax(
            typeNames.enumerated().map { index, name in
                InheritedTypeSyntax(
                    type: TypeSyntax(stringLiteral: name),
                    trailingComma: index < typeNames.count - 1 ? .commaToken(trailingTrivia: .space) : nil
                )
            }
        )
        return InheritanceClauseSyntax(
            colon: .colonToken(trailingTrivia: .space),
            inheritedTypes: types
        )
    }
}
