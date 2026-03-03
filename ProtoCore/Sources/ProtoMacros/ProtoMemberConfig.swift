//
//  ProtoMemberConfig.swift
//  Proto
//
//  Created by Guillaume Coquard on 18.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Configuration parsed from `@ProtoMember(...)` attribute arguments.
/// Controls how individual members appear in the generated protocol.
///
/// ## Conflict Resolution
/// When conflicting options are combined, a diagnostic error is emitted and
/// the conflicting pair is resolved as follows:
/// - `.mutable` + `.immutable` → neither applied (mutual cancellation)
/// - `.async` + `.sync` → `.sync` wins (`forceSync` is checked first)
/// - `.isolated` + `.nonisolated` → neither applied (mutual cancellation)
struct ProtoMemberConfig: Equatable, Sendable {
    let immutable: Bool
    let mutable: Bool
    let forceAsync: Bool
    let forceThrows: Bool
    let forceSync: Bool
    let forceMutating: Bool
    let forceNonisolated: Bool
    let forceIsolated: Bool

    static let `default` = Self(
        immutable: false,
        mutable: false,
        forceAsync: false,
        forceThrows: false,
        forceSync: false,
        forceMutating: false,
        forceNonisolated: false,
        forceIsolated: false
    )

    static func parse(
        from attributes: AttributeListSyntax,
        in context: (any MacroExpansionContext)? = nil
    ) -> Self {
        guard let attr = findProtoMemberAttribute(in: attributes),
            let arguments = attr.arguments?.as(LabeledExprListSyntax.self)
        else {
            return .default
        }

        let options = parseOptions(from: arguments, context: context)
        if let context {
            diagnoseConflicts(in: options, attr: attr, context: context)
        }

        return Self(
            immutable: options.contains(.immutable),
            mutable: options.contains(.mutable),
            forceAsync: options.contains(.async),
            forceThrows: options.contains(.throws),
            forceSync: options.contains(.sync),
            forceMutating: options.contains(.mutating),
            forceNonisolated: options.contains(.nonisolated),
            forceIsolated: options.contains(.isolated)
        )
    }

    private enum Option: String {
        case immutable, mutable
        case async, `throws`, sync
        case mutating, nonisolated, isolated
    }

    private static func parseOptions(
        from arguments: LabeledExprListSyntax,
        context: (any MacroExpansionContext)?
    ) -> Set<Option> {
        var options = Set<Option>()
        for arg in arguments {
            let expr = arg.expression
            guard let memberAccess = expr.as(MemberAccessExprSyntax.self),
                memberAccess.base == nil
            else { continue }

            let name = memberAccess.declName.baseName.trimmedDescription
            if let option = Option(rawValue: name) {
                options.insert(option)
            } else {
                context?.diagnose(
                    Diagnostic(
                        node: Syntax(expr),
                        message: ProtoMemberDiagnostic.unknownMemberOption
                    )
                )
            }
        }
        return options
    }

    private static func diagnoseConflicts(
        in options: Set<Option>,
        attr: AttributeSyntax,
        context: some MacroExpansionContext
    ) {
        func check(_ a: Option, _ b: Option, _ message: ProtoMemberDiagnostic) {
            if options.contains(a), options.contains(b) {
                context.diagnose(Diagnostic(node: Syntax(attr), message: message))
            }
        }
        check(.async, .sync, .asyncSyncConflict)
        check(.mutable, .immutable, .mutableImmutableConflict)
        check(.nonisolated, .isolated, .nonisolatedIsolatedConflict)
    }

    private static func findProtoMemberAttribute(in attributes: AttributeListSyntax) -> AttributeSyntax? {
        for element in attributes {
            guard case .attribute(let attr) = element else { continue }
            if attr.attributeName.trimmedDescription == "ProtoMember" {
                return attr
            }
        }
        return nil
    }
}

// MARK: - Diagnostics

enum ProtoMemberDiagnostic: String, DiagnosticMessage {
    case unknownMemberOption
    case asyncSyncConflict
    case mutableImmutableConflict
    case nonisolatedIsolatedConflict
    case immutableOnFunction
    case mutableOnFunction
    case mutatingOnPropertyOrSubscript
    case mutableEffectfulGetterConflict
    case nonisolatedOnNonActorMember
    case isolatedOnNonActorMember
    case isolatedOnStaticMember
    case uninferablePropertyType
    case optionsOnInitializer
    case typealiasCycleDetected

    var severity: DiagnosticSeverity {
        switch self {
        case .asyncSyncConflict,
            .mutableImmutableConflict,
            .nonisolatedIsolatedConflict,
            .uninferablePropertyType:
            .error
        default:
            .warning
        }
    }

    var message: String {
        switch self {
        case .unknownMemberOption:
            "Unknown @ProtoMember option; expected '.immutable', '.mutable', '.async', "
                + "'.throws', '.sync', '.mutating', '.nonisolated', or '.isolated'"
        case .asyncSyncConflict:
            "Conflicting options: '.async' and '.sync' cannot be combined"
        case .mutableImmutableConflict:
            "Conflicting options: '.mutable' and '.immutable' cannot be combined"
        case .nonisolatedIsolatedConflict:
            "Conflicting options: '.nonisolated' and '.isolated' cannot be combined"
        case .immutableOnFunction:
            "'.immutable' has no effect on functions or initializers"
        case .mutableOnFunction:
            "'.mutable' has no effect on functions or initializers"
        case .mutatingOnPropertyOrSubscript:
            "'.mutating' has no effect on properties or subscripts"
        case .mutableEffectfulGetterConflict:
            "Async/throwing getters cannot have setters; '.mutable' ignored"
        case .nonisolatedOnNonActorMember:
            "'.nonisolated' only affects actor-generated protocol requirements"
        case .isolatedOnNonActorMember:
            "'.isolated' only affects actor-generated protocol requirements"
        case .isolatedOnStaticMember:
            "'.isolated' has no effect on static members"
        case .uninferablePropertyType:
            "Property type cannot be inferred; add an explicit type annotation"
        case .optionsOnInitializer:
            "@ProtoMember options have no effect on initializers"
        case .typealiasCycleDetected:
            "Typealias cycle detected; some type aliases may not be fully resolved"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "ProtoMemberMacro", id: rawValue)
    }
}
