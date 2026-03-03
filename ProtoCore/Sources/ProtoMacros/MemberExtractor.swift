//
//  MemberExtractor.swift
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

/// Determines the access level threshold and extracts eligible members
/// from a declaration group.
enum MemberExtractor {
    /// Parses the access level from a modifier list. Returns `.internal` if none is found.
    static func accessLevel(of modifiers: DeclModifierListSyntax) -> AccessLevel {
        for modifier in modifiers {
            if let level = AccessLevel(scopeName: modifier.name.trimmedDescription) {
                return level
            }
        }
        return .internal
    }

    /// Returns the minimum access level a member must have to be included in the protocol.
    static func minimumAccessLevel(for typeAccess: AccessLevel) -> AccessLevel {
        switch typeAccess {
        case .open, .public:
            .public
        case .package:
            .package
        case .internal:
            .internal
        case .fileprivate:
            .fileprivate
        case .private:
            .private
        }
    }

    /// Checks whether a declaration has the `@ProtoExclude` attribute.
    static func hasProtoExclude(_ attributes: AttributeListSyntax) -> Bool {
        hasAttribute("ProtoExclude", in: attributes)
    }

    /// Checks whether a declaration has the `@ProtoMockIgnored` attribute.
    static func hasProtoMockIgnored(_ attributes: AttributeListSyntax) -> Bool {
        hasAttribute("ProtoMockIgnored", in: attributes)
    }

    /// Extracts typealias declarations from a declaration group,
    /// resolving transitive chains (e.g. `typealias A = B; typealias B = String`).
    ///
    /// When a cycle is detected (resolution does not reach a fixed point within
    /// the maximum number of iterations), partially resolved aliases are returned
    /// and a warning diagnostic is emitted if a context is provided.
    static func extractTypeAliases(
        from declGroup: some DeclGroupSyntax,
        node: Syntax? = nil,
        context: (any MacroExpansionContext)? = nil
    ) -> [String: TypeSyntax] {
        var aliases: [String: TypeSyntax] = [:]
        for member in declGroup.memberBlock.members {
            guard let typealiasDecl = member.decl.as(TypeAliasDeclSyntax.self) else { continue }
            let name = typealiasDecl.name.trimmedDescription
            aliases[name] = typealiasDecl.initializer.value.trimmed
        }

        // Resolve transitive chains to a fixed point so A→B→String becomes A→String.
        // Guard against cycles with a maximum iteration count equal to the alias count,
        // since a cycle-free chain can be at most N hops long.
        var changed = true
        var iterations = 0
        let maxIterations = aliases.count
        while changed, iterations < maxIterations {
            changed = false
            iterations += 1
            for (name, type) in aliases {
                let resolved = type.trimmedDescription
                if let transitive = aliases[resolved], transitive.trimmedDescription != resolved {
                    aliases[name] = transitive
                    changed = true
                }
            }
        }

        if changed, iterations == maxIterations, maxIterations > 0, let context, let node {
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: ProtoMemberDiagnostic.typealiasCycleDetected
                )
            )
        }

        return aliases
    }

    /// Checks whether a modifier list contains `static` or `class`.
    static func isStatic(_ modifiers: DeclModifierListSyntax) -> Bool {
        modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.static) || modifier.name.tokenKind == .keyword(.class)
        }
    }

    /// Extracts the setter access level from modifier list, if any.
    /// Handles `private(set)`, `fileprivate(set)`, `internal(set)`, `package(set)`.
    static func setterAccessLevel(of modifiers: DeclModifierListSyntax) -> AccessLevel? {
        for modifier in modifiers {
            guard modifier.detail?.detail.trimmedDescription == "set" else { continue }
            if let level = AccessLevel(scopeName: modifier.name.trimmedDescription) {
                return level
            }
        }
        return nil
    }

    private static func hasAttribute(_ name: String, in attributes: AttributeListSyntax) -> Bool {
        attributes.contains { element in
            guard case .attribute(let attr) = element else { return false }
            return attr.attributeName.trimmedDescription == name
        }
    }

    /// Extract all eligible members from the declaration group.
    ///
    /// Only members declared in the type's primary body are included.
    /// Members added via extensions are excluded by design, since the macro
    /// only has access to the `DeclGroupSyntax` it is attached to.
    static func extract(
        from declGroup: some DeclGroupSyntax,
        typeAccessLevel: AccessLevel,
        includeMethods: Bool,
        includeProperties: Bool,
        includeSubscripts: Bool,
        includeStatic: Bool,
        includeInit: Bool
    ) -> [ProtocolMember] {
        let threshold = minimumAccessLevel(for: typeAccessLevel)
        var result: [ProtocolMember] = []

        for memberItem in declGroup.memberBlock.members {
            if let member = extractMember(
                from: memberItem.decl,
                threshold: threshold,
                includeMethods: includeMethods,
                includeProperties: includeProperties,
                includeSubscripts: includeSubscripts,
                includeStatic: includeStatic,
                includeInit: includeInit
            ) {
                result.append(member)
            }
        }

        return result
    }
}

