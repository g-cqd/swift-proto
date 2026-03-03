//
//  ProtoMockSynchronizationLock.swift
//  Proto
//
//  Created by Guillaume Coquard on 19.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

#if canImport(Foundation)
import Foundation
#endif
#if canImport(Synchronization)
import Synchronization
#endif

/// Internal runtime lock used by generated Sendable mocks.
///
/// Macro expansions cannot introduce imports, so generated mocks reference this
/// runtime helper instead of emitting `import Synchronization` at call sites.
public final class ProtoMockSynchronizationLock: @unchecked Sendable {
    #if canImport(Foundation)
    private let primitive = NSLock()
    #endif

    public init() {}

    public func withLock<R>(_ body: () -> R) -> R {
        #if canImport(Synchronization)
        if #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) {
            return Self.withModernLock(body)
        }
        #endif
        #if canImport(Foundation)
        primitive.lock()
        defer { primitive.unlock() }
        return body()
        #else
        return body()
        #endif
    }
}

#if canImport(Synchronization)
@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
private extension ProtoMockSynchronizationLock {
    static let modernLock: Mutex<Void> = .init(())

    static func withModernLock<R>(_ body: () -> R) -> R {
        modernLock.withLock { _ in body() }
    }
}
#endif
