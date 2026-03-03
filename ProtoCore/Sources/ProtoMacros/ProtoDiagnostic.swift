//
//  ProtoDiagnostic.swift
//  Proto
//
//  Created by Guillaume Coquard on 19.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftDiagnostics

enum ProtoDiagnostic: DiagnosticMessage {
    case requiresNominalType
    case unknownOption
    case invalidScopeValue
    case invalidIsolationValue
    case invalidMemberSelectionValue
    case invalidConstrainedTypeList
    case invalidConstrainedOptionValue
    case mixedWhereClauseWithTo
    case unknownConstrainedTypeName(String)
    case interpolatedStringNotSupported
    case interpolatedStringNotSupportedInMockExpr
    case invalidConformsToArgument
    case invalidMockOptionValue
    case invalidStringArgument
    case invalidCompilationCondition(String)
    case invalidCompilationExpression(String)

    var severity: DiagnosticSeverity {
        switch self {
        case .requiresNominalType,
            .invalidScopeValue,
            .invalidIsolationValue,
            .invalidMemberSelectionValue,
            .invalidConstrainedTypeList,
            .invalidConstrainedOptionValue,
            .mixedWhereClauseWithTo,
            .interpolatedStringNotSupported,
            .interpolatedStringNotSupportedInMockExpr,
            .invalidConformsToArgument,
            .invalidMockOptionValue,
            .invalidStringArgument,
            .invalidCompilationCondition,
            .invalidCompilationExpression:
            .error
        case .unknownOption,
            .unknownConstrainedTypeName:
            .warning
        }
    }

    var message: String {
        switch self {
        case .requiresNominalType:
            "@Proto can only be applied to a class, struct, enum, or actor"
        case .unknownOption:
            "Unknown option; expected '.include(...)', '.exclude(...)', '.scope(...)', "
                + "'.conforms(to:)', '.sendable', '.mock', '.mock(...)', '.noIsolation', '.isolation(...)', "
                + "'.constrained', '.constrained(...)', or '.unconstrained'"
        case .invalidScopeValue:
            "Invalid scope value; expected '.private', '.fileprivate', '.internal', '.package', '.public', or '.open'"
        case .invalidIsolationValue:
            "Invalid isolation value; expected '.full', '.actorOnly', '.asyncOnly', or '.none'"
        case .invalidMemberSelectionValue:
            "Invalid member selection; expected '.members', '.methods', '.properties', "
                + "'.subscripts', '.static', or '.initializer'"
        case .invalidConstrainedTypeList:
            "Invalid constrained type list; expected one or more string names in '.to(...)'"
        case .invalidConstrainedOptionValue:
            "Invalid constrained option; expected '.to(...)' or '.withWhereClause'"
        case .mixedWhereClauseWithTo:
            "'.withWhereClause' cannot be combined with '.to(...)' at root level; "
                + "use per-parameter '.to(\"T\", .withWhereClause)' instead"
        case .unknownConstrainedTypeName(let name):
            "'\(name)' does not match any generic parameter; it will be ignored"
        case .interpolatedStringNotSupported:
            "String interpolation is not supported in '.to(...)'; use a plain string literal"
        case .interpolatedStringNotSupportedInMockExpr:
            "String interpolation is not supported in '.expr(...)'; use a plain string literal"
        case .invalidConformsToArgument:
            "Invalid argument for '.conforms(to:)'; expected a type literal like 'Sendable.self'"
        case .invalidMockOptionValue:
            "Invalid mock option; expected '.debug', '.release', '.custom(\"...\")', '.expr(\"...\")' or '.scope(...)'"
        case .invalidStringArgument:
            "Expected a string literal argument"
        case .invalidCompilationCondition(let flag):
            "Invalid compilation condition '\(flag)'; must contain only letters, digits, and underscores"
        case .invalidCompilationExpression(let expression):
            "Invalid compilation expression '\(expression)'; expression must be "
                + "non-empty, single-line, and must not contain ';'"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "ProtoMacro", id: stableID)
    }

    private var stableID: String {
        switch self {
        case .unknownConstrainedTypeName:
            "unknownConstrainedTypeName"
        case .invalidCompilationCondition:
            "invalidCompilationCondition"
        case .invalidCompilationExpression:
            "invalidCompilationExpression"
        default:
            String(describing: self)
        }
    }
}
