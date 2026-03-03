# Mock Generation

Use ``ProtoOption/mock`` to generate a companion `<TypeName>Mock`.

## Basic Mock

```swift
@Proto(.mock)
final class BillingService {
    func charge(cents: Int) async throws -> String {
        "ok"
    }
}
```

Generated mock helpers include:

- `chargeCallCount`
- `chargeReceivedArguments`
- `chargeHandler`
- `chargeError`
- `chargeSetReturnValue(_:)`

## Conditional and Scoped Mocks

Use ``ProtoOption/mock(_:)`` with ``ProtoMockOption``:

- `.debug`
- `.release`
- `.custom("FLAG")`
- `.expr("DEBUG && os(iOS)")`
- `.scope(...)`

When multiple conditions are supplied, Proto joins them with logical `||`.
Use parentheses inside `.expr(...)` when precedence matters. Expressions must
be single-line and cannot contain `;`.

## Auto-Default Return Behavior

Use ``ProtoOption/mock(_:)`` with ``ProtoMockOption/auto`` when you want
unstubbed protocol-shaped return values to default to generated mocks instead
of failing fast.

For example:

- `UserProtocol` defaults to `UserMock()`
- `UserProtocol?` defaults to `UserMock()`
- `[UserProtocol]` defaults to `[UserMock()]`

## Sendable Mocks

When combined with ``ProtoOption/conforms(to:)`` and `Sendable.self` (or the
``ProtoOption/sendable`` shorthand), generated class mocks become
`@unchecked Sendable` and use synchronized helper state via
`ProtoMockSynchronizationLock`.

This gives deterministic helper mutation under parallel test access while
preserving the same helper API shape.

## Excluding Helpers for Specific Members

Annotate a member with ``ProtoMockIgnored()`` to skip helper generation for that
member while still emitting a conformance-safe fallback implementation.
