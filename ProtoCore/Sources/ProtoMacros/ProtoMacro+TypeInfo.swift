//
//  ProtoMacro+TypeInfo.swift
//  Proto
//
//  Created by Guillaume Coquard on 19.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftSyntax

struct TypeInfo {
    let declGroup: any DeclGroupSyntax
    let name: String
    let modifiers: DeclModifierListSyntax
    let attributes: AttributeListSyntax
    let genericParameterClause: GenericParameterClauseSyntax?
    let genericWhereClause: GenericWhereClauseSyntax?
    let isActor: Bool

    init?(from declaration: some DeclSyntaxProtocol) {
        if let d = declaration.as(ClassDeclSyntax.self) {
            self.init(
                declGroup: d,
                name: d.name.trimmedDescription,
                modifiers: d.modifiers,
                attributes: d.attributes,
                genericParameterClause: d.genericParameterClause,
                genericWhereClause: d.genericWhereClause,
                isActor: false
            )
        } else if let d = declaration.as(StructDeclSyntax.self) {
            self.init(
                declGroup: d,
                name: d.name.trimmedDescription,
                modifiers: d.modifiers,
                attributes: d.attributes,
                genericParameterClause: d.genericParameterClause,
                genericWhereClause: d.genericWhereClause,
                isActor: false
            )
        } else if let d = declaration.as(EnumDeclSyntax.self) {
            self.init(
                declGroup: d,
                name: d.name.trimmedDescription,
                modifiers: d.modifiers,
                attributes: d.attributes,
                genericParameterClause: d.genericParameterClause,
                genericWhereClause: d.genericWhereClause,
                isActor: false
            )
        } else if let d = declaration.as(ActorDeclSyntax.self) {
            self.init(
                declGroup: d,
                name: d.name.trimmedDescription,
                modifiers: d.modifiers,
                attributes: d.attributes,
                genericParameterClause: d.genericParameterClause,
                genericWhereClause: d.genericWhereClause,
                isActor: true
            )
        } else {
            return nil
        }
    }

    private init(
        declGroup: some DeclGroupSyntax,
        name: String,
        modifiers: DeclModifierListSyntax,
        attributes: AttributeListSyntax,
        genericParameterClause: GenericParameterClauseSyntax?,
        genericWhereClause: GenericWhereClauseSyntax?,
        isActor: Bool
    ) {
        self.declGroup = declGroup
        self.name = name
        self.modifiers = modifiers
        self.attributes = attributes
        self.genericParameterClause = genericParameterClause
        self.genericWhereClause = genericWhereClause
        self.isActor = isActor
    }
}
