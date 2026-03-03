//
//  ProtoScope.swift
//  Proto
//
//  Created by Guillaume Coquard on 17.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

/// Controls the access level of the generated protocol.
///
/// Maps 1:1 to `MemberExtractor.AccessLevel` in the macro implementation.
public enum ProtoScope {
    /// Emit a `private` generated declaration.
    case `private`

    /// Emit a `fileprivate` generated declaration.
    case `fileprivate`

    /// Emit an `internal` generated declaration.
    case `internal`

    /// Emit a `package` generated declaration.
    case package

    /// Emit a `public` generated declaration.
    case `public`

    /// Emit an `open` generated declaration.
    case open
}
