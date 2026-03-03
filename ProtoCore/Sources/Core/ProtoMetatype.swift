//
//  ProtoMetatype.swift
//  Proto
//
//  Created by Guillaume Coquard on 19.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

/// Marker protocol for Proto-managed protocols.
///
/// When `.mock(.auto)` is used, Proto adds `Proto.Metatype` to the generated
/// protocol's inheritance list. This allows downstream tooling to identify
/// Proto-managed protocols at the type level.
public protocol Metatype {}
