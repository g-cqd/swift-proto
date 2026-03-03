# Proto

`Proto` is a Swift macro library that generates protocols (and optional mocks)
from concrete type declarations.

It is built for protocol-first architecture, dependency injection, and test
ergonomics with minimal handwritten boilerplate.

## Why Proto?

In protocol-oriented Swift codebases, keeping protocols, concrete types, and
mocks aligned by hand is tedious and error-prone. Proto automates this:

1. **Annotate** a class, struct, enum, or actor with `@Proto`.
2. **Get** a protocol and an optional mock generated at compile time.
3. **Inject** the protocol in tests and production code with zero drift.

This means less boilerplate, fewer merge conflicts on protocol files, and mocks
that are always in sync with the real implementation.

## Project Goals

- Generate protocol surfaces directly from real production types.
- Keep generated APIs deterministic and easy to reason about.
- Reduce maintenance drift between concrete types and protocol contracts.
- Provide mock generation that is practical for unit and integration tests.

## Non-Goals

- Runtime reflection or dynamic proxying.
- Replacing handwritten domain-specific fakes where behavior matters more than
  call tracking.
- Supporting non-nominal declarations (the macro requires a class, struct, enum,
  or actor).

## Requirements

- Swift 6.2+
- Swift language mode: Swift 6
- Platforms:
  - macOS 10.15+
  - iOS 13+
  - watchOS 6+
  - tvOS 13+
  - visionOS 1+

## Installation

Add `Proto` in your package manifest:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/g-cqd/swift-proto.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .product(name: "Proto", package: "Proto"),
            ]
        ),
    ]
)
```

## Quick Start

```swift
import Proto

@Proto
final class APIClient: APIClientProtocol {
    let baseURL: String

    init(baseURL: String) {
        self.baseURL = baseURL
    }

    func get(path: String) async throws -> Data {
        Data()
    }
}
```

This generates:

```swift
protocol APIClientProtocol {
    var baseURL: String { get }
    func get(path: String) async throws -> Data
}
```

Important: conformance is explicit. Add `: <TypeName>Protocol` yourself.

For a full app-style scenario, see the [Internal Demos](#internal-demos).

## Generated Types

`@Proto` can emit:

- `<TypeName>Protocol`
- `<TypeName>Mock` when `.mock` is enabled

For example, `BillingService` generates `BillingServiceProtocol` and optionally
`BillingServiceMock`.

## Option Reference (`@Proto`)

All options are values of `ProtoOption`.

### Core Options

| Option | Meaning |
| --- | --- |
| `.include(...)` | Include specific member categories. |
| `.exclude(...)` | Exclude specific member categories. |
| `.scope(...)` | Override generated protocol access level. |
| `.conforms(to: ...)` | Add protocol inheritance to generated protocol. |
| `.sendable` | Shorthand for `.conforms(to: Sendable.self)`. |
| `.noIsolation` | Shortcut for `.isolation(.none)`. |
| `.isolation(...)` | Control actor inheritance and async injection. |
| `.unconstrained` | No primary associated type rewriting (default). |
| `.constrained` | Make all generics primary associated types. |
| `.constrained(...)` | Configure constrained behavior with sub-options. |
| `.mock` | Generate `<TypeName>Mock`. |
| `.mock(...)` | Generate `<TypeName>Mock` with mock sub-options. |

### Member Selection (`ProtoMemberSelection`)

Used with `.include(...)` and `.exclude(...)`.

| Selection | Included/Excluded Category |
| --- | --- |
| `.members` | Methods + properties + subscripts |
| `.methods` | Methods only |
| `.properties` | Properties only |
| `.subscripts` | Subscripts only |
| `.static` | Static methods/properties/subscripts |
| `.initializer` | Initializers |

### Include/Exclude Precedence

Options are applied in declaration order. Later options win.

```swift
@Proto(.exclude(.methods), .include(.members))
```

This includes methods (because the second option overrides the first for that
category).

### Access Scope (`ProtoScope`)

| Scope | Output Access |
| --- | --- |
| `.private` | `private` |
| `.fileprivate` | `fileprivate` |
| `.internal` | `internal` |
| `.package` | `package` |
| `.public` | `public` |
| `.open` | `open` |

### Actor Isolation (`ProtoIsolation`)

| Isolation | Actor Inheritance | Async Injection |
| --- | --- | --- |
| `.full` | enabled | enabled |
| `.actorOnly` | enabled | disabled |
| `.asyncOnly` | disabled | enabled |
| `.none` | disabled | disabled |

### Constrained Options (`ProtoConstrainedOption`)

Used with `.constrained(...)`.

| Option | Meaning |
| --- | --- |
| `.to("T", "U")` | Constrain only listed generic parameters. |
| `.to("T", .withWhereClause)` | Constrain parameter and preserve its `where` clause constraints. |
| `.withWhereClause` | Preserve all original `where` clause constraints (default: omitted). |

### Mock Options (`ProtoMockOption`)

Used with `.mock(...)`.

| Option | Meaning |
| --- | --- |
| `.debug` | Wrap mock declaration in `#if DEBUG`. |
| `.release` | Wrap mock declaration in `#if RELEASE`. |
| `.custom("FLAG")` | Wrap mock declaration in `#if FLAG` (identifier only). |
| `.expr("DEBUG && os(iOS)")` | Wrap mock declaration in `#if <expression>`. |
| `.scope(...)` | Override generated mock access level. |
| `.auto` | Auto-return `*Mock()` for unstubbed protocol-shaped return types. |

