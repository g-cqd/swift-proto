//
//  ProtoPlugin.swift
//  Proto
//
//  Created by Guillaume Coquard on 17.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import ProtoMacros
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

// Wrapper types in the ProtoMacroPlugin module so that
// `String(reflecting:)` returns "ProtoMacroPlugin.ProtoMacro",
// matching `#externalMacro(module: "ProtoMacroPlugin", ...)`.
// The actual implementation lives in the ProtoMacros library
// which can be imported by test targets.

public struct ProtoMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try ProtoMacros.ProtoMacro.expansion(
            of: node,
            providingPeersOf: declaration,
            in: context
        )
    }
}

public struct ProtoExcludeMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try ProtoMacros.ProtoExcludeMacro.expansion(
            of: node,
            providingPeersOf: declaration,
            in: context
        )
    }
}

public struct ProtoMemberMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try ProtoMacros.ProtoMemberMacro.expansion(
            of: node,
            providingPeersOf: declaration,
            in: context
        )
    }
}

public struct ProtoMockIgnoredMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try ProtoMacros.ProtoMockIgnoredMacro.expansion(
            of: node,
            providingPeersOf: declaration,
            in: context
        )
    }
}

@main
struct ProtoPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ProtoMacro.self,
        ProtoExcludeMacro.self,
        ProtoMemberMacro.self,
        ProtoMockIgnoredMacro.self,
    ]
}
