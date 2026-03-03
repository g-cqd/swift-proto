//
//  ProtoMacro.swift
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

public struct ProtoMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let typeInfo = TypeInfo(from: declaration) else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: ProtoDiagnostic.requiresNominalType
                )
            )
            return []
        }

        let config = ProtoMacroConfig.parse(from: node, in: context)
        return generateDeclarations(
            for: typeInfo,
            config: config,
            node: node,
            context: context
        )
    }

    private static func generateDeclarations(
        for typeInfo: TypeInfo,
        config: ProtoMacroConfig,
        node: AttributeSyntax,
        context: some MacroExpansionContext
    ) -> [DeclSyntax] {
        let inferredAccessLevel = MemberExtractor.accessLevel(of: typeInfo.modifiers)
        let protocolAccessLevel = config.scope ?? inferredAccessLevel
        let generationInputs = resolveGenerationInputs(
            typeInfo: typeInfo,
            from: config,
            inferredAccessLevel: inferredAccessLevel,
            node: node,
            in: context
        )
        let (includeActorInheritance, injectActorAsync) = actorGenerationFlags(for: typeInfo, config: config)
        let protocolName = "\(typeInfo.name)Protocol"
        let genericWhereClause = resolvedWhereClause(
            behavior: config.whereClauseBehavior,
            genericWhereClause: typeInfo.genericWhereClause
        )

        let protocolConformsTo = config.conformsTo + (config.mockAutoDefault ? ["Proto.Metatype"] : [])
        var declarations = [DeclSyntax]()
        let protocolDecl = makeProtocolDeclaration(
            protocolName: protocolName,
            protocolAccessLevel: protocolAccessLevel,
            members: generationInputs.members,
            typeInfo: typeInfo,
            inferredAccessLevel: inferredAccessLevel,
            includeActorInheritance: includeActorInheritance,
            injectActorAsync: injectActorAsync,
            primaryTypes: generationInputs.primaryTypes,
            typeAliases: generationInputs.typeAliases,
            genericWhereClause: genericWhereClause,
            conformsTo: protocolConformsTo,
            context: context
        )
        declarations.append(DeclSyntax(protocolDecl))

        if config.includeMock {
            appendMockDeclaration(
                to: &declarations,
                config: config,
                protocolName: protocolName,
                protocolAccessLevel: protocolAccessLevel,
                members: generationInputs.members,
                typeInfo: typeInfo,
                inferredAccessLevel: inferredAccessLevel,
                includeActorInheritance: includeActorInheritance,
                injectActorAsync: injectActorAsync,
                typeAliases: generationInputs.typeAliases,
                genericWhereClause: genericWhereClause
            )
        }

        return declarations
    }

    private static func resolveGenerationInputs(
        typeInfo: TypeInfo,
        from config: ProtoMacroConfig,
        inferredAccessLevel: MemberExtractor.AccessLevel,
        node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) -> GenerationInputs {
        let members = extractedMembers(
            from: typeInfo,
            config: config,
            inferredAccessLevel: inferredAccessLevel
        )
        let typeAliases = MemberExtractor.extractTypeAliases(
            from: typeInfo.declGroup,
            node: Syntax(node),
            context: context
        )
        let genericParamNames = typeInfo.genericParameterClause?.parameters.map(\.name.trimmedDescription) ?? []
        let primaryTypes = resolvedPrimaryTypes(
            from: config,
            genericParamNames: genericParamNames,
            node: node,
            in: context
        )
        return GenerationInputs(
            members: members,
            typeAliases: typeAliases,
            primaryTypes: primaryTypes
        )
    }

    private static func extractedMembers(
        from typeInfo: TypeInfo,
        config: ProtoMacroConfig,
        inferredAccessLevel: MemberExtractor.AccessLevel
    ) -> [ProtocolMember] {
        MemberExtractor.extract(
            from: typeInfo.declGroup,
            typeAccessLevel: inferredAccessLevel,
            includeMethods: config.includeMethods,
            includeProperties: config.includeProperties,
            includeSubscripts: config.includeSubscripts,
            includeStatic: config.includeStatic,
            includeInit: config.includeInit
        )
    }

    private static func actorGenerationFlags(
        for typeInfo: TypeInfo,
        config: ProtoMacroConfig
    ) -> (includeActorInheritance: Bool, injectActorAsync: Bool) {
        (
            typeInfo.isActor && config.isolation.actorInheritanceEnabled,
            typeInfo.isActor && config.isolation.asyncInjectionEnabled
        )
    }

    private static func makeProtocolDeclaration(
        protocolName: String,
        protocolAccessLevel: MemberExtractor.AccessLevel,
        members: [ProtocolMember],
        typeInfo: TypeInfo,
        inferredAccessLevel: MemberExtractor.AccessLevel,
        includeActorInheritance: Bool,
        injectActorAsync: Bool,
        primaryTypes: [String],
        typeAliases: [String: TypeSyntax],
        genericWhereClause: GenericWhereClauseSyntax?,
        conformsTo: [String],
        context: some MacroExpansionContext
    ) -> ProtocolDeclSyntax {
        ProtocolGenerator.generate(
            name: protocolName,
            accessLevel: protocolAccessLevel,
            members: members,
            typeAttributes: typeInfo.attributes,
            memberAccessLevel: inferredAccessLevel,
            genericParameterClause: typeInfo.genericParameterClause,
            genericWhereClause: genericWhereClause,
            isActorType: typeInfo.isActor,
            includeActorInheritance: includeActorInheritance,
            injectActorAsync: injectActorAsync,
            primaryTypes: primaryTypes,
            typeName: typeInfo.name,
            typeAliases: typeAliases,
            conformsTo: conformsTo,
            context: context
        )
    }

    private static func appendMockDeclaration(
        to declarations: inout [DeclSyntax],
        config: ProtoMacroConfig,
        protocolName: String,
        protocolAccessLevel: MemberExtractor.AccessLevel,
        members: [ProtocolMember],
        typeInfo: TypeInfo,
        inferredAccessLevel: MemberExtractor.AccessLevel,
        includeActorInheritance: Bool,
        injectActorAsync: Bool,
        typeAliases: [String: TypeSyntax],
        genericWhereClause: GenericWhereClauseSyntax?
    ) {
        let mockDecl = makeMockDeclaration(
            protocolName: protocolName,
            mockAccessLevel: config.mockScope ?? protocolAccessLevel,
            members: members,
            typeInfo: typeInfo,
            inferredAccessLevel: inferredAccessLevel,
            includeActorInheritance: includeActorInheritance,
            injectActorAsync: injectActorAsync,
            typeAliases: typeAliases,
            genericWhereClause: genericWhereClause,
            conformsTo: config.conformsTo,
            mockAutoDefault: config.mockAutoDefault
        )
        if config.mockCompilationConditions.isEmpty {
            declarations.append(mockDecl)
        } else {
            let condition = config.mockCompilationConditions.joined(separator: " || ")
            declarations.append(
                DeclSyntax(stringLiteral: "#if \(condition)\n\(mockDecl.trimmedDescription)\n#endif")
            )
        }
    }

    private static func makeMockDeclaration(
        protocolName: String,
        mockAccessLevel: MemberExtractor.AccessLevel,
        members: [ProtocolMember],
        typeInfo: TypeInfo,
        inferredAccessLevel: MemberExtractor.AccessLevel,
        includeActorInheritance: Bool,
        injectActorAsync: Bool,
        typeAliases: [String: TypeSyntax],
        genericWhereClause: GenericWhereClauseSyntax?,
        conformsTo: [String],
        mockAutoDefault: Bool
    ) -> DeclSyntax {
        let context = MockGenerator.GenerationContext(
            protocolName: protocolName,
            mockName: "\(typeInfo.name)Mock",
            visibilityKeyword: MockGenerator.visibilityKeyword(for: mockAccessLevel),
            mockIsActor: includeActorInheritance,
            requiresUncheckedSendable: !includeActorInheritance && conformsTo.contains("Sendable"),
            requiresSynchronizedState: !includeActorInheritance && conformsTo.contains("Sendable"),
            mockAutoDefault: mockAutoDefault,
            genericParameterClause: typeInfo.genericParameterClause,
            genericWhereClause: genericWhereClause,
            isActorType: typeInfo.isActor,
            injectActorAsync: injectActorAsync,
            typeName: typeInfo.name,
            typeAliases: typeAliases,
            memberAccessLevel: inferredAccessLevel,
            propagatedAttributes: ProtocolGenerator.propagatedAttributes(from: typeInfo.attributes)
        )
        return MockGenerator.generate(context: context, members: members)
    }

    private static func resolvedPrimaryTypes(
        from config: ProtoMacroConfig,
        genericParamNames: [String],
        node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) -> [String] {
        switch config.primaryBehavior {
        case .unconstrained:
            return []
        case .all:
            return genericParamNames
        case .explicit(let names):
            let genericParamNameSet = Set(genericParamNames)
            for name in names where !genericParamNameSet.contains(name) {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(node),
                        message: ProtoDiagnostic.unknownConstrainedTypeName(name)
                    )
                )
            }
            return names
        }
    }
}

