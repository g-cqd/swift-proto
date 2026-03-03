//
//  ProtoDeclarations.swift
//  Proto
//
//  Created by Guillaume Coquard on 17.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

/// Option type for configuring the `@Proto` macro.
///
/// This uses the phantom-type pattern: methods return `Self` but carry no
/// runtime state. The macro plugin parses the syntax tree directly rather
/// than evaluating these values. The `convenience_type` SwiftLint rule is
/// suppressed because the struct serves as a namespace for these DSL methods.
///
/// Use static members to compose options:
/// ```swift
/// @Proto(.include(.static), .scope(.public), .conforms(to: Identifiable.self))
/// ```
public struct ProtoOption {
    /// Include specific member categories in the generated protocol.
    ///
    /// Options are applied sequentially — later options override earlier ones.
    /// For example, `.exclude(.methods), .include(.members)` re-includes methods
    /// because `.include(.members)` runs after `.exclude(.methods)`.
    public static func include(_ selections: ProtoMemberSelection...) -> Self {
        Self()
    }

    /// Exclude specific member categories from the generated protocol.
    ///
    /// Options are applied sequentially — later options override earlier ones.
    /// For example, `.include(.members), .exclude(.methods)` excludes methods
    /// because `.exclude(.methods)` runs after `.include(.members)`.
    public static func exclude(_ selections: ProtoMemberSelection...) -> Self {
        Self()
    }

    /// Override the access level of the generated protocol.
    public static func scope(_ scope: ProtoScope) -> Self {
        Self()
    }

    /// Add protocol inheritance to the generated protocol.
    /// - Tip: Use ``sendable`` as shorthand for `Sendable` conformance.
    public static func conforms(to types: Any.Type...) -> Self {
        Self()
    }

    /// Shorthand for `.conforms(to: Sendable.self)`.
    public static var sendable: Self {
        Self()
    }

    /// Suppress Actor inheritance and automatic async injection.
    /// Shorthand for `.isolation(.none)`.
    public static var noIsolation: Self {
        Self()
    }

    /// Configure actor inheritance and async injection behavior when applied to actors.
    public static func isolation(_ mode: ProtoIsolation) -> Self {
        Self()
    }

    /// No primary associated types (the default).
    public static var unconstrained: Self {
        Self()
    }

    /// All generic parameters become primary associated types.
    public static var constrained: Self {
        Self()
    }

    /// Configure constrained generation options.
    /// - `.to(...)` constrains only listed generic parameters.
    /// - `.to("T", .withWhereClause)` preserves `where` constraints for specific parameters.
    /// - `.withWhereClause` preserves all original `where` clause constraints.
    public static func constrained(_ options: ProtoConstrainedOption...) -> Self {
        Self()
    }

    /// Generate a companion `<TypeName>Mock` type conforming to the generated protocol.
    ///
    /// When combined with `.conforms(to: Sendable.self)` or `.sendable`, the
    /// mock is emitted as `@unchecked Sendable` and generated with synchronized
    /// helper state.
    /// Proto prefers `Synchronization.Mutex` when available and falls back to
    /// `Foundation.NSLock` otherwise.
    public static var mock: Self {
        Self()
    }

    /// Generate a companion `<TypeName>Mock` type with conditional compilation and/or scope override.
    ///
    /// - SeeAlso: ``mock`` for thread-safety notes on `@unchecked Sendable` mocks.
    public static func mock(_ options: ProtoMockOption...) -> Self {
        Self()
    }
}

/// Isolation mode for actor-based protocol generation.
public enum ProtoIsolation {
    /// Actor inheritance and async injection are enabled (default).
    case full

    /// Actor inheritance is enabled, async injection is disabled.
    case actorOnly

    /// Actor inheritance is disabled, async injection is enabled.
    case asyncOnly

    /// Actor inheritance and async injection are disabled.
    case none
}

/// Selectors used by `.include(...)` and `.exclude(...)`.
public enum ProtoMemberSelection {
    /// All methods, properties, and subscripts.
    case members

    /// Methods only.
    case methods

    /// Properties only.
    case properties

    /// Subscripts only.
    case subscripts

    /// Static methods, properties, and subscripts.
    case `static`

    /// Initializers.
    case initializer
}

/// Modifier for per-parameter where-clause opt-in in `.to(...)`.
///
/// This uses the phantom-type pattern: the macro plugin parses the syntax tree
/// directly rather than evaluating these values at runtime.
public struct ProtoConstrainedModifier {
    /// Preserve `where` clause constraints for the associated parameter.
    public static var withWhereClause: Self {
        Self()
    }
}

