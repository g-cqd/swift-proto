//
//  ProtoMacroConfig.swift
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

/// Configuration parsed from `@Proto(...)` macro arguments.
/// Controls protocol generation behavior including member filtering,
/// access level, generic constraints, conformances, and isolation.
struct ProtoMacroConfig: Sendable {
    enum PrimaryTypeBehavior: Sendable {
        case unconstrained  // default — no primary associated types
        case all  // .constrained — all generic params become primary
        case explicit([String])  // .constrained(.to("Key")) — specific selection
    }

    enum WhereClauseBehavior: Sendable {
        case omit  // default — no where clause
        case keepAll  // .constrained(.withWhereClause)
        case keepFor(Set<String>)  // per-parameter .to("T", .withWhereClause)
    }

    enum IsolationBehavior: Sendable {
        case full
        case actorOnly
        case asyncOnly
        case none

        var actorInheritanceEnabled: Bool {
            switch self {
            case .full, .actorOnly:
                true
            case .asyncOnly, .none:
                false
            }
        }

        var asyncInjectionEnabled: Bool {
            switch self {
            case .full, .asyncOnly:
                true
            case .actorOnly, .none:
                false
            }
        }
    }

    enum MemberSelection: Sendable {
        case members
        case methods
        case properties
        case subscripts
        case `static`
        case initializer
    }

    let scope: MemberExtractor.AccessLevel?
    let includeMethods: Bool
    let includeProperties: Bool
    let includeSubscripts: Bool
    let includeStatic: Bool
    let includeInit: Bool
    let includeMock: Bool
    let mockCompilationConditions: [String]
    let mockScope: MemberExtractor.AccessLevel?
    let mockAutoDefault: Bool
    let primaryBehavior: PrimaryTypeBehavior
    let whereClauseBehavior: WhereClauseBehavior
    let conformsTo: [String]
    let isolation: IsolationBehavior

    static func parse(from node: AttributeSyntax, in context: some MacroExpansionContext) -> Self {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return .default
        }

        var state = ParsingState()
        for arg in arguments {
            processArgument(arg.expression, state: &state, context: context)
        }
        return state.build()
    }
}