private struct GenerationInputs {
    let members: [ProtocolMember]
    let typeAliases: [String: TypeSyntax]
    let primaryTypes: [String]
}

// MARK: - Where Clause Resolution

extension ProtoMacro {
    static func resolvedWhereClause(
        behavior: ProtoMacroConfig.WhereClauseBehavior,
        genericWhereClause: GenericWhereClauseSyntax?
    ) -> GenericWhereClauseSyntax? {
        guard let whereClause = genericWhereClause else { return nil }
        switch behavior {
        case .omit:
            return nil
        case .keepAll:
            return whereClause
        case .keepFor(let names):
            let filtered = whereClause.requirements.filter { requirement in
                baseTypeName(of: requirement).map { names.contains($0) } ?? false
            }
            guard !filtered.isEmpty else { return nil }
            let newRequirements = GenericRequirementListSyntax(
                filtered.enumerated().map { index, req in
                    var requirement = req
                    if index < filtered.count - 1 {
                        requirement = requirement.with(\.trailingComma, TokenSyntax.commaToken(trailingTrivia: .space))
                    } else {
                        requirement = requirement.with(\.trailingComma, nil)
                    }
                    return requirement
                }
            )
            return whereClause.with(\.requirements, newRequirements)
        }
    }

    /// Extract the base type name from a generic requirement's left-hand side.
    private static func baseTypeName(of requirement: GenericRequirementSyntax) -> String? {
        switch requirement.requirement {
        case .conformanceRequirement(let conformance):
            return rootTypeName(of: conformance.leftType)
        case .sameTypeRequirement(let sameType):
            if case .type(let leftType) = sameType.leftType {
                return rootTypeName(of: leftType)
            }
            return nil
        case .layoutRequirement(let layout):
            return rootTypeName(of: layout.type)
        }
    }

    /// Walk a type to find its root identifier name.
    private static func rootTypeName(of type: TypeSyntax) -> String? {
        if let identifierType = type.as(IdentifierTypeSyntax.self) {
            return identifierType.name.trimmedDescription
        }
        if let memberType = type.as(MemberTypeSyntax.self) {
            return rootTypeName(of: TypeSyntax(memberType.baseType))
        }
        return nil
    }
}
