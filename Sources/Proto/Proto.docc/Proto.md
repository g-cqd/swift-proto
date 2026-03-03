# ``Proto``

Generate protocols and optional companion mocks from concrete Swift types.

## Overview

`Proto` exposes a peer-macro DSL for protocol-oriented design:

- ``Proto(_:)`` generates `<TypeName>Protocol`.
- ``Proto(_:)`` with `.mock` also generates `<TypeName>Mock`, and `.mock(.auto)`
  enables convention-based default return values for unstubbed protocol-shaped
  returns.
- ``ProtoMember(_:)`` adjusts member-level generation behavior.
- ``ProtoExclude()`` and ``ProtoMockIgnored()`` selectively skip output.

Use Proto when you want lightweight dependency inversion without manually
maintaining protocol and test-double boilerplate.

## Goals

- Generate protocol surfaces directly from production types.
- Keep generated APIs deterministic and easy to reason about.
- Reduce protocol drift between implementation and contract.
- Provide practical mocks for unit and integration tests.

## Non-Goals

- Runtime reflection or dynamic proxying.
- Replacing handwritten domain-specific fakes where behavior is intentional.
- Supporting non-nominal declarations (Proto requires class/struct/enum/actor).

## Requirements

- Swift 6.2+
- Swift language mode: Swift 6
- Apple platforms:
  - macOS 10.15+
  - iOS 13+
  - watchOS 6+
  - tvOS 13+
  - visionOS 1+

## Topics

### Essentials

- <doc:Getting-Started>
- <doc:Configuration-Reference>
- <doc:Mock-Generation>

### Macros

- ``Proto(_:)``
- ``ProtoExclude()``
- ``ProtoMember(_:)``
- ``ProtoMockIgnored()``

### Option Types

- ``ProtoOption``
- ``ProtoMemberOption``
- ``ProtoMockOption``
- ``ProtoConstrainedOption``

### Supporting Types

- ``ProtoScope``
- ``ProtoIsolation``
- ``ProtoMemberSelection``
