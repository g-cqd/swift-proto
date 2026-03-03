import Foundation

public enum IncidentSeverity: String, Sendable {
    case low
    case medium
    case high
    case critical
}

public struct SecurityIncident: Sendable {
    public let id: String
    public let title: String
    public let severity: IncidentSeverity
    public let reportedAt: Date

    public init(id: String, title: String, severity: IncidentSeverity, reportedAt: Date) {
        self.id = id
        self.title = title
        self.severity = severity
        self.reportedAt = reportedAt
    }
}

public struct MitigationSummary: Sendable {
    public let incidentID: String
    public let pagerChannel: String
    public let escalationAccepted: Bool
    public let executedSteps: [String]
    public let responderHandle: String?

    public init(
        incidentID: String,
        pagerChannel: String,
        escalationAccepted: Bool,
        executedSteps: [String],
        responderHandle: String?
    ) {
        self.incidentID = incidentID
        self.pagerChannel = pagerChannel
        self.escalationAccepted = escalationAccepted
        self.executedSteps = executedSteps
        self.responderHandle = responderHandle
    }
}
