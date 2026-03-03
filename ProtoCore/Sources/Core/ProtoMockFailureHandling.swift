//
//  ProtoMockFailureHandling.swift
//  Proto
//
//  Created by Guillaume Coquard on 19.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

/// Runtime failure helper for generated mocks.
///
/// Generated mocks call this helper to centralize failure behavior.
/// Terminates execution with `preconditionFailure` to preserve fail-fast semantics.
///
/// - Note: Testing framework integration (Issue.record) should be handled
///   at the test-target level, not here, because `canImport(Testing)` evaluates
///   to true at compile time even in non-test targets while the linker symbols
///   are only available in test bundles.
public enum ProtoMockFailureHandling {
    @inline(__always)
    public static func fail(
        _ message: String,
        file: StaticString = #fileID,
        line: UInt = #line
    ) -> Never {
        preconditionFailure(message, file: file, line: line)
    }
}
