# Configuration Reference

`@Proto(...)` options are parsed in declaration order. When multiple options
target the same behavior, later options override earlier options.

## Core Options (`ProtoOption`)

| Option | Behavior |
| --- | --- |
| ``ProtoOption/include(_:)`` | Include selected member categories. |
| ``ProtoOption/exclude(_:)`` | Exclude selected member categories. |
| ``ProtoOption/scope(_:)`` | Override generated protocol access level. |
| ``ProtoOption/conforms(to:)`` | Add inherited protocol requirements. |
| ``ProtoOption/sendable`` | Shorthand for `Sendable` inheritance. |
| ``ProtoOption/noIsolation`` | Shorthand for ``ProtoOption/isolation(_:)`` with `.none`. |
| ``ProtoOption/isolation(_:)`` | Configure actor inheritance and async injection behavior. |
| ``ProtoOption/unconstrained`` | Keep original generic form (default). |
| ``ProtoOption/constrained`` | Promote all generic parameters to primary associated types. |
| ``ProtoOption/constrained(_:)`` | Configure constrained behavior using ``ProtoConstrainedOption``. |
| ``ProtoOption/mock`` | Generate `<TypeName>Mock`. |
| ``ProtoOption/mock(_:)`` | Generate `<TypeName>Mock` with ``ProtoMockOption`` values. |

## Include / Exclude Selections (`ProtoMemberSelection`)

Used by ``ProtoOption/include(_:)`` and ``ProtoOption/exclude(_:)``:

| Selection | Category |
| --- | --- |
| `.members` | Methods + properties + subscripts |
| `.methods` | Methods only |
| `.properties` | Properties only |
| `.subscripts` | Subscripts only |
| `.static` | Static methods/properties/subscripts |
| `.initializer` | Initializers |

Example:

```swift
@Proto(.exclude(.members), .include(.methods))
```

Only methods are included because `.include(.methods)` is evaluated last.

## Access Scope (`ProtoScope`)

| Scope | Generated Access |
| --- | --- |
| `.private` | `private` |
| `.fileprivate` | `fileprivate` |
| `.internal` | `internal` |
| `.package` | `package` |
| `.public` | `public` |
| `.open` | `open` |

## Isolation (`ProtoIsolation`)

| Mode | Actor Inheritance | Async Injection |
| --- | --- | --- |
| `.full` | enabled | enabled |
| `.actorOnly` | enabled | disabled |
| `.asyncOnly` | disabled | enabled |
| `.none` | disabled | disabled |

## Constrained Options (`ProtoConstrainedOption`)

| Option | Behavior |
| --- | --- |
| `.to("T", "U")` | Constrain only listed generic parameters. |
| `.to("T", .withWhereClause)` | Constrain parameter and preserve its `where` clause constraints. |
| `.withWhereClause` | Preserve all original `where` clause constraints (default: omitted). |

> Note: By default, the original `where` clause is **omitted** from the generated protocol.
> Use `.withWhereClause` (root-level) to keep all constraints, or per-parameter
> `.to("T", .withWhereClause)` to keep only specific parameter constraints.
> Root-level `.withWhereClause` cannot be combined with `.to(...)`; use per-parameter form instead.

## Mock Options (`ProtoMockOption`)

Used with ``ProtoOption/mock(_:)``:

| Option | Behavior |
| --- | --- |
| ``ProtoMockOption/debug`` | Wrap mock declaration in `#if DEBUG`. |
| ``ProtoMockOption/release`` | Wrap mock declaration in `#if RELEASE`. |
| ``ProtoMockOption/custom(_:)`` | Wrap mock declaration in `#if <flag>`. |
| ``ProtoMockOption/expr(_:)`` | Wrap mock declaration in `#if <expression>`. |
| ``ProtoMockOption/scope(_:)`` | Override generated mock access level. |
| ``ProtoMockOption/auto`` | Auto-return `*Mock()` for unstubbed protocol-shaped return types. |
| ``ProtoMockOption/propertySetters`` | Generate setter methods for get-only properties (the default). |
| ``ProtoMockOption/noPropertySetters`` | Suppress setter method generation for get-only properties. |

When `.auto` is active, the generated protocol also inherits `Proto.Metatype`
(a marker protocol) so downstream tooling can identify Proto-managed protocols
at the type level.

When multiple compilation conditions are provided, Proto joins them with
logical `||`. Use parentheses in `expr(...)` when precedence matters.
Expressions must be single-line and cannot contain `;`.

## Member-Level Overrides (`ProtoMemberOption`)

Use ``ProtoMember(_:)`` with ``ProtoMemberOption``:

| Option | Effect |
| --- | --- |
| `.immutable` | Force `{ get }` |
| `.mutable` | Force `{ get set }` |
| `.async` | Force `async` |
| `.throws` | Force `throws` |
| `.sync` | Prevent async injection |
| `.mutating` | Force `mutating` on function requirement |
| `.nonisolated` | Force `nonisolated` requirement |
| `.isolated` | Force actor-isolated requirement |
