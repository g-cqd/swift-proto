//
//  MockGenerator+DeclarationRendering.swift
//  Proto
//
//  Created by Guillaume Coquard on 19.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftSyntax

extension MockGenerator {
    static func renderMockDeclaration(
        from context: GenerationContext,
        state: GenerationState
    ) -> DeclSyntax {
        let memberItems = buildMemberItems(
            from: state,
            visibilityKeyword: context.visibilityKeyword,
            requiresSynchronizedState: context.requiresSynchronizedState,
            mockAutoDefault: context.mockAutoDefault
        )
        let memberBlock = MemberBlockSyntax(
            leftBrace: .leftBraceToken(leadingTrivia: .space),
            members: MemberBlockItemListSyntax(memberItems),
            rightBrace: .rightBraceToken(leadingTrivia: .newline)
        )
        let whereClause = normalizedGenericWhereClause(context.genericWhereClause)

        if context.mockIsActor {
            return actorMockDeclaration(
                context: context,
                memberBlock: memberBlock,
                whereClause: whereClause
            )
        }
        return classMockDeclaration(
            context: context,
            memberBlock: memberBlock,
            whereClause: whereClause
        )
    }

    static func renderConvenienceInit(
        parameters: [InitParameter],
        visibilityKeyword: String?,
        requiresSynchronizedState: Bool,
        mockAutoDefault: Bool = false
    ) -> DeclSyntax? {
        guard !parameters.isEmpty else { return nil }

        let accessPrefix = visibilityKeyword.map { "\($0) " } ?? ""
        var lines = [String]()

        var paramDecls = [String]()
        for param in parameters {
            paramDecls.append("\(param.helperName)Handler: (\(param.handlerType))? = nil")
            if let errorType = param.errorType {
                paramDecls.append("\(param.helperName)Error: (\(errorType))? = nil")
            }
            if let returnType = param.returnType {
                if mockAutoDefault, let defaultExpr = autoDefaultExpression(for: returnType) {
                    paramDecls.append("\(param.helperName)ReturnValue: \(returnType)? = \(defaultExpr)")
                } else {
                    paramDecls.append("\(param.helperName)ReturnValue: \(returnType)? = nil")
                }
            }
        }

        lines.append("\(accessPrefix)init(")
        for (index, paramDecl) in paramDecls.enumerated() {
            let separator = index < paramDecls.count - 1 ? "," : ""
            lines.append("        \(paramDecl)\(separator)")
        }
        lines.append(") {")

        for param in parameters {
            lines.append("        self.\(param.helperName)Handler = \(param.helperName)Handler")
            if param.errorType != nil {
                lines.append("        self.\(param.helperName)Error = \(param.helperName)Error")
            }
            if param.returnType != nil {
                let returnStorage =
                    requiresSynchronizedState
                    ? "_\(param.helperName)ReturnStub"
                    : "\(param.helperName)ReturnStub"
                lines.append("        if let \(param.helperName)ReturnValue {")
                if requiresSynchronizedState {
                    lines.append("            _protoMockLock.withLock {")
                    lines.append("                \(returnStorage) = .value(\(param.helperName)ReturnValue)")
                    lines.append("            }")
                } else {
                    lines.append("            \(returnStorage) = .value(\(param.helperName)ReturnValue)")
                }
                lines.append("        }")
            }
        }

        lines.append("}")
        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }

    private static func memberBlockItem(
        from decl: DeclSyntax,
        separatedByBlankLine: Bool
    ) -> MemberBlockItemSyntax {
        var normalizedDecl = decl
        normalizedDecl.leadingTrivia = []
        normalizedDecl.trailingTrivia = []

        var item = MemberBlockItemSyntax(decl: normalizedDecl)
        item.leadingTrivia =
            separatedByBlankLine
            ? .newline + .newline + .spaces(4)
            : .newline + .spaces(4)
        return item
    }

    private static func buildMemberItems(
        from state: GenerationState,
        visibilityKeyword: String?,
        requiresSynchronizedState: Bool,
        mockAutoDefault: Bool = false
    ) -> [MemberBlockItemSyntax] {
        var memberItems = [MemberBlockItemSyntax]()
        if state.needsReturnStub {
            memberItems.append(memberBlockItem(from: returnStubDeclaration(), separatedByBlankLine: false))
        }
        if requiresSynchronizedState,
            let synchronizationDecl = synchronizationSupportDeclaration(
                includeInstanceLock: state.needsInstanceSynchronization,
                includeStaticLock: state.needsStaticSynchronization
            )
        {
            memberItems.append(
                memberBlockItem(
                    from: synchronizationDecl,
                    separatedByBlankLine: !memberItems.isEmpty
                )
            )
        }
        appendMemberDecls(state.helperDecls, to: &memberItems)

        if let convenienceInit = renderConvenienceInit(
            parameters: state.initParameters,
            visibilityKeyword: visibilityKeyword,
            requiresSynchronizedState: requiresSynchronizedState,
            mockAutoDefault: mockAutoDefault
        ) {
            memberItems.append(
                memberBlockItem(
                    from: convenienceInit,
                    separatedByBlankLine: !memberItems.isEmpty
                )
            )
        }

        appendMemberDecls(state.memberImplDecls, to: &memberItems)
        return memberItems
    }

