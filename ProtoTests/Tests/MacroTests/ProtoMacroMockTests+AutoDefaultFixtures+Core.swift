extension ProtoMacroMockTests.AutoDefaultFixture {
    // MARK: - Basic: func fetch() -> UserProtocol → returns UserMock()

    static let basicFunctionInput = """
        @Proto(.mock(.auto))
        final class Service {
            func fetch() -> UserProtocol {
                fatalError()
            }
        }
        """

    static let basicFunctionExpanded = """
        final class Service {
            func fetch() -> UserProtocol {
                fatalError()
            }
        }

        protocol ServiceProtocol: Proto.Metatype {
            func fetch() -> UserProtocol
        }

        final class ServiceMock: ServiceProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var fetchCallCount = 0
            var fetchHandler: (() -> UserProtocol)?
            private var fetchReturnStub: ProtoMockReturnStub<UserProtocol> = .unset
            func fetchSetReturnValue(_ value: UserProtocol) {
                fetchReturnStub = .value(value)
            }

            init(
                fetchHandler: (() -> UserProtocol)? = nil,
                fetchReturnValue: UserProtocol? = UserMock()
            ) {
                self.fetchHandler = fetchHandler
                if let fetchReturnValue {
                    fetchReturnStub = .value(fetchReturnValue)
                }
            }

            func fetch() -> UserProtocol {
                fetchCallCount += 1
                if let handler = fetchHandler {
                    return handler()
                }
                if case .value(let value) = fetchReturnStub {
                    return value
                }
                return UserMock()
            }
        }
        """

    // MARK: - Optional: func fetch() -> UserProtocol? → returns UserMock()

    static let optionalFunctionInput = """
        @Proto(.mock(.auto))
        final class Service {
            func fetch() -> UserProtocol? {
                nil
            }
        }
        """

    static let optionalFunctionExpanded = """
        final class Service {
            func fetch() -> UserProtocol? {
                nil
            }
        }

        protocol ServiceProtocol: Proto.Metatype {
            func fetch() -> UserProtocol?
        }

        final class ServiceMock: ServiceProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var fetchCallCount = 0
            var fetchHandler: (() -> UserProtocol?)?
            private var fetchReturnStub: ProtoMockReturnStub<UserProtocol?> = .unset
            func fetchSetReturnValue(_ value: UserProtocol?) {
                fetchReturnStub = .value(value)
            }

            init(
                fetchHandler: (() -> UserProtocol?)? = nil,
                fetchReturnValue: UserProtocol?? = UserMock()
            ) {
                self.fetchHandler = fetchHandler
                if let fetchReturnValue {
                    fetchReturnStub = .value(fetchReturnValue)
                }
            }

            func fetch() -> UserProtocol? {
                fetchCallCount += 1
                if let handler = fetchHandler {
                    return handler()
                }
                if case .value(let value) = fetchReturnStub {
                    return value
                }
                return UserMock()
            }
        }
        """

    // MARK: - Array: func fetch() -> [UserProtocol] → returns [UserMock()]

    static let arrayFunctionInput = """
        @Proto(.mock(.auto))
        final class Service {
            func fetch() -> [UserProtocol] {
                []
            }
        }
        """

    static let arrayFunctionExpanded = """
        final class Service {
            func fetch() -> [UserProtocol] {
                []
            }
        }

        protocol ServiceProtocol: Proto.Metatype {
            func fetch() -> [UserProtocol]
        }

        final class ServiceMock: ServiceProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var fetchCallCount = 0
            var fetchHandler: (() -> [UserProtocol])?
            private var fetchReturnStub: ProtoMockReturnStub<[UserProtocol]> = .unset
            func fetchSetReturnValue(_ value: [UserProtocol]) {
                fetchReturnStub = .value(value)
            }

            init(
                fetchHandler: (() -> [UserProtocol])? = nil,
                fetchReturnValue: [UserProtocol]? = [UserMock()]
            ) {
                self.fetchHandler = fetchHandler
                if let fetchReturnValue {
                    fetchReturnStub = .value(fetchReturnValue)
                }
            }

            func fetch() -> [UserProtocol] {
                fetchCallCount += 1
                if let handler = fetchHandler {
                    return handler()
                }
                if case .value(let value) = fetchReturnStub {
                    return value
                }
                return [UserMock()]
            }
        }
        """

    // MARK: - Non-matching: func fetch() -> String → still calls fail()

    static let nonMatchingFunctionInput = """
        @Proto(.mock(.auto))
        final class Service {
            func fetch() -> String {
                ""
            }
        }
        """

    static let nonMatchingFunctionExpanded = """
        final class Service {
            func fetch() -> String {
                ""
            }
        }

        protocol ServiceProtocol: Proto.Metatype {
            func fetch() -> String
        }

        final class ServiceMock: ServiceProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var fetchCallCount = 0
            var fetchHandler: (() -> String)?
            private var fetchReturnStub: ProtoMockReturnStub<String> = .unset
            func fetchSetReturnValue(_ value: String) {
                fetchReturnStub = .value(value)
            }

            init(
                fetchHandler: (() -> String)? = nil,
                fetchReturnValue: String? = nil
            ) {
                self.fetchHandler = fetchHandler
                if let fetchReturnValue {
                    fetchReturnStub = .value(fetchReturnValue)
                }
            }

            func fetch() -> String {
                fetchCallCount += 1
                if let handler = fetchHandler {
                    return handler()
                }
                if case .value(let value) = fetchReturnStub {
                    return value
                }
                ProtoMockFailureHandling.fail("Unstubbed call to fetch on ServiceMock")
            }
        }
        """

    // MARK: - Void function: unchanged behavior

    static let voidFunctionInput = """
        @Proto(.mock(.auto))
        final class Service {
            func ping() {
            }
        }
        """

    static let voidFunctionExpanded = """
        final class Service {
            func ping() {
            }
        }

        protocol ServiceProtocol: Proto.Metatype {
            func ping()
        }

        final class ServiceMock: ServiceProtocol {
            private(set) var pingCallCount = 0
            var pingHandler: (() -> Void)?

            init(
                pingHandler: (() -> Void)? = nil
            ) {
                self.pingHandler = pingHandler
            }

            func ping() {
                pingCallCount += 1
                if let handler = pingHandler {
                    handler()
                    return
                }
            }
        }
        """

    // MARK: - Property: var user: UserProtocol → getter returns UserMock()

    static let propertyInput = """
        @Proto(.mock(.auto))
        final class Service {
            var user: UserProtocol {
                get { fatalError() }
            }
        }
        """

    static let propertyExpanded = """
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
            var user: UserProtocol {
                get {
                    return UserMock()
                }
            }
        }
        """

    // MARK: - Subscript: subscript(...) -> UserProtocol → getter returns UserMock()

    static let subscriptInput = """
        @Proto(.mock(.auto))
        final class Service {
            subscript(key: String) -> UserProtocol {
                get { fatalError() }
            }
        }
        """

    static let subscriptExpanded = """
        final class Service {
            subscript(key: String) -> UserProtocol {
                get { fatalError() }
            }
        }

        protocol ServiceProtocol: Proto.Metatype {
            subscript(key: String) -> UserProtocol {
                get
            }
        }

        final class ServiceMock: ServiceProtocol {
            subscript(key: String) -> UserProtocol {
                get {
                    return UserMock()
                }
            }
        }
        """
}