/// Selectors used by `.constrained(...)`.
public struct ProtoConstrainedOption {
    /// Constrain only specific generic parameters as primary associated types.
    public static func to(_ names: String...) -> Self {
        Self()
    }

    /// Constrain a specific generic parameter with an optional modifier.
    ///
    /// Use `.withWhereClause` to preserve `where` clause constraints for this parameter:
    /// ```swift
    /// @Proto(.constrained(.to("Key", .withWhereClause), .to("Value")))
    /// ```
    public static func to(_ name: String, _ modifier: ProtoConstrainedModifier) -> Self {
        Self()
    }

    /// Preserve all original `where` clause constraints on the generated protocol.
    ///
    /// By default, `where` clauses are omitted. Use this shorthand to keep them all:
    /// ```swift
    /// @Proto(.constrained(.withWhereClause))
    /// ```
    ///
    /// - Important: Cannot be combined with `.to(...)` at root level.
    ///   Use per-parameter `.to("T", .withWhereClause)` instead.
    public static var withWhereClause: Self {
        Self()
    }
}

/// Selectors used by `.mock(...)`.
public struct ProtoMockOption {
    /// Wrap mock in `#if DEBUG`.
    public static var debug: Self {
        Self()
    }

    /// Wrap mock in `#if RELEASE`.
    public static var release: Self {
        Self()
    }

    /// Wrap mock in `#if <flag>` with a custom compilation condition.
    ///
    /// The flag must be a valid compilation condition identifier.
    public static func custom(_ flag: String) -> Self {
        Self()
    }

    /// Wrap mock in `#if <expression>` using a raw compile-time condition expression.
    ///
    /// Use this when you need compound conditions that cannot be represented by
    /// `.debug`, `.release`, or `.custom(...)`.
    ///
    /// The expression must be a single-line compile condition and must not
    /// contain `;`.
    ///
    /// Example: `.expr("DEBUG && os(iOS)")`
    public static func expr(_ expression: String) -> Self {
        Self()
    }

    /// Override the access level of the generated mock.
    public static func scope(_ scope: ProtoScope) -> Self {
        Self()
    }

    /// Enable convention-based auto-defaulting for unstubbed return values.
    ///
    /// When a mock function returns a Proto-managed protocol type (e.g. `UserProtocol`),
    /// the generated mock returns `UserMock()` instead of calling `fail(...)`.
    public static var auto: Self {
        Self()
    }
}

/// Option type for configuring the `@ProtoMember` macro.
///
/// Use static members to compose options:
/// ```swift
/// @ProtoMember(.immutable, .sync)
/// ```
public struct ProtoMemberOption {
    /// Strip setter — produce `{ get }` or `{ get async }`.
    public static var immutable: Self {
        Self()
    }

    /// Force setter — produce `{ get set }` even on `let` or computed-get.
    public static var mutable: Self {
        Self()
    }

    /// Force `async` on any member.
    public static var async: Self {
        Self()
    }

    /// Force `throws` on any member.
    public static var `throws`: Self {
        Self()
    }

    /// Prevent async injection on any member.
    public static var sync: Self {
        Self()
    }

    /// Force `mutating` modifier on function in protocol.
    public static var mutating: Self {
        Self()
    }

    /// Force `nonisolated` modifier on a member requirement.
    /// Relevant for actor-generated protocols.
    public static var nonisolated: Self {
        Self()
    }

    /// Force actor-isolated requirement generation.
    /// Relevant for actor-generated protocols.
    public static var isolated: Self {
        Self()
    }
}

/// Generates a protocol named `<TypeName>Protocol` from the exposed API of the attached type.
///
/// Note that developers need to manually add `: <TypeName>Protocol` conformance to the type declaration:
/// ```swift
/// @Proto
/// struct MyService: MyServiceProtocol { ... }
/// ```
@attached(peer, names: suffixed(Protocol), suffixed(Mock))
public macro Proto(_ options: ProtoOption...) = #externalMacro(module: "ProtoMacroPlugin", type: "ProtoMacro")

/// Marks a member to be excluded from the generated protocol.
@attached(peer)
public macro ProtoExclude() = #externalMacro(module: "ProtoMacroPlugin", type: "ProtoExcludeMacro")

/// Configures how a member appears in the generated protocol.
@attached(peer)
public macro ProtoMember(_ options: ProtoMemberOption...) =
    #externalMacro(
        module: "ProtoMacroPlugin",
        type: "ProtoMemberMacro"
    )

/// Marks a member as excluded from generated mock helper API.
/// The member still gets a conformance-safe fallback implementation.
@attached(peer)
public macro ProtoMockIgnored() =
    #externalMacro(
        module: "ProtoMacroPlugin",
        type: "ProtoMockIgnoredMacro"
    )