    private static func appendMemberDecls(
        _ declarations: [DeclSyntax],
        to memberItems: inout [MemberBlockItemSyntax]
    ) {
        guard !declarations.isEmpty else { return }
        for (index, declaration) in declarations.enumerated() {
            memberItems.append(
                memberBlockItem(
                    from: declaration,
                    separatedByBlankLine: memberItems.isEmpty ? false : index == 0
                )
            )
        }
    }

    private static func returnStubDeclaration() -> DeclSyntax {
        DeclSyntax(
            stringLiteral: """
                private enum ProtoMockReturnStub<Value> {
                        case unset
                        case value(Value)
                }
                """
        )
    }

    private static func synchronizationSupportDeclaration(
        includeInstanceLock: Bool,
        includeStaticLock: Bool
    ) -> DeclSyntax? {
        guard includeInstanceLock || includeStaticLock else { return nil }

        var lines = [String]()
        if includeInstanceLock {
            lines.append("private let _protoMockLock = ProtoMockSynchronizationLock()")
        }
        if includeStaticLock {
            lines.append("private static let _protoMockStaticLock = ProtoMockSynchronizationLock()")
        }

        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }

    private static func normalizedGenericWhereClause(
        _ genericWhereClause: GenericWhereClauseSyntax?
    ) -> GenericWhereClauseSyntax? {
        var whereClause = genericWhereClause
        if var clause = whereClause {
            clause.trailingTrivia = []
            whereClause = clause
        }
        return whereClause
    }

    private static func actorMockDeclaration(
        context: GenerationContext,
        memberBlock: MemberBlockSyntax,
        whereClause: GenericWhereClauseSyntax?
    ) -> DeclSyntax {
        var actorDecl = ActorDeclSyntax(
            attributes: context.propagatedAttributes,
            modifiers: typeModifiers(
                visibilityKeyword: context.visibilityKeyword,
                includeFinal: false
            ),
            name: .identifier(context.mockName),
            genericParameterClause: context.genericParameterClause,
            inheritanceClause: mockInheritanceClause(from: context),
            genericWhereClause: whereClause,
            memberBlock: memberBlock
        )
        actorDecl.actorKeyword.trailingTrivia = .space
        actorDecl.leadingTrivia = []
        actorDecl.trailingTrivia = []
        return DeclSyntax(actorDecl)
    }

    private static func classMockDeclaration(
        context: GenerationContext,
        memberBlock: MemberBlockSyntax,
        whereClause: GenericWhereClauseSyntax?
    ) -> DeclSyntax {
        var classDecl = ClassDeclSyntax(
            attributes: context.propagatedAttributes,
            modifiers: typeModifiers(
                visibilityKeyword: context.visibilityKeyword,
                includeFinal: true
            ),
            name: .identifier(context.mockName),
            genericParameterClause: context.genericParameterClause,
            inheritanceClause: mockInheritanceClause(from: context),
            genericWhereClause: whereClause,
            memberBlock: memberBlock
        )
        classDecl.classKeyword.trailingTrivia = .space
        classDecl.leadingTrivia = []
        classDecl.trailingTrivia = []
        return DeclSyntax(classDecl)
    }

    private static func typeModifiers(
        visibilityKeyword: String?,
        includeFinal: Bool
    ) -> DeclModifierListSyntax {
        var modifiers = [DeclModifierSyntax]()
        if let visibilityKeyword {
            modifiers.append(
                DeclModifierSyntax(
                    name: modifierToken(for: visibilityKeyword),
                    trailingTrivia: .space
                )
            )
        }
        if includeFinal {
            modifiers.append(DeclModifierSyntax(name: .keyword(.final), trailingTrivia: .space))
        }
        return DeclModifierListSyntax(modifiers)
    }

    private static func mockInheritanceClause(from context: GenerationContext) -> InheritanceClauseSyntax {
        var inheritedTypes = [InheritedTypeSyntax]()
        if context.requiresUncheckedSendable {
            inheritedTypes.append(
                InheritedTypeSyntax(
                    type: TypeSyntax(stringLiteral: "@unchecked Sendable"),
                    trailingComma: .commaToken(trailingTrivia: .space)
                )
            )
        }
        inheritedTypes.append(InheritedTypeSyntax(type: TypeSyntax(stringLiteral: context.protocolName)))
        return InheritanceClauseSyntax(
            colon: .colonToken(trailingTrivia: .space),
            inheritedTypes: InheritedTypeListSyntax(inheritedTypes)
        )
    }
}
