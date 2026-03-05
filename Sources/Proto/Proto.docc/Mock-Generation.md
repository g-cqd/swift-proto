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

## Property Setter Methods

By default, get-only protocol properties in the mock receive private backing
storage and a setter method so tests can inject values:

```swift
// Source: var name: String { get }
// Generated in mock:
private var _nameValue: String?
var name: String {
    get {
        guard let value = _nameValue else {
            ProtoMockFailureHandling.fail("Unstubbed property 'name' on StoreMock")
        }
        return value
    }
}
func setName(_ value: String) {
    _nameValue = value
}
```

When the getter has async effects (e.g. actor isolation), the setter method is
also `async`. The setter never inherits `throws` because it only assigns a value.

Use ``ProtoMockOption/noPropertySetters`` to suppress setter generation. In that
case, get-only properties use failure stubs or auto-defaults directly without
backing storage.

With ``ProtoMockOption/auto``, backing storage is initialized with the
convention-based default (e.g. `UserMock()`) and the guard/fail is omitted.

Properties that already have a setter in the protocol (`{ get set }`) are
unaffected — the mock uses a standard stored property stub.

``ProtoMockIgnored()`` on a property also suppresses its setter method.

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
