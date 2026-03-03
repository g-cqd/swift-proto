//
//  ProtocolGenerator+Transforms.swift
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

// MARK: - Shared Transform Context

extension ProtocolGenerator {
    /// Encapsulates the shared isolation, async/throws, and diagnostic logic
    /// used by `protocolFunction`, `protocolVariables`, and `protocolSubscript`.
    struct MemberTransformContext {
        let memberConfig: ProtoMemberConfig
        let isActorType: Bool
        let isStatic: Bool
        let forceNonisolated: Bool
        let forceIsolated: Bool
        let needsAsync: Bool
        let needsThrows: Bool
        /// The modifiers after stripping access control and applying isolation.
        let filteredModifiers: DeclModifierListSyntax
        /// The attributes after stripping Proto-specific attributes.
        let filteredAttributes: AttributeListSyntax

        /// Initializes the transform context and emits inapplicable-option diagnostics.
        ///
        /// - Parameters:
        ///   - attributes: The member's attribute list (used to parse `@ProtoMember`).
        ///   - modifiers: The member's modifier list (used to detect `static`).
        ///   - isActorType: Whether the enclosing type is an actor.
        ///   - injectActorAsync: Whether actor-async injection is enabled.
        ///   - node: The syntax node used for diagnostics.
        ///   - context: The macro expansion context (used for diagnostics and config parsing).
        ///   - isAlreadyAsync: Whether the member already has an `async` specifier.
        ///   - isAlreadyThrows: Whether the member already has a `throws` clause.
        init(
            attributes: AttributeListSyntax,
            modifiers: DeclModifierListSyntax,
            isActorType: Bool,
            injectActorAsync: Bool,
            node: Syntax,
            context: (any MacroExpansionContext)?,
            isAlreadyAsync: Bool = false,
            isAlreadyThrows: Bool = false
        ) {
            self.memberConfig = context.map { ProtoMemberConfig.parse(from: attributes, in: $0) } ?? .default
            self.isActorType = isActorType
            self.isStatic = MemberExtractor.isStatic(modifiers)

            // Conflict resolution: when both flags in a pair are present, a diagnostic
            // error is emitted and neither flag takes effect (mutual cancellation).
            //   mutable + immutable → neither applied
            //   async + sync → sync wins (forceSync checked first)
            //   isolated + nonisolated → neither applied
            let requestedForceNonisolated = memberConfig.forceNonisolated && !memberConfig.forceIsolated
            let requestedForceIsolated = memberConfig.forceIsolated && !memberConfig.forceNonisolated
            self.forceNonisolated = requestedForceNonisolated && isActorType
            self.forceIsolated = requestedForceIsolated && isActorType

            // Compute filtered modifiers/attributes with isolation applied
            self.filteredModifiers = ProtocolGenerator.applyIsolationModifiers(
                to: ProtocolGenerator.filterModifiers(modifiers),
                forceNonisolated: forceNonisolated,
                forceIsolated: forceIsolated
            )
            self.filteredAttributes = ProtocolGenerator.filterAttributes(attributes)

            // Compute async/throws needs based on post-filter nonisolated status.
            //
            // Truth table for `needsAsync`:
            //   forceSync  forceAsync  injectActorAsync  nonisolated  static  alreadyAsync  → needsAsync
            //   true       *           *                 *            *       *             → false
            //   false      true        *                 *            *       false         → true
            //   false      true        *                 *            *       true          → false
            //   false      false       true              false        false   false         → true
            //   false      false       true              true         *       *             → false
            //   false      false       true              *            true    *             → false
            //   false      false       false             *            *       *             → false
            let isNonisolated = ProtocolGenerator.hasModifier(filteredModifiers, named: "nonisolated")
            let computedNeedsAsync: Bool =
                if memberConfig.forceSync {
                    false
                } else if memberConfig.forceAsync {
                    !isAlreadyAsync
                } else {
                    injectActorAsync && !isNonisolated && !self.isStatic && !isAlreadyAsync
                }
            self.needsAsync = computedNeedsAsync
            self.needsThrows = memberConfig.forceThrows && !isAlreadyThrows

            // Emit diagnostics for inapplicable isolation options
            if let context {
                if requestedForceNonisolated, !isActorType {
                    context.diagnose(
                        Diagnostic(
                            node: node,
                            message: ProtoMemberDiagnostic.nonisolatedOnNonActorMember
                        )
                    )
                }
                if requestedForceIsolated, !isActorType {
                    context.diagnose(
                        Diagnostic(
                            node: node,
                            message: ProtoMemberDiagnostic.isolatedOnNonActorMember
                        )
                    )
                }
                if requestedForceIsolated, self.isStatic {
                    context.diagnose(
                        Diagnostic(
                            node: node,
                            message: ProtoMemberDiagnostic.isolatedOnStaticMember
                        )
                    )
                }
            }
        }
    }
}

