//
//  ProtoMockIgnoredMacro.swift
//  Proto
//
//  Created by Guillaume Coquard on 18.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftSyntax
import SwiftSyntaxMacros

/// A no-op peer macro used solely as a marker attribute.
/// Its presence on a member signals `ProtoMacro` to omit mock helper generation
/// for that member while preserving protocol conformance.
public struct ProtoMockIgnoredMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