When multiple mock conditions are provided, Proto joins them with `||`. Use
parentheses inside `.expr(...)` when precedence matters. Expressions must be
single-line and cannot contain `;`.

## Member-Level Macros

### `@ProtoMember`

Use `ProtoMemberOption` to override requirement shape per member.

| Option | Effect |
| --- | --- |
| `.immutable` | Force `{ get }` |
| `.mutable` | Force `{ get set }` |
| `.async` | Force `async` |
| `.throws` | Force `throws` |
| `.sync` | Prevent async injection |
| `.mutating` | Force `mutating` for function requirement |
| `.nonisolated` | Force `nonisolated` |
| `.isolated` | Force actor-isolated requirement |

### `@ProtoExclude`

Exclude the member from generated protocol requirements.

### `@ProtoMockIgnored`

Exclude the member from generated mock helper API. A fallback implementation is
still generated so protocol conformance remains valid.

## Mock Generation Details

When `.mock` is enabled, generated `<TypeName>Mock` includes helper APIs per
member, such as:

- `<member>CallCount`
- `<member>ReceivedArguments` (when parameters exist)
- `<member>Handler`
- `<member>Error` (for throwing methods where applicable)
- `<member>SetReturnValue(_:)` (for non-`Void` returns)

If a non-`Void` method has no handler and no return stub, mock behavior records
an issue when `Testing` is available and then fails fast via
`ProtoMockFailureHandling.fail("Unstubbed call ...")`.

With `.mock(.auto)`, unstubbed protocol-shaped returns use convention-based
defaults instead of failing fast, for example:

- `UserProtocol` -> `UserMock()`
- `UserProtocol?` -> `UserMock()`
- `[UserProtocol]` -> `[UserMock()]`

When `.auto` is active, the generated protocol also inherits `Proto.Metatype`
(a marker protocol) so downstream tooling can distinguish Proto-managed
protocols at the type level.

### Sendable Mocks

If `.mock` is combined with `.conforms(to: Sendable.self)` or `.sendable` on
non-actor types:

- The generated mock is `@unchecked Sendable`.
- Helper state is synchronized.
- Runtime synchronization prefers `Synchronization.Mutex` when available and
  falls back to `Foundation.NSLock`.

## Advanced Examples

### Conditional Mock Generation + Scope Override

```swift
@Proto(
    .mock(.debug, .scope(.internal)),
    .scope(.public)
)
final class PaymentsService: PaymentsServiceProtocol {
    func charge(cents: Int) async throws -> String { "ok" }
}
```

### Selective API Surface

```swift
@Proto(
    .exclude(.members),
    .include(.methods),
    .include(.initializer)
)
final class OperationPipeline: OperationPipelineProtocol {
    let name: String

    init(name: String) {
        self.name = name
    }

    func run(_ input: String) -> String {
        "\(name):\(input)"
    }
}
```

### Constrained Generic Protocols

```swift
@Proto(.constrained(.to("Entity", .withWhereClause)))
final class Repository<Entity> where Entity: Hashable {
    func save(_ value: Entity) {}
}
```

## Validation Commands

Project validation commands used in this repository:

```bash
swift build
swift test
swift test --enable-code-coverage
swift format --in-place --recursive .
```

## Documentation

- Symbol documentation in `ProtoCore/Sources/Core/*.swift`
- DocC catalog in `Sources/Proto/Proto.docc`

## Package Layout

- `ProtoCore`
  - `Sources/Core`: public declarations and runtime support
  - `Sources/ProtoMacros`: macro implementation
  - `Sources/ProtoMacroPlugin`: compiler plugin entry point
- `Sources/Proto`: public re-export target
- `ProtoTests/Tests/MacroTests`: macro expansion tests
- `Tests/ProtoIntegrationTests`: runtime integration tests
- `ProtoDemoPackage`: internal, non-public umbrella demo package
  - `Sources/ProtoDemoDomain` + `Sources/ProtoDemoApp`: monthly budget demo
  - `Sources/ProtoAutoOpsDomain` + `Sources/ProtoAutoOpsApp`: incident ops demo
  - `Tests/ProtoDemoDomainTests` and `Tests/ProtoAutoOpsDomainTests`: per-demo tests
  - `Tests/ProtoDemoTests`: aggregate cross-demo tests

## Internal Demos

`ProtoDemoPackage` demonstrates Proto in two realistic scenarios:
monthly-budget monitoring and security incident operations. It is not published
as a product.

Its aggregate test target is wired into the root package, so running
`swift test` from the repository root includes `ProtoDemoTests`.

Run it directly:

```bash
cd ProtoDemoPackage
swift build
swift test
swift run ProtoDemoApp
swift run ProtoAutoOpsApp
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to get involved.

## Security

See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.

## License

This project is licensed under the [Mozilla Public License 2.0](LICENSE).

```
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
```
