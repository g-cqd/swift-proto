import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroDiagnosticTests {
    @Test
    private func `mock expr with multiline string emits diagnostic`() {
        assertMacroExpansionTesting(
            MockExprSafetyFixture.multilineExprInput,
            expandedSource: MockExprSafetyFixture.serviceExpanded,
            diagnostics: [
                DiagnosticSpec(
                    message: "Invalid compilation expression 'DEBUG &&\nos(iOS)'; expression must be "
                        + "non-empty, single-line, and must not contain ';'",
                    line: 1,
                    column: 14,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test
    private func `mock expr with interpolated string emits diagnostic`() {
        assertMacroExpansionTesting(
            MockExprSafetyFixture.interpolatedExprInput,
            expandedSource: MockExprSafetyFixture.serviceExpanded,
            diagnostics: [
                DiagnosticSpec(
                    message: "String interpolation is not supported in '.expr(...)'; use a plain string literal",
                    line: 1,
                    column: 20,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }
}

private enum MockExprSafetyFixture {
    static let multilineExprInput = """
        @Proto(.mock(.expr(\"\"\"
        DEBUG &&
        os(iOS)
        \"\"\")))
        final class Service {
            func work() {
            }
        }
        """

    static let interpolatedExprInput = """
        @Proto(.mock(.expr("DEBUG && \\(42)")))
        final class Service {
            func work() {
            }
        }
        """

    static let serviceExpanded = """
        final class Service {
            func work() {
            }
        }

        protocol ServiceProtocol {
            func work()
        }

        final class ServiceMock: ServiceProtocol {
            private(set) var workCallCount = 0
            var workHandler: (() -> Void)?

            init(
                workHandler: (() -> Void)? = nil
            ) {
                self.workHandler = workHandler
            }

            func work() {
                workCallCount += 1
                if let handler = workHandler {
                    handler()
                    return
                }
            }
        }
        """
}
