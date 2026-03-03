extension ProtoMacroMockTests {
    enum FeatureFixture {}
}

extension ProtoMacroMockTests.FeatureFixture {
    static let sendableShorthandInput = """
        @Proto(.mock, .sendable)
        final class Service {
            func work() {
            }
        }
        """

    static let sendableInput = """
        @Proto(.mock, .conforms(to: Sendable.self))
        final class Service {
            func work() {
            }
        }
        """

    static let sendableExpanded = """
        final class Service {
            func work() {
            }
        }

        protocol ServiceProtocol: Sendable {
            func work()
        }

        final class ServiceMock: @unchecked Sendable, ServiceProtocol {
            private let _protoMockLock = ProtoMockSynchronizationLock()

            var workCallCount: Int {
                _protoMockLock.withLock {
                    _workCallCount
                }
            }
            private var _workCallCount = 0
            var workHandler: (() -> Void)? {
                get {
                    _protoMockLock.withLock {
                        _workHandler
                    }
                }
                set {
                    _protoMockLock.withLock {
                        _workHandler = newValue
                    }
                }
            }
            private var _workHandler: (() -> Void)?

            init(
                workHandler: (() -> Void)? = nil
            ) {
                self.workHandler = workHandler
            }

            func work() {
                _protoMockLock.withLock {
                    _workCallCount += 1
                }
                let handler = _protoMockLock.withLock {
                    _workHandler
                }
                if let handler = handler {
                    handler()
                    return
                }
            }
        }
        """
}

extension ProtoMacroMockTests.FeatureFixture {
    static let staticSendableInput = """
        @Proto(.mock, .include(.static), .conforms(to: Sendable.self))
        final class Counter {
            static func tick() {
            }
        }
        """

    static let staticSendableExpanded = """
        final class Counter {
            static func tick() {
            }
        }

        protocol CounterProtocol: Sendable {
            static func tick()
        }

        final class CounterMock: @unchecked Sendable, CounterProtocol {
            private static let _protoMockStaticLock = ProtoMockSynchronizationLock()

            static var tickCallCount: Int {
                Self._protoMockStaticLock.withLock {
                    _tickCallCount
                }
            }
            private static var _tickCallCount = 0
            static var tickHandler: (() -> Void)? {
                get {
                    Self._protoMockStaticLock.withLock {
                        _tickHandler
                    }
                }
                set {
                    Self._protoMockStaticLock.withLock {
                        _tickHandler = newValue
                    }
                }
            }
            private static var _tickHandler: (() -> Void)?

            static func tick() {
                Self._protoMockStaticLock.withLock {
                    _tickCallCount += 1
                }
                let handler = Self._protoMockStaticLock.withLock {
                    _tickHandler
                }
                if let handler = handler {
                    handler()
                    return
                }
            }
        }
        """
}

extension ProtoMacroMockTests.FeatureFixture {
    static let staticInput = """
        @Proto(.mock, .include(.static))
        final class Factory {
            static func create() -> String {
                ""
            }

            func process() -> String {
                ""
            }
        }
        """

    static let staticExpanded = """
        final class Factory {
            static func create() -> String {
                ""
            }

            func process() -> String {
                ""
            }
        }

        protocol FactoryProtocol {
            static func create() -> String
            func process() -> String
        }

        final class FactoryMock: FactoryProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            static private(set) var createCallCount = 0
            static var createHandler: (() -> String)?
            private static var createReturnStub: ProtoMockReturnStub<String> = .unset
            static func createSetReturnValue(_ value: String) {
                createReturnStub = .value(value)
            }
            private(set) var processCallCount = 0
            var processHandler: (() -> String)?
            private var processReturnStub: ProtoMockReturnStub<String> = .unset
            func processSetReturnValue(_ value: String) {
                processReturnStub = .value(value)
            }

            init(
                processHandler: (() -> String)? = nil,
                processReturnValue: String? = nil
            ) {
                self.processHandler = processHandler
                if let processReturnValue {
                    processReturnStub = .value(processReturnValue)
                }
            }

            static func create() -> String {
                createCallCount += 1
                if let handler = createHandler {
                    return handler()
                }
                if case .value(let value) = createReturnStub {
                    return value
                }
                ProtoMockFailureHandling.fail("Unstubbed call to create on FactoryMock")
            }
            func process() -> String {
                processCallCount += 1
                if let handler = processHandler {
                    return handler()
                }
                if case .value(let value) = processReturnStub {
                    return value
                }
                ProtoMockFailureHandling.fail("Unstubbed call to process on FactoryMock")
            }
        }
        """
}
