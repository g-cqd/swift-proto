extension ProtoMacroMockTests {
    enum StubFixture {
        static let propertyStubInput = """
            @Proto(.mock)
            final class Store {
                var name: String {
                    get { "" }
                }
                var count: Int {
                    get { 0 }
                    set { }
                }
            }
            """

        static let propertyStubExpanded = """
            final class Store {
                var name: String {
                    get { "" }
                }
                var count: Int {
                    get { 0 }
                    set { }
                }
            }

            protocol StoreProtocol {
                var name: String {
                    get
                }
                var count: Int {
                    get
                    set
                }
            }

            final class StoreMock: StoreProtocol {
                var name: String {
                    get {
                        ProtoMockFailureHandling.fail("Unstubbed property 'name' on StoreMock")
                    }
                }
                var count: Int {
                    get {
                        ProtoMockFailureHandling.fail("Unstubbed property 'count' on StoreMock")
                    }
                    set {
                    }
                }
            }
            """

        static let subscriptStubInput = """
            @Proto(.mock)
            final class Table {
                subscript(key: String) -> Int? {
                    get { nil }
                    set { }
                }
            }
            """

        static let subscriptStubExpanded = """
            final class Table {
                subscript(key: String) -> Int? {
                    get { nil }
                    set { }
                }
            }

            protocol TableProtocol {
                subscript(key: String) -> Int? {
                    get
                    set
                }
            }

            final class TableMock: TableProtocol {
                subscript(key: String) -> Int? {
                    get {
                        ProtoMockFailureHandling.fail("Unstubbed subscript on TableMock")
                    }
                    set {
                    }
                }
            }
            """

        static let initializerStubInput = """
            @Proto(.mock, .include(.initializer))
            final class Builder {
                init(name: String) {
                }

                func build() -> String {
                    ""
                }
            }
            """

        static let initializerStubExpanded = """
            final class Builder {
                init(name: String) {
                }

                func build() -> String {
                    ""
                }
            }

            protocol BuilderProtocol {
                init(name: String)
                func build() -> String
            }

            final class BuilderMock: BuilderProtocol {
                private enum ProtoMockReturnStub<Value> {
                    case unset
                    case value(Value)
                }

                private(set) var buildCallCount = 0
                var buildHandler: (() -> String)?
                private var buildReturnStub: ProtoMockReturnStub<String> = .unset
                func buildSetReturnValue(_ value: String) {
                    buildReturnStub = .value(value)
                }

                init(
                    buildHandler: (() -> String)? = nil,
                    buildReturnValue: String? = nil
                ) {
                    self.buildHandler = buildHandler
                    if let buildReturnValue {
                        buildReturnStub = .value(buildReturnValue)
                    }
                }

                init(name: String) {
                    ProtoMockFailureHandling.fail("Unstubbed initializer on BuilderMock")
                }
                func build() -> String {
                    buildCallCount += 1
                    if let handler = buildHandler {
                        return handler()
                    }
                    if case .value(let value) = buildReturnStub {
                        return value
                    }
                    ProtoMockFailureHandling.fail("Unstubbed call to build on BuilderMock")
                }
            }
            """

        static let overloadedInput = """
            @Proto(.mock)
            final class API {
                func fetch(by id: String) -> String {
                    ""
                }

                func fetch(all flag: Bool) -> [String] {
                    []
                }
            }
            """

        static let overloadedExpanded = """
            final class API {
                func fetch(by id: String) -> String {
                    ""
                }

                func fetch(all flag: Bool) -> [String] {
                    []
                }
            }

            protocol APIProtocol {
                func fetch(by id: String) -> String
                func fetch(all flag: Bool) -> [String]
            }

            final class APIMock: APIProtocol {
                private enum ProtoMockReturnStub<Value> {
                    case unset
                    case value(Value)
                }

                private(set) var fetchCallCount = 0
                private(set) var fetchReceivedArguments: [String] = []
                var fetchHandler: ((String) -> String)?
                private var fetchReturnStub: ProtoMockReturnStub<String> = .unset
                func fetchSetReturnValue(_ value: String) {
                    fetchReturnStub = .value(value)
                }
                private(set) var fetch2CallCount = 0
                private(set) var fetch2ReceivedArguments: [Bool] = []
                var fetch2Handler: ((Bool) -> [String])?
                private var fetch2ReturnStub: ProtoMockReturnStub<[String]> = .unset
                func fetch2SetReturnValue(_ value: [String]) {
                    fetch2ReturnStub = .value(value)
                }

                init(
                    fetchHandler: ((String) -> String)? = nil,
                    fetchReturnValue: String? = nil,
                    fetch2Handler: ((Bool) -> [String])? = nil,
                    fetch2ReturnValue: [String]? = nil
                ) {
                    self.fetchHandler = fetchHandler
                    if let fetchReturnValue {
                        fetchReturnStub = .value(fetchReturnValue)
                    }
                    self.fetch2Handler = fetch2Handler
                    if let fetch2ReturnValue {
                        fetch2ReturnStub = .value(fetch2ReturnValue)
                    }
                }

                func fetch(by id: String) -> String {
                    fetchCallCount += 1
                    fetchReceivedArguments.append(id)
                    if let handler = fetchHandler {
                        return handler(id)
                    }
                    if case .value(let value) = fetchReturnStub {
                        return value
                    }
                    ProtoMockFailureHandling.fail("Unstubbed call to fetch on APIMock")
                }
                func fetch(all flag: Bool) -> [String] {
                    fetch2CallCount += 1
                    fetch2ReceivedArguments.append(flag)
                    if let handler = fetch2Handler {
                        return handler(flag)
                    }
                    if case .value(let value) = fetch2ReturnStub {
                        return value
                    }
                    ProtoMockFailureHandling.fail("Unstubbed call to fetch2 on APIMock")
                }
            }
            """
    }
}
