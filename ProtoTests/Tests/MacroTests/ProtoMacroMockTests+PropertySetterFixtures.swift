extension ProtoMacroMockTests {
    enum PropertySetterFixture {}
}

// MARK: - Basic: get-only property generates backing storage + setter method

extension ProtoMacroMockTests.PropertySetterFixture {
    static let basicInput = """
        @Proto(.mock)
        final class Store {
            var name: String {
                get { "" }
            }
        }
        """

    static let basicExpanded = """
        final class Store {
            var name: String {
                get { "" }
            }
        }

        protocol StoreProtocol {
            var name: String {
                get
            }
        }

        final class StoreMock: StoreProtocol {
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
        }
        """
}

// MARK: - noPropertySetters: get-only property uses failure stub only

extension ProtoMacroMockTests.PropertySetterFixture {
    static let noSettersInput = """
        @Proto(.mock(.noPropertySetters))
        final class Store {
            var name: String {
                get { "" }
            }
        }
        """

    static let noSettersExpanded = """
        final class Store {
            var name: String {
                get { "" }
            }
        }

        protocol StoreProtocol {
            var name: String {
                get
            }
        }

        final class StoreMock: StoreProtocol {
            var name: String {
                get {
                    ProtoMockFailureHandling.fail("Unstubbed property 'name' on StoreMock")
                }
            }
        }
        """
}

// MARK: - Async getter: setter method is async

extension ProtoMacroMockTests.PropertySetterFixture {
    static let asyncGetterInput = """
        @Proto(.mock)
        final class Store {
            var data: String {
                get async { "" }
            }
        }
        """

    static let asyncGetterExpanded = """
        final class Store {
            var data: String {
                get async { "" }
            }
        }

        protocol StoreProtocol {
            var data: String {
                get async
            }
        }

        final class StoreMock: StoreProtocol {
            private var _dataValue: String?
            var data: String {
                get async {
                    guard let value = _dataValue else {
                        ProtoMockFailureHandling.fail("Unstubbed property 'data' on StoreMock")
                    }
                    return value
                }
            }
            func setData(_ value: String) async {
                _dataValue = value
            }
        }
        """
}

// MARK: - Property with setter in protocol: no backing storage or setter method

extension ProtoMacroMockTests.PropertySetterFixture {
    static let mutablePropertyInput = """
        @Proto(.mock)
        final class Config {
            var name: String = ""
        }
        """

    static let mutablePropertyExpanded = """
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

// MARK: - Auto-default with backing storage

extension ProtoMacroMockTests.PropertySetterFixture {
    static let autoDefaultInput = """
        @Proto(.mock(.auto))
        final class Service {
            var user: UserProtocol {
                get { fatalError() }
            }
        }
        """

    static let autoDefaultExpanded = """
        final class Service {
            var user: UserProtocol {
                get { fatalError() }
            }
        }

        protocol ServiceProtocol: Proto.Metatype {
            var user: UserProtocol {
                get
            }
        }

        final class ServiceMock: ServiceProtocol {
            private var _userValue: UserProtocol = UserMock()
            var user: UserProtocol {
                get {
                    _userValue
                }
            }
            func setUser(_ value: UserProtocol) {
                _userValue = value
            }
        }
        """
}

// MARK: - Public visibility: setter method gets public modifier

extension ProtoMacroMockTests.PropertySetterFixture {
    static let publicVisibilityInput = """
        @Proto(.mock)
        public final class Store {
            public var name: String {
                get { "" }
            }
        }
        """

    static let publicVisibilityExpanded = """
        public final class Store {
            public var name: String {
                get { "" }
            }
        }

        public protocol StoreProtocol {
            var name: String {
                get
            }
        }

        public final class StoreMock: StoreProtocol {
            private var _nameValue: String?
            public var name: String {
                get {
                    guard let value = _nameValue else {
                        ProtoMockFailureHandling.fail("Unstubbed property 'name' on StoreMock")
                    }
                    return value
                }
            }
            public func setName(_ value: String) {
                _nameValue = value
            }
        }
        """
}
