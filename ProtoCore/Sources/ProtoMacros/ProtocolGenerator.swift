//
//  ProtocolGenerator.swift
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

/// Builds the `ProtocolDeclSyntax` from extracted members.
enum ProtocolGenerator {
    /// Keywords and modifiers to strip from protocol requirements.
    static let strippedModifiers: Set<String> = [
        "final", "override", "class",
        "private", "fileprivate", "internal", "package", "public", "open",
        "weak", "unowned", "lazy",
    ]

    /// Attributes to strip from protocol requirements.
    static let strippedAttributes: Set<String> = [
        "Proto", "ProtoExclude", "ProtoMember", "ProtoMockIgnored",
        // Property wrappers (invalid on protocol requirements)
        "State", "Binding", "Published", "ObservedObject", "StateObject",
        "EnvironmentObject", "Environment", "AppStorage", "SceneStorage",
        "FocusState", "GestureState", "Namespace", "ScaledMetric",
        "ObservationIgnored", "ObservationTracked",
    ]

    /// Type-level attributes that propagate to the generated protocol declaration.
    static let propagatedAttributeNames: Set<String> = [
        "MainActor", "preconcurrency", "available",
    ]

    /// Generate the full protocol declaration.
    static func generate(
        name: String,
        accessLevel: MemberExtractor.AccessLevel,
        members: [ProtocolMember],
        typeAttributes: AttributeListSyntax,
        memberAccessLevel: MemberExtractor.AccessLevel? = nil,
        genericParameterClause: GenericParameterClauseSyntax? = nil,
        genericWhereClause: GenericWhereClauseSyntax? = nil,
        isActorType: Bool = false,
        includeActorInheritance: Bool = false,
        injectActorAsync: Bool = false,
        primaryTypes: [String] = [],
        typeName: String = "",
        typeAliases: [String: TypeSyntax] = [:],
        conformsTo: [String] = [],
        context: (any MacroExpansionContext)? = nil
    ) -> ProtocolDeclSyntax {
        let effectiveMemberAccessLevel = memberAccessLevel ?? accessLevel
        let memberDecls = transformMembers(
            members,
            isActorType: isActorType,
            injectActorAsync: injectActorAsync,
            typeAccessLevel: effectiveMemberAccessLevel,
            typeName: typeName,
            typeAliases: typeAliases,
            genericParameterClause: genericParameterClause,
            context: context
        )

        let memberBlock = MemberBlockSyntax(
            leftBrace: .leftBraceToken(leadingTrivia: .space),
            members: MemberBlockItemListSyntax(memberDecls),
            rightBrace: .rightBraceToken(leadingTrivia: .newline)
        )

        let propagatedAttrs = propagatedAttributes(from: typeAttributes)
        var modifiers: DeclModifierListSyntax = []
        if let keyword = accessModifierKeyword(for: accessLevel) {
            modifiers = [
                DeclModifierSyntax(name: .keyword(keyword), trailingTrivia: .space)
            ]
        }

        var whereClause = genericWhereClause
        if var clause = whereClause {
            clause.trailingTrivia = []
            whereClause = clause
        }

        var protocolDecl = ProtocolDeclSyntax(
            attributes: propagatedAttrs,
            modifiers: modifiers,
            name: .identifier(name),
            primaryAssociatedTypeClause: primaryAssociatedTypeClause(from: primaryTypes),
            inheritanceClause: inheritanceClause(
                includeActorInheritance: includeActorInheritance,
                conformsTo: conformsTo
            ),
            genericWhereClause: whereClause,
            memberBlock: memberBlock
        )
        protocolDecl.protocolKeyword.trailingTrivia = .space

        return protocolDecl
    }

    private static func transformMembers(
        _ members: [ProtocolMember],
        isActorType: Bool,
        injectActorAsync: Bool,
        typeAccessLevel: MemberExtractor.AccessLevel,
        typeName: String,
        typeAliases: [String: TypeSyntax],
        genericParameterClause: GenericParameterClauseSyntax?,
        context: (any MacroExpansionContext)?
    ) -> [MemberBlockItemSyntax] {
        var decls = associatedtypeDecls(from: genericParameterClause)
        for member in members {
            switch member {
            case .function(let funcDecl):
                let transformed = protocolFunction(
                    from: funcDecl,
                    isActorType: isActorType,
                    injectActorAsync: injectActorAsync,
                    context: context
                )
                let rewritten = rewriteTypes(in: transformed, typeName: typeName, typeAliases: typeAliases)
                decls.append(MemberBlockItemSyntax(decl: rewritten))
            case .variable(let varDecl):
                for req in protocolVariables(
                    from: varDecl,
                    isActorType: isActorType,
                    injectActorAsync: injectActorAsync,
                    typeAccessLevel: typeAccessLevel,
                    context: context
                ) {
                    let rewritten = rewriteTypes(in: req, typeName: typeName, typeAliases: typeAliases)
                    decls.append(MemberBlockItemSyntax(decl: rewritten))
                }
            case .initializer(let initDecl):
                let transformed = protocolInitializer(from: initDecl, context: context)
                let rewritten = rewriteTypes(in: transformed, typeName: typeName, typeAliases: typeAliases)
                decls.append(MemberBlockItemSyntax(decl: rewritten))
            case .subscript(let subDecl):
                let transformed = protocolSubscript(
                    from: subDecl,
                    isActorType: isActorType,
                    injectActorAsync: injectActorAsync,
                    typeAccessLevel: typeAccessLevel,
                    context: context
                )
                let rewritten = rewriteTypes(in: transformed, typeName: typeName, typeAliases: typeAliases)
                decls.append(MemberBlockItemSyntax(decl: rewritten))
            }
        }
        return decls
    }
}