// MARK: - Transform Helpers

extension ProtocolGenerator {
    /// Apply async/throws effect specifiers to a function signature if needed.
    static func applyEffectSpecifiers(
        to signature: inout FunctionSignatureSyntax,
        needsAsync: Bool,
        needsThrows: Bool
    ) {
        guard needsAsync || needsThrows else { return }
        var specifiers = signature.effectSpecifiers ?? FunctionEffectSpecifiersSyntax()
        if needsAsync {
            specifiers.asyncSpecifier = .keyword(.async, trailingTrivia: .space)
        }
        if needsThrows {
            specifiers.throwsClause = ThrowsClauseSyntax(
                throwsSpecifier: .keyword(.throws, trailingTrivia: .space)
            )
        }
        signature.effectSpecifiers = specifiers
    }

    /// Determine whether a variable/subscript has a setter, respecting config and access levels.
    static func resolveHasSetter(
        config: ProtoMemberConfig,
        accessorBlock: AccessorBlockSyntax?,
        modifiers: DeclModifierListSyntax,
        typeAccessLevel: MemberExtractor.AccessLevel,
        needsEffectfulGetter: Bool,
        node: Syntax,
        context: (any MacroExpansionContext)?,
        isLet: Bool = false
    ) -> Bool {
        var base: Bool =
            if config.mutable {
                true
            } else if config.immutable {
                false
            } else if isLet {
                false
            } else if let accessorBlock {
                accessorBlockHasSetter(accessorBlock)
            } else {
                !isLet
            }

        let threshold = MemberExtractor.minimumAccessLevel(for: typeAccessLevel)
        if base, let setterAccess = MemberExtractor.setterAccessLevel(of: modifiers),
            setterAccess < threshold
        {
            base = false
        }

        if config.mutable, needsEffectfulGetter, let context {
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: ProtoMemberDiagnostic.mutableEffectfulGetterConflict
                )
            )
        }

        return needsEffectfulGetter ? false : base
    }
}

// MARK: - Member Transformations

