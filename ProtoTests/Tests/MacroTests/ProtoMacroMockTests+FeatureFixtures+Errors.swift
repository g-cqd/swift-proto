extension ProtoMacroMockTests.FeatureFixture {
    static let typedThrowsInput = """
        @Proto(.mock)
        final class Loader {
            func load() throws(LoadError) -> String {
                ""
            }
        }
        """

    static let typedThrowsExpanded = """
        final class Loader {
            func load() throws(LoadError) -> String {
                ""
            }
        }

        protocol LoaderProtocol {
            func load() throws(LoadError) -> String
        }

        final class LoaderMock: LoaderProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var loadCallCount = 0
            var loadHandler: (() throws(LoadError) -> String)?
            var loadError: (LoadError)?
            private var loadReturnStub: ProtoMockReturnStub<String> = .unset
            func loadSetReturnValue(_ value: String) {
                loadReturnStub = .value(value)
            }

            init(
                loadHandler: (() throws(LoadError) -> String)? = nil,
                loadError: (LoadError)? = nil,
                loadReturnValue: String? = nil
            ) {
                self.loadHandler = loadHandler
                self.loadError = loadError
                if let loadReturnValue {
                    loadReturnStub = .value(loadReturnValue)
                }
            }

            func load() throws(LoadError) -> String {
                loadCallCount += 1
                if let handler = loadHandler {
                    return try handler()
                }
                if let error = loadError {
                    throw error
                }
                if case .value(let value) = loadReturnStub {
                    return value
                }
                ProtoMockFailureHandling.fail("Unstubbed call to load on LoaderMock")
            }
        }
        """
}

extension ProtoMacroMockTests.FeatureFixture {
    static let rethrowsInput = """
        @Proto(.mock)
        final class Processor {
            func process(_ transform: (String) throws -> String) rethrows -> String {
                try transform("")
            }
        }
        """

    static let rethrowsExpanded = """
        final class Processor {
            func process(_ transform: (String) throws -> String) rethrows -> String {
                try transform("")
            }
        }

        protocol ProcessorProtocol {
            func process(_ transform: (String) throws -> String) rethrows -> String
        }

        final class ProcessorMock: ProcessorProtocol {
            private enum ProtoMockReturnStub<Value> {
                case unset
                case value(Value)
            }

            private(set) var processCallCount = 0
            private(set) var processReceivedArguments: [(String) throws -> String] = []
            var processHandler: (((String) throws -> String) throws -> String)?
            private var processReturnStub: ProtoMockReturnStub<String> = .unset
            func processSetReturnValue(_ value: String) {
                processReturnStub = .value(value)
            }

            init(
                processHandler: (((String) throws -> String) throws -> String)? = nil,
                processReturnValue: String? = nil
            ) {
                self.processHandler = processHandler
                if let processReturnValue {
                    processReturnStub = .value(processReturnValue)
                }
            }

            func process(_ transform: (String) throws -> String) rethrows -> String {
                processCallCount += 1
                processReceivedArguments.append(transform)
                if let handler = processHandler {
                    return try handler(transform)
                }
                if case .value(let value) = processReturnStub {
                    return value
                }
                ProtoMockFailureHandling.fail("Unstubbed call to process on ProcessorMock")
            }
        }
        """
}
