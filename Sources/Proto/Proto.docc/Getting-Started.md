# Getting Started

Set up Proto in a SwiftPM target, annotate a type with ``Proto(_:)``, and
conform that type to the generated protocol.

## Install

```swift
dependencies: [
    .package(url: "<repository-url>", from: "1.0.0"),
]
```

```swift
.target(
    name: "MyFeature",
    dependencies: [
        .product(name: "Proto", package: "Proto")
    ]
)
```

## Basic Usage

```swift
import Proto

@Proto
final class APIClient: APIClientProtocol {
    func get(path: String) async throws -> Data {
        Data()
    }
}
```

Generated:

```swift
protocol APIClientProtocol {
    func get(path: String) async throws -> Data
}
```

## Actor Usage

```swift
@Proto
actor SessionStore: SessionStoreProtocol {
    func login(token: String) {}
}
```

By default, actor requirements keep `Actor` inheritance and gain `async` where
needed. Use ``ProtoOption/isolation(_:)`` or ``ProtoOption/noIsolation`` to
override that behavior.
