extension ProtoMacroMockTests {
    enum MockOptionFixture {
        static let mockDebugInput = """
            @Proto(.mock(.debug))
            final class Service {
                func fetch() -> String {
                    ""
                }
            }
            """

        static let mockDebugExpanded = """
            final class Service {
                func fetch() -> String {
                    ""
                }
            }

            protocol ServiceProtocol {
                func fetch() -> String
            }

            #if DEBUG
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
            #endif
            """

        static let mockCustomFlagInput = """
            @Proto(.mock(.custom("TESTING")))
            final class Service {
                func fetch() -> String {
                    ""
                }
            }
            """

        static let mockCustomFlagExpanded = """
            final class Service {
                func fetch() -> String {
                    ""
                }
            }

            protocol ServiceProtocol {
                func fetch() -> String
            }

            #if TESTING
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
            #endif
            """

        static let mockExprInput = """
            @Proto(.mock(.expr("DEBUG && os(iOS)")))
            final class Service {
                func fetch() -> String {
                    ""
                }
            }
            """

        static let mockExprExpanded = """
            final class Service {
                func fetch() -> String {
                    ""
                }
            }

            protocol ServiceProtocol {
                func fetch() -> String
            }

            #if DEBUG && os(iOS)
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
            #endif
            """

        static let mockScopeInput = """
            @Proto(.mock(.scope(.package)))
            final class Service {
                func fetch() -> String {
                    ""
                }
            }
            """

        static let mockScopeExpanded = """
            final class Service {
                func fetch() -> String {
                    ""
                }
            }

            protocol ServiceProtocol {
                func fetch() -> String
            }

            package final class ServiceMock: ServiceProtocol {
                private enum ProtoMockReturnStub<Value> {
                    case unset
                    case value(Value)
                }

                package private(set) var fetchCallCount = 0
                package var fetchHandler: (() -> String)?
                private var fetchReturnStub: ProtoMockReturnStub<String> = .unset
                package func fetchSetReturnValue(_ value: String) {
                    fetchReturnStub = .value(value)
                }

                package init(
                    fetchHandler: (() -> String)? = nil,
                    fetchReturnValue: String? = nil
                ) {
                    self.fetchHandler = fetchHandler
                    if let fetchReturnValue {
                        fetchReturnStub = .value(fetchReturnValue)
                    }
                }

                package func fetch() -> String {
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
    }
}

extension ProtoMacroMockTests.MockOptionFixture {
    static let mockMultipleConditionsInput = """
        @Proto(.mock(.debug, .release, .custom("X")))
        final class Service {
            func fetch() -> String {
                ""
            }
        }
        """

    static let mockMultipleConditionsExpanded = """
        final class Service {
            func fetch() -> String {
                ""
            }
        }

        protocol ServiceProtocol {
            func fetch() -> String
        }

        #if DEBUG || RELEASE || X
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
        #endif
        """

    static let mockDebugWithScopeInput = """
        @Proto(.mock(.debug, .scope(.package)))
        final class Service {
            func fetch() -> String {
                ""
            }
        }
        """

    static let mockDebugWithScopeExpanded = """
        final class Service {
            func fetch() -> String {
                ""
            }
        }

        protocol ServiceProtocol {
            func fetch() -> String
        }

        #if DEBUG
        package final class ServiceMock: ServiceProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            package private(set) var fetchCallCount = 0
            package var fetchHandler: (() -> String)?
            private var fetchReturnStub: ProtoMockReturnStub<String> = .unset
            package func fetchSetReturnValue(_ value: String) {
                fetchReturnStub = .value(value)
            }

            package init(
                fetchHandler: (() -> String)? = nil,
                fetchReturnValue: String? = nil
            ) {
                self.fetchHandler = fetchHandler
                if let fetchReturnValue {
                    fetchReturnStub = .value(fetchReturnValue)
                }
            }

            package func fetch() -> String {
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
        #endif
        """
}
