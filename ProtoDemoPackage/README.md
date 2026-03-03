# ProtoDemoPackage

Internal umbrella demo package for Proto.

## Purpose

This package wraps two realistic demos:

- Monthly budget monitoring (`ProtoDemo*`)
- Security incident response operations (`ProtoAutoOps*`)

Both demonstrate `@Proto(.mock(.auto))` usage for reducing mock setup while
keeping protocol boundaries explicit.

## Package Layout

- `Sources/ProtoDemoDomain`
  - Budget domain models and orchestration
- `Sources/ProtoDemoApp`
  - Budget demo executable
- `Tests/ProtoDemoDomainTests`
  - Budget demo tests
- `Sources/ProtoAutoOpsDomain`
  - Incident operations models and orchestration
- `Sources/ProtoAutoOpsApp`
  - Incident ops demo executable
- `Tests/ProtoAutoOpsDomainTests`
  - Auto-ops demo tests
- `Tests/ProtoDemoTests`
  - Aggregate smoke tests across both demos

## Run

```bash
cd ProtoDemoPackage
swift build
swift test
swift run ProtoDemoApp
swift run ProtoAutoOpsApp
```

If an app fails to locate `Testing.framework` in your toolchain setup, run the
built binary with a fallback framework path:

```bash
cd ProtoDemoPackage
DYLD_FALLBACK_FRAMEWORK_PATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks \
  ./.build/arm64-apple-macosx/debug/ProtoDemoApp
DYLD_FALLBACK_FRAMEWORK_PATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks \
  ./.build/arm64-apple-macosx/debug/ProtoAutoOpsApp
```
