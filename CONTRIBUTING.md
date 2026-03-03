# Contributing to Proto

Contributions are welcome. This document explains how to get started.

## Getting Started

1. Fork and clone the repository.
2. Ensure you have Swift 6.2+ installed (`swift --version`).
3. Build and run tests from the repository root:

```bash
swift build
swift test
```

## Development Workflow

1. Create a branch from `main` for your change.
2. Make your changes in small, focused commits.
3. Run the full validation suite before submitting:

```bash
swift build
swift test
swift format --in-place --recursive .
```

4. Open a pull request against `main`.

## Code Style

This project enforces consistent style via:

- **swift-format** (Apple's native formatter) with the repo's `.swift-format` configuration.
- **Swift 6 strict language mode** for all targets.

Run the formatter before submitting. CI will reject PRs that do not pass.

## File Headers

All Swift files must include the MPL-2.0 header:

```swift
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
```

## Testing

- **Macro expansion tests** live in `ProtoTests/Tests/MacroTests/`.
- **Integration tests** live in `Tests/ProtoIntegrationTests/`.
- **Demo tests** live in `ProtoDemoPackage/Tests/`.

If your change affects macro output, add or update expansion tests. If it
affects runtime behavior, add or update integration tests.

## Reporting Bugs

Open an issue with:

- A minimal reproducing `@Proto` declaration.
- Expected vs actual generated output.
- Swift version and platform.

## Pull Request Guidelines

- Keep PRs focused on a single concern.
- Include tests for new behavior.
- Update documentation if public API changes.
- Ensure all CI checks pass before requesting review.

## License

By contributing, you agree that your contributions will be licensed under the
[Mozilla Public License 2.0](LICENSE).
