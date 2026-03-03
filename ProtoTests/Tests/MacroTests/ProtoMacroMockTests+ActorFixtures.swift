extension ProtoMacroMockTests {
    enum ActorFixture {}
}

// MARK: - Actor with generic parameters

extension ProtoMacroMockTests.ActorFixture {
    static let actorGenericInput = """
        @Proto
        actor Storage<Key: Hashable, Value> {
            func get(key: Key) -> Value? {
                nil
            }

            func set(key: Key, value: Value) {
            }
        }
        """

    static let actorGenericExpanded = """
        actor Storage<Key: Hashable, Value> {
            func get(key: Key) -> Value? {
                nil
            }

            func set(key: Key, value: Value) {
            }
        }

        protocol StorageProtocol: Actor {
            associatedtype Key: Hashable
            associatedtype Value
            func get(key: Key) async -> Value?
            func set(key: Key, value: Value) async
        }
        """
}

// MARK: - Actor mock with noIsolation

extension ProtoMacroMockTests.ActorFixture {
    static let actorMockNoIsolationInput = """
        @Proto(.mock, .noIsolation)
        actor Worker {
            func execute(task: String) {
            }
        }
        """

    static let actorMockNoIsolationExpanded = """
        actor Worker {
            func execute(task: String) {
            }
        }

        protocol WorkerProtocol {
            func execute(task: String)
        }

        final class WorkerMock: WorkerProtocol {
            private(set) var executeCallCount = 0
            private(set) var executeReceivedArguments: [String] = []
            var executeHandler: ((String) -> Void)?

            init(
                executeHandler: ((String) -> Void)? = nil
            ) {
                self.executeHandler = executeHandler
            }

            func execute(task: String) {
                executeCallCount += 1
                executeReceivedArguments.append(task)
                if let handler = executeHandler {
                    handler(task)
                    return
                }
            }
        }
        """
}
