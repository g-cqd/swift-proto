//
//  MockGenerator.swift
//  Proto
//
//  Created by Guillaume Coquard on 18.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftSyntax

/// Builds an opt-in companion `<TypeName>Mock` declaration.
enum MockGenerator {
    struct GenerationContext {
        let protocolName: String
        let mockName: String
        let visibilityKeyword: String?
        let mockIsActor: Bool
        let requiresUncheckedSendable: Bool
        let requiresSynchronizedState: Bool
        let mockAutoDefault: Bool
        let mockPropertySetters: Bool
        let genericParameterClause: GenericParameterClauseSyntax?
        let genericWhereClause: GenericWhereClauseSyntax?
        let isActorType: Bool
        let injectActorAsync: Bool
        let typeName: String
        let typeAliases: [String: TypeSyntax]
        let memberAccessLevel: MemberExtractor.AccessLevel
        let propagatedAttributes: AttributeListSyntax
    }

    struct InitParameter {
        let helperName: String
        let handlerType: String
        let returnType: String?
        let errorType: String?
    }

    struct GenerationState {
        var functionNameCounts: [String: Int] = [:]
        var helperDecls: [DeclSyntax] = []
        var memberImplDecls: [DeclSyntax] = []
        var needsReturnStub = false
        var initParameters: [InitParameter] = []
        var needsInstanceSynchronization = false
        var needsStaticSynchronization = false
    }

    static func generate(
        context: GenerationContext,
        members: [ProtocolMember]
    ) -> DeclSyntax {
        var state = GenerationState()
        for member in members {
            process(member: member, in: context, state: &state)
        }

        return renderMockDeclaration(from: context, state: state)
    }

    static func process(
        member: ProtocolMember,
        in context: GenerationContext,
        state: inout GenerationState
    ) {
        switch member {
        case .function(let functionDecl):
            processFunction(functionDecl, in: context, state: &state)
        case .variable(let variableDecl):
            processVariable(variableDecl, in: context, state: &state)
        case .initializer(let initializerDecl):
            processInitializer(initializerDecl, in: context, state: &state)
        case .subscript(let subscriptDecl):
            processSubscript(subscriptDecl, in: context, state: &state)
        }
    }

    static func processFunction(
        _ functionDecl: FunctionDeclSyntax,
        in context: GenerationContext,
        state: inout GenerationState
    ) {
        let ignored = MemberExtractor.hasProtoMockIgnored(functionDecl.attributes)
        // context: nil — diagnostics were already emitted during protocol generation
        let transformed = ProtocolGenerator.rewriteTypes(
            in: ProtocolGenerator.protocolFunction(
                from: functionDecl,
                isActorType: context.isActorType,
                injectActorAsync: context.injectActorAsync,
                context: nil
            ),
            typeName: context.typeName,
            typeAliases: context.typeAliases
        )

        let helperName = nextHelperName(
            for: transformed.name.trimmedDescription,
            counts: &state.functionNameCounts
        )
        let rendered = renderFunctionMember(
            transformed,
            helperName: helperName,
            mockName: context.mockName,
            visibilityKeyword: context.visibilityKeyword,
            mockIsActor: context.mockIsActor,
            requiresSynchronizedState: context.requiresSynchronizedState,
            mockAutoDefault: context.mockAutoDefault,
            ignored: ignored
        )

        state.helperDecls += rendered.helperDecls
        state.memberImplDecls.append(rendered.memberImpl)
        state.needsReturnStub = state.needsReturnStub || rendered.needsReturnStub
        state.needsInstanceSynchronization =
            state.needsInstanceSynchronization
            || rendered.usesInstanceSynchronization
        state.needsStaticSynchronization =
            state.needsStaticSynchronization
            || rendered.usesStaticSynchronization
        if let initParameter = rendered.initParameter {
            state.initParameters.append(initParameter)
        }
    }

    static func processVariable(
        _ variableDecl: VariableDeclSyntax,
        in context: GenerationContext,
        state: inout GenerationState
    ) {
        let ignored = MemberExtractor.hasProtoMockIgnored(variableDecl.attributes)
        // context: nil — diagnostics were already emitted during protocol generation
        let protocolVariables = ProtocolGenerator.protocolVariables(
            from: variableDecl,
            isActorType: context.isActorType,
            injectActorAsync: context.injectActorAsync,
            typeAccessLevel: context.memberAccessLevel,
            context: nil
        )
        let transformedVariables = protocolVariables.map {
            ProtocolGenerator.rewriteTypes(
                in: $0,
                typeName: context.typeName,
                typeAliases: context.typeAliases
            )
        }

        let effectivePropertySetters = ignored ? false : context.mockPropertySetters
        for transformed in transformedVariables {
            let propertyStubs = renderPropertyStub(
                transformed,
                mockName: context.mockName,
                visibilityKeyword: context.visibilityKeyword,
                mockIsActor: context.mockIsActor,
                mockAutoDefault: context.mockAutoDefault,
                mockPropertySetters: effectivePropertySetters
            )
            state.memberImplDecls.append(contentsOf: propertyStubs)
        }
    }

    static func processInitializer(
        _ initializerDecl: InitializerDeclSyntax,
        in context: GenerationContext,
        state: inout GenerationState
    ) {
        // context: nil — diagnostics were already emitted during protocol generation
        let transformed = ProtocolGenerator.rewriteTypes(
            in: ProtocolGenerator.protocolInitializer(from: initializerDecl, context: nil),
            typeName: context.typeName,
            typeAliases: context.typeAliases
        )
        state.memberImplDecls.append(
            renderInitializerStub(
                transformed,
                mockName: context.mockName,
                visibilityKeyword: context.visibilityKeyword,
                mockIsActor: context.mockIsActor,
                mockAutoDefault: context.mockAutoDefault
            )
        )
    }

    static func processSubscript(
        _ subscriptDecl: SubscriptDeclSyntax,
        in context: GenerationContext,
        state: inout GenerationState
    ) {
        // context: nil — diagnostics were already emitted during protocol generation
        let transformed = ProtocolGenerator.rewriteTypes(
            in: ProtocolGenerator.protocolSubscript(
                from: subscriptDecl,
                isActorType: context.isActorType,
                injectActorAsync: context.injectActorAsync,
                typeAccessLevel: context.memberAccessLevel,
                context: nil
            ),
            typeName: context.typeName,
            typeAliases: context.typeAliases
        )
        state.memberImplDecls.append(
            renderSubscriptStub(
                transformed,
                mockName: context.mockName,
                visibilityKeyword: context.visibilityKeyword,
                mockIsActor: context.mockIsActor,
                mockAutoDefault: context.mockAutoDefault
            )
        )
    }

    static func nextHelperName(for memberName: String, counts: inout [String: Int]) -> String {
        let baseHelperName = sanitizeHelperIdentifier(memberName)
        let nextCount = (counts[baseHelperName] ?? 0) + 1
        counts[baseHelperName] = nextCount
        return nextCount == 1 ? baseHelperName : "\(baseHelperName)\(nextCount)"
    }
}
