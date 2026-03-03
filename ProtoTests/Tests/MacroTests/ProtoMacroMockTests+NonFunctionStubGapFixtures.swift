extension ProtoMacroMockTests {
    enum NonFunctionStubGapFixture {}
}

// MARK: - Mock property with get/set (NonFunctionStubs lines 152-156)

extension ProtoMacroMockTests.NonFunctionStubGapFixture {
    static let storedPropertyMockInput = """
        @Proto(.mock)
        final class Config {
            var name: String = ""
        }
        """

    static let storedPropertyMockExpanded = """
        final class Config {
            var name: String = ""
        }

        protocol ConfigProtocol {
            var name: String {
                get
                set
            }
        }

        final class ConfigMock: ConfigProtocol {
            var name: String {
                get {
                    ProtoMockFailureHandling.fail("Unstubbed property 'name' on ConfigMock")
                }
                set {
                }
            }
        }
        """
}

// MARK: - Auto-default property with getter and setter (NonFunctionStubs lines 169-195)

extension ProtoMacroMockTests.NonFunctionStubGapFixture {
    static let autoDefaultMutablePropertyInput = """
        @Proto(.mock(.auto))
        final class Registry {
            var current: UserProtocol {
                get { fatalError() }
                set {}
            }
        }
        """

    static let autoDefaultMutablePropertyExpanded = """
        final class Registry {
            var current: UserProtocol {
                get { fatalError() }
                set {}
            }
        }

        protocol RegistryProtocol: Proto.Metatype {
            var current: UserProtocol {
                get
                set
            }
        }

        final class RegistryMock: RegistryProtocol {
            var current: UserProtocol {
                get {
                    return UserMock()
                }
                set {
                }
            }
        }
        """
}
