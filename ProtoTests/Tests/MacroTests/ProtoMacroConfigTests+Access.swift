import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

extension ProtoMacroConfigTests {
    @Test
    private func `internal class filters private and fileprivate`() {
        assertMacroExpansionTesting(
            """
            @Proto
            final class InternalService {
                func internalMethod() {
                }
                private func privateHelper() {
                }
                fileprivate func filePrivateHelper() {
                }
            }
            """,
            expandedSource: """
                final class InternalService {
                    func internalMethod() {
                    }
                    private func privateHelper() {
                    }
                    fileprivate func filePrivateHelper() {
                    }
                }

                protocol InternalServiceProtocol {
                    func internalMethod()
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `public class includes only public members`() {
        assertMacroExpansionTesting(
            """
            @Proto
            public final class PublicService {
                public func publicMethod() {
                }
                func internalMethod() {
                }
                private func privateHelper() {
                }
            }
            """,
            expandedSource: """
                public final class PublicService {
                    public func publicMethod() {
                    }
                    func internalMethod() {
                    }
                    private func privateHelper() {
                    }
                }

                public protocol PublicServiceProtocol {
                    func publicMethod()
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `scope override to package level`() {
        assertMacroExpansionTesting(
            """
            @Proto(.scope(.package))
            struct Service {
                package func packageMethod() {
                }
                func internalMethod() {
                }
                private func privateHelper() {
                }
            }
            """,
            expandedSource: """
                struct Service {
                    package func packageMethod() {
                    }
                    func internalMethod() {
                    }
                    private func privateHelper() {
                    }
                }

                package protocol ServiceProtocol {
                    func packageMethod()
                    func internalMethod()
                }
                """,
            macros: testMacros
        )
    }

    @Test
    private func `struct generates protocol with members`() {
        assertMacroExpansionTesting(
            """
            @Proto
            struct Config {
                var timeout: Int
                func validate() -> Bool {
                    return true
                }
            }
            """,
            expandedSource: """
                struct Config {
                    var timeout: Int
                    func validate() -> Bool {
                        return true
                    }
                }

                protocol ConfigProtocol {
                    var timeout: Int {
                        get
                        set
                    }
                    func validate() -> Bool
                }
                """,
            macros: testMacros
        )
    }
}
