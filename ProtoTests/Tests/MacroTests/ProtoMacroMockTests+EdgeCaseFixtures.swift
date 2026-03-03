extension ProtoMacroMockTests {
    enum EdgeCaseFixture {
        static let enumStaticInput = """
            @Proto(.mock, .include(.static))
            enum Theme {
                case light
                case dark

                static func system() -> Self {
                    .light
                }

                var name: String {
                    switch self {
                    case .light: "light"
                    case .dark: "dark"
                    }
                }
            }
            """

        static let enumStaticExpanded = """
            enum Theme {
                case light
                case dark

                static func system() -> Self {
                    .light
                }

                var name: String {
                    switch self {
                    case .light: "light"
                    case .dark: "dark"
                    }
                }
            }

            protocol ThemeProtocol {
                static func system() -> Self
                var name: String {
                    get
                }
            }

            final class ThemeMock: ThemeProtocol {
                private enum ProtoMockReturnStub<Value> {
                    case unset
                    case value(Value)
                }

                static private(set) var systemCallCount = 0
                static var systemHandler: (() -> Self)?
                private static var systemReturnStub: ProtoMockReturnStub<Self> = .unset
                static func systemSetReturnValue(_ value: Self) {
                    systemReturnStub = .value(value)
                }

                static func system() -> Self {
                    systemCallCount += 1
                    if let handler = systemHandler {
                        return handler()
                    }
                    if case .value(let value) = systemReturnStub {
                        return value
                    }
                    ProtoMockFailureHandling.fail("Unstubbed call to system on ThemeMock")
                }
                var name: String {
                    get {
                        ProtoMockFailureHandling.fail("Unstubbed property 'name' on ThemeMock")
                    }
                }
            }
            """
        static let privateSetInput = """
            @Proto(.mock)
            public final class Counter {
                public private(set) var value: Int = 0

                public func increment() {
                }
            }
            """

        static let privateSetExpanded = """
            public final class Counter {
                public private(set) var value: Int = 0

                public func increment() {
                }
            }

            public protocol CounterProtocol {
                var value: Int {
                    get
                }
                func increment()
            }

            public final class CounterMock: CounterProtocol {
                public private(set) var incrementCallCount = 0
                public var incrementHandler: (() -> Void)?

                public init(
                    incrementHandler: (() -> Void)? = nil
                ) {
                    self.incrementHandler = incrementHandler
                }

                public var value: Int {
                    get {
                        ProtoMockFailureHandling.fail("Unstubbed property 'value' on CounterMock")
                    }
                }
                public func increment() {
                    incrementCallCount += 1
                    if let handler = incrementHandler {
                        handler()
                        return
                    }
                }
            }
            """
    }
}
