# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Proto, please report it responsibly.

**Do not open a public issue.** Instead, send a detailed report to the
maintainers via a private channel (e.g., a GitHub Security Advisory or direct
contact).

Include:

- A description of the vulnerability.
- Steps to reproduce or a minimal proof of concept.
- The potential impact.
- Any suggested fix, if you have one.

## Response Timeline

- **Acknowledgement**: within 3 business days.
- **Initial assessment**: within 7 business days.
- **Fix or mitigation**: as soon as reasonably possible, depending on severity.

## Scope

Proto is a compile-time Swift macro library. Its attack surface is limited to:

- **Macro expansion**: malformed input declarations could theoretically produce
  unexpected generated code.
- **Build-time dependencies**: `swift-syntax` is the only external dependency.

Runtime vulnerabilities in downstream applications that _use_ Proto-generated
code are outside Proto's scope, but we still welcome reports if Proto's output
contributes to the issue.

## Supported Versions

Security fixes are applied to the latest release branch. Older versions are not
actively maintained for security updates.

## Disclosure Policy

We follow coordinated disclosure. Once a fix is available, we will:

1. Release a patched version.
2. Publish a GitHub Security Advisory with details.
3. Credit the reporter (unless they prefer to remain anonymous).