// MARK: - Member Extraction

private extension MemberExtractor {
    static func extractMember(
        from decl: DeclSyntax,
        threshold: AccessLevel,
        includeMethods: Bool,
        includeProperties: Bool,
        includeSubscripts: Bool,
        includeStatic: Bool,
        includeInit: Bool
    ) -> ProtocolMember? {
        if let funcDecl = decl.as(FunctionDeclSyntax.self) {
            return extractFunction(
                funcDecl,
                threshold: threshold,
                includeMethods: includeMethods,
                includeStatic: includeStatic
            )
        }
        if let varDecl = decl.as(VariableDeclSyntax.self) {
            return extractVariable(
                varDecl,
                threshold: threshold,
                includeProperties: includeProperties,
                includeStatic: includeStatic
            )
        }
        if let initDecl = decl.as(InitializerDeclSyntax.self) {
            return extractInitializer(initDecl, threshold: threshold, includeInit: includeInit)
        }
        if let subDecl = decl.as(SubscriptDeclSyntax.self) {
            return extractSubscript(
                subDecl,
                threshold: threshold,
                includeSubscripts: includeSubscripts,
                includeStatic: includeStatic
            )
        }
        return nil
    }

    static func extractFunction(
        _ funcDecl: FunctionDeclSyntax,
        threshold: AccessLevel,
        includeMethods: Bool,
        includeStatic: Bool
    ) -> ProtocolMember? {
        guard includeMethods else { return nil }
        guard !hasProtoExclude(funcDecl.attributes) else { return nil }
        guard accessLevel(of: funcDecl.modifiers) >= threshold else { return nil }
        guard includeStatic || !isStatic(funcDecl.modifiers) else { return nil }
        return .function(funcDecl)
    }

    static func extractVariable(
        _ varDecl: VariableDeclSyntax,
        threshold: AccessLevel,
        includeProperties: Bool,
        includeStatic: Bool
    ) -> ProtocolMember? {
        guard includeProperties else { return nil }
        guard !hasProtoExclude(varDecl.attributes) else { return nil }
        guard accessLevel(of: varDecl.modifiers) >= threshold else { return nil }
        guard includeStatic || !isStatic(varDecl.modifiers) else { return nil }
        return .variable(varDecl)
    }

    static func extractInitializer(
        _ initDecl: InitializerDeclSyntax,
        threshold: AccessLevel,
        includeInit: Bool
    ) -> ProtocolMember? {
        guard includeInit else { return nil }
        guard !hasProtoExclude(initDecl.attributes) else { return nil }
        guard accessLevel(of: initDecl.modifiers) >= threshold else { return nil }
        return .initializer(initDecl)
    }

    static func extractSubscript(
        _ subDecl: SubscriptDeclSyntax,
        threshold: AccessLevel,
        includeSubscripts: Bool,
        includeStatic: Bool
    ) -> ProtocolMember? {
        guard includeSubscripts else { return nil }
        guard !hasProtoExclude(subDecl.attributes) else { return nil }
        guard accessLevel(of: subDecl.modifiers) >= threshold else { return nil }
        guard includeStatic || !isStatic(subDecl.modifiers) else { return nil }
        return .subscript(subDecl)
    }
}

// MARK: - Access Level

extension MemberExtractor {
    /// The access level of a declaration, ordered from most to least restrictive.
    ///
    /// This is the single source of truth for access levels. `ProtoScope` in
    /// the Core module mirrors these cases for the public DSL; parsing uses
    /// ``init(scopeName:)`` to avoid duplicating the string-to-enum mapping.
    enum AccessLevel: Int, Comparable, Sendable {
        case `private` = 0
        case `fileprivate` = 1
        case `internal` = 2
        case package = 3
        case `public` = 4
        case open = 5

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        /// Initialize from a scope name string (as used in `.scope(...)` DSL).
        /// Returns `nil` for unrecognized names.
        init?(scopeName: String) {
            switch scopeName {
            case "private":
                self = .private
            case "fileprivate":
                self = .fileprivate
            case "internal":
                self = .internal
            case "package":
                self = .package
            case "public":
                self = .public
            case "open":
                self = .open
            default:
                return nil
            }
        }
    }
}
