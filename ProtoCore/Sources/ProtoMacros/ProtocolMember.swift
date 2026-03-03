//
//  ProtocolMember.swift
//  Proto
//
//  Created by Guillaume Coquard on 17.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftSyntax

/// Represents a member eligible for inclusion in the generated protocol.
enum ProtocolMember {
    case function(FunctionDeclSyntax)
    case variable(VariableDeclSyntax)
    case initializer(InitializerDeclSyntax)
    case `subscript`(SubscriptDeclSyntax)
}