extension ProtocolGenerator {
    /// Transform a function declaration into a protocol requirement (no body).
    static func protocolFunction(
        from funcDecl: FunctionDeclSyntax,
        isActorType: Bool = false,
        injectActorAsync: Bool = false,
        context: (any MacroExpansionContext)? = nil
    ) -> FunctionDeclSyntax {
        let isAlreadyAsync = funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil
        let isAlreadyThrows = funcDecl.signature.effectSpecifiers?.throwsClause != nil

        let ctx = MemberTransformContext(
            attributes: funcDecl.attributes,
            modifiers: funcDecl.modifiers,
            isActorType: isActorType,
            injectActorAsync: injectActorAsync,
            node: Syntax(funcDecl),
            context: context,
            isAlreadyAsync: isAlreadyAsync,
            isAlreadyThrows: isAlreadyThrows
        )

        // Emit function-specific diagnostics
        if let context {
            if ctx.memberConfig.immutable {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(funcDecl),
                        message: ProtoMemberDiagnostic.immutableOnFunction
                    )
                )
            }
            if ctx.memberConfig.mutable {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(funcDecl),
                        message: ProtoMemberDiagnostic.mutableOnFunction
                    )
                )
            }
        }

        var result = funcDecl.trimmed
        result.body = nil
        result.modifiers = ctx.filteredModifiers
        result.attributes = ctx.filteredAttributes
        result.signature = filterDefaultValues(signature: funcDecl.signature)
        applyEffectSpecifiers(to: &result.signature, needsAsync: ctx.needsAsync, needsThrows: ctx.needsThrows)

        if ctx.memberConfig.forceMutating,
            !hasModifier(result.modifiers, named: "mutating")
        {
            var modifiers = Array(result.modifiers)
            modifiers.insert(DeclModifierSyntax(name: .keyword(.mutating), trailingTrivia: .space), at: 0)
            result.modifiers = DeclModifierListSyntax(modifiers)
        }

        result.leadingTrivia = .newline + .spaces(4)
        result.trailingTrivia = []
        return result
    }

    /// Transform a variable declaration into protocol property requirements.
    /// Handles multi-binding declarations (e.g. `var a: Int, b: String`)
    /// by emitting one requirement per binding.
    static func protocolVariables(
        from varDecl: VariableDeclSyntax,
        isActorType: Bool = false,
        injectActorAsync: Bool = false,
        typeAccessLevel: MemberExtractor.AccessLevel = .internal,
        context: (any MacroExpansionContext)? = nil
    ) -> [VariableDeclSyntax] {
        let isLet = varDecl.bindingSpecifier.tokenKind == .keyword(.let)

        let ctx = MemberTransformContext(
            attributes: varDecl.attributes,
            modifiers: varDecl.modifiers,
            isActorType: isActorType,
            injectActorAsync: injectActorAsync,
            node: Syntax(varDecl),
            context: context
        )

        // Emit property-specific diagnostics
        if let context, ctx.memberConfig.forceMutating {
            context.diagnose(
                Diagnostic(
                    node: Syntax(varDecl),
                    message: ProtoMemberDiagnostic.mutatingOnPropertyOrSubscript
                )
            )
        }

        let baseNeedsAsync = ctx.needsAsync
        let baseNeedsThrows = ctx.memberConfig.forceThrows

        return varDecl.bindings.compactMap { binding in
            // Merge existing getter effects with @ProtoMember flags
            let existingEffects = existingGetterEffects(binding.accessorBlock)
            let needsAsync = baseNeedsAsync || existingEffects.isAsync
            let needsThrows = baseNeedsThrows || existingEffects.isThrows
            let needsEffectfulGetter = needsAsync || needsThrows
            return transformBinding(
                binding,
                from: varDecl,
                config: ctx.memberConfig,
                typeAccessLevel: typeAccessLevel,
                needsEffectfulGetter: needsEffectfulGetter,
                needsAsync: needsAsync,
                needsThrows: needsThrows,
                isLet: isLet,
                filteredModifiers: ctx.filteredModifiers,
                filteredAttributes: ctx.filteredAttributes,
                context: context
            )
        }
    }

    /// Transform a single pattern binding into a protocol property requirement.
    ///
    /// Handles type inference, accessor block generation (get/set with effects),
    /// and setter access-level filtering. Returns `nil` when the property's type
    /// cannot be inferred, emitting a diagnostic.
    private static func transformBinding(
        _ binding: PatternBindingSyntax,
        from varDecl: VariableDeclSyntax,
        config: ProtoMemberConfig,
        typeAccessLevel: MemberExtractor.AccessLevel,
        needsEffectfulGetter: Bool,
        needsAsync: Bool,
        needsThrows: Bool,
        isLet: Bool,
        filteredModifiers: DeclModifierListSyntax,
        filteredAttributes: AttributeListSyntax,
        context: (any MacroExpansionContext)?
    ) -> VariableDeclSyntax? {
        let hasSetter = resolveHasSetter(
            config: config,
            accessorBlock: binding.accessorBlock,
            modifiers: varDecl.modifiers,
            typeAccessLevel: typeAccessLevel,
            needsEffectfulGetter: needsEffectfulGetter,
            node: Syntax(varDecl),
            context: context,
            isLet: isLet
        )

        let accessorBlock = compactAccessorBlock(
            hasSetter: hasSetter,
            needsAsync: needsAsync,
            needsThrows: needsThrows
        )

        var transformed = binding
        if transformed.typeAnnotation == nil, let initializer = transformed.initializer {
            if let inferred = Self.inferType(from: initializer) {
                transformed.pattern = transformed.pattern.with(\.trailingTrivia, [])
                transformed.typeAnnotation = inferred
            } else {
                context?.diagnose(
                    Diagnostic(
                        node: Syntax(varDecl),
                        message: ProtoMemberDiagnostic.uninferablePropertyType
                    )
                )
                return nil
            }
        }

        if let typeAnnotation = transformed.typeAnnotation {
            transformed.typeAnnotation = typeAnnotation.with(\.trailingTrivia, [])
        }
        transformed =
            transformed
            .with(\.initializer, nil)
            .with(\.accessorBlock, accessorBlock)
            .with(\.trailingComma, nil)
        transformed.trailingTrivia = []

        var result = varDecl.trimmed
        result.bindings = PatternBindingListSyntax([transformed])
        result.bindingSpecifier = .keyword(.var, trailingTrivia: .space)
        result.modifiers = filteredModifiers
        result.attributes = filteredAttributes
        result.leadingTrivia = .newline + .spaces(4)
        result.trailingTrivia = []
        return result
    }

    /// Transform an initializer into a protocol requirement (no body).
    static func protocolInitializer(
        from initDecl: InitializerDeclSyntax,
        context: (any MacroExpansionContext)? = nil
    ) -> InitializerDeclSyntax {
        // Warn if @ProtoMember has options on an initializer (they have no effect)
        if let context {
            let config = ProtoMemberConfig.parse(from: initDecl.attributes, in: context)
            if config != .default {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(initDecl),
                        message: ProtoMemberDiagnostic.optionsOnInitializer
                    )
                )
            }
        }

        var result = initDecl.trimmed
        result.body = nil
        result.modifiers = filterModifiers(initDecl.modifiers)
        result.attributes = filterAttributes(initDecl.attributes)
        result.signature = filterDefaultValues(signature: initDecl.signature)
        result.leadingTrivia = .newline + .spaces(4)
        result.trailingTrivia = []
        return result
    }

    /// Transform a subscript declaration into a protocol requirement.
    static func protocolSubscript(
        from subDecl: SubscriptDeclSyntax,
        isActorType: Bool = false,
        injectActorAsync: Bool = false,
        typeAccessLevel: MemberExtractor.AccessLevel = .internal,
        context: (any MacroExpansionContext)? = nil
    ) -> SubscriptDeclSyntax {
        let ctx = MemberTransformContext(
            attributes: subDecl.attributes,
            modifiers: subDecl.modifiers,
            isActorType: isActorType,
            injectActorAsync: injectActorAsync,
            node: Syntax(subDecl),
            context: context
        )

        // Emit subscript-specific diagnostics
        if let context, ctx.memberConfig.forceMutating {
            context.diagnose(
                Diagnostic(
                    node: Syntax(subDecl),
                    message: ProtoMemberDiagnostic.mutatingOnPropertyOrSubscript
                )
            )
        }

        var result = subDecl.trimmed
        result.modifiers = ctx.filteredModifiers
        result.attributes = ctx.filteredAttributes
        result.parameterClause = filterDefaultValues(parameterClause: subDecl.parameterClause)

        // Merge existing getter effects with @ProtoMember flags
        let existingEffects = existingGetterEffects(subDecl.accessorBlock)
        let needsAsync = ctx.needsAsync || existingEffects.isAsync
        let needsThrows = ctx.memberConfig.forceThrows || existingEffects.isThrows
        let needsEffectfulGetter = needsAsync || needsThrows

        let hasSetter = resolveHasSetter(
            config: ctx.memberConfig,
            accessorBlock: result.accessorBlock,
            modifiers: subDecl.modifiers,
            typeAccessLevel: typeAccessLevel,
            needsEffectfulGetter: needsEffectfulGetter,
            node: Syntax(subDecl),
            context: context
        )

        result.returnClause = result.returnClause.with(\.trailingTrivia, [])
        result.accessorBlock = compactAccessorBlock(
            hasSetter: hasSetter,
            needsAsync: needsAsync,
            needsThrows: needsThrows
        )

        result.leadingTrivia = .newline + .spaces(4)
        result.trailingTrivia = []
        return result
    }
}
