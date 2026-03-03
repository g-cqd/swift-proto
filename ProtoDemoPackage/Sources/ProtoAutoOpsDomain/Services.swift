import Proto

@Proto(.mock)
public final class PagerChannel: PagerChannelProtocol {
    public let channelName: String

    public init(channelName: String = "primary-pager") {
        self.channelName = channelName
    }

    public func notify(_ message: String) async {}
}

@Proto(.mock)
public final class Playbook: PlaybookProtocol {
    public let id: String
    public let steps: [String]

    public init(id: String = "containment", steps: [String] = ["Collect indicators"]) {
        self.id = id
        self.steps = steps
    }

    public func run(for incident: SecurityIncident) async -> [String] {
        steps
    }
}

@Proto(.mock)
public final class Responder: ResponderProtocol {
    public let handle: String

    public init(handle: String = "sec-oncall") {
        self.handle = handle
    }

    public func acknowledge(incidentID: String) async -> Bool {
        true
    }
}

@Proto(.mock(.auto))
public final class IncidentResourceDirectory: IncidentResourceDirectoryProtocol {
    private let responder: Responder?
    private let playbooks: [Playbook]
    private let primaryPager: PagerChannel
    private let secondaryPager: PagerChannel

    public init(
        responder: Responder? = Responder(),
        playbooks: [Playbook] = [Playbook()],
        primaryPager: PagerChannel = PagerChannel(channelName: "primary-pager"),
        secondaryPager: PagerChannel = PagerChannel(channelName: "secondary-pager")
    ) {
        self.responder = responder
        self.playbooks = playbooks
        self.primaryPager = primaryPager
        self.secondaryPager = secondaryPager
    }

    public func escalationResponder() -> ResponderProtocol? {
        responder
    }

    public func activePlaybooks() -> [PlaybookProtocol] {
        playbooks
    }

    public func defaultPager() -> PagerChannelProtocol {
        primaryPager
    }

    public var backupPager: PagerChannelProtocol {
        secondaryPager
    }
}
