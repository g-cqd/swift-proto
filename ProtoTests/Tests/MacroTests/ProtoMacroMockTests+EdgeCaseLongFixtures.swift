extension ProtoMacroMockTests.EdgeCaseFixture {
    static let backtickIdentifierInput = """
        @Proto(.mock)
        final class Router {
            func `default`() -> String {
                ""
            }
        }
        """

    static let backtickIdentifierExpanded = """
        final class Router {
            func `default`() -> String {
                ""
            }
        }

        protocol RouterProtocol {
            func `default`() -> String
        }

        final class RouterMock: RouterProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var defaultCallCount = 0
            var defaultHandler: (() -> String)?
            private var defaultReturnStub: ProtoMockReturnStub<String> = .unset
            func defaultSetReturnValue(_ value: String) {
                defaultReturnStub = .value(value)
            }

            init(
                defaultHandler: (() -> String)? = nil,
                defaultReturnValue: String? = nil
            ) {
                self.defaultHandler = defaultHandler
                if let defaultReturnValue {
                    defaultReturnStub = .value(defaultReturnValue)
                }
            }

            func `default`() -> String {
                defaultCallCount += 1
                if let handler = defaultHandler {
                    return handler()
                }
                if case .value(let value) = defaultReturnStub {
                    return value
                }
                ProtoMockFailureHandling.fail("Unstubbed call to default on RouterMock")
            }
        }
        """

    static let genericFunctionInput = """
        @Proto(.mock)
        final class Converter {
            func convert<T>(value: String) -> T {
                preconditionFailure()
            }
        }
        """

    static let genericFunctionExpanded = """
        final class Converter {
            func convert<T>(value: String) -> T {
                preconditionFailure()
            }
        }

        protocol ConverterProtocol {
            func convert<T>(value: String) -> T
        }

        final class ConverterMock: ConverterProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var convertCallCount = 0
            private(set) var convertReceivedArguments: [String] = []
            var convertHandler: ((String) -> T)?
            private var convertReturnStub: ProtoMockReturnStub<T> = .unset
            func convertSetReturnValue(_ value: T) {
                convertReturnStub = .value(value)
            }

            init(
                convertHandler: ((String) -> T)? = nil,
                convertReturnValue: T? = nil
            ) {
                self.convertHandler = convertHandler
                if let convertReturnValue {
                    convertReturnStub = .value(convertReturnValue)
                }
            }

            func convert<T>(value: String) -> T {
                convertCallCount += 1
                convertReceivedArguments.append(value)
                if let handler = convertHandler {
                    return handler(value)
                }
                if case .value(let value) = convertReturnStub {
                    return value
                }
                ProtoMockFailureHandling.fail("Unstubbed call to convert on ConverterMock")
            }
        }
        """

    static let unnamedParametersInput = """
        @Proto(.mock)
        final class Adder {
            func add(_ a: Int, _ b: Int) -> Int {
                a + b
            }
        }
        """

    static let unnamedParametersExpanded = """
        final class Adder {
            func add(_ a: Int, _ b: Int) -> Int {
                a + b
            }
        }

        protocol AdderProtocol {
            func add(_ a: Int, _ b: Int) -> Int
        }

        final class AdderMock: AdderProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var addCallCount = 0
            private(set) var addReceivedArguments: [(Int, Int)] = []
            var addHandler: ((Int, Int) -> Int)?
            private var addReturnStub: ProtoMockReturnStub<Int> = .unset
            func addSetReturnValue(_ value: Int) {
                addReturnStub = .value(value)
            }

            init(
                addHandler: ((Int, Int) -> Int)? = nil,
                addReturnValue: Int? = nil
            ) {
                self.addHandler = addHandler
                if let addReturnValue {
                    addReturnStub = .value(addReturnValue)
                }
            }

            func add(_ a: Int, _ b: Int) -> Int {
                addCallCount += 1
                addReceivedArguments.append((a, b))
                if let handler = addHandler {
                    return handler(a, b)
                }
                if case .value(let value) = addReturnStub {
                    return value
                }
                ProtoMockFailureHandling.fail("Unstubbed call to add on AdderMock")
            }
        }
        """
}
