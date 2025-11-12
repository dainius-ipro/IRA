// StoredSession.swift
import Foundation
import SwiftData

@Model
final class StoredSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var vehicle: String?
    var racer: String?
    var track: String?
    var championship: String?
    var session: String?
    
    @Relationship(deleteRule: .cascade)
    var laps: [StoredLap]
    
    init(
        id: UUID = UUID(),
        date: Date,
        vehicle: String? = nil,
        racer: String? = nil,
        track: String? = nil,
        championship: String? = nil,
        session: String? = nil,
        laps: [StoredLap] = []
    ) {
        self.id = id
        self.date = date
        self.vehicle = vehicle
        self.racer = racer
        self.track = track
        self.championship = championship
        self.session = session
        self.laps = laps
    }
    
    // Convenience initializer from Session
    convenience init(from session: Session) {
        self.init(
            id: session.id,
            date: session.date,
            vehicle: session.vehicle,
            racer: session.racer,
            track: session.track,
            championship: session.championship,
            session: session.session
        )
        self.laps = session.laps.map { StoredLap.fromLap($0) }
    }
    
    // Convert from Session model (static method)
    static func fromSession(_ session: Session) -> StoredSession {
        let storedSession = StoredSession(
            id: session.id,
            date: session.date,
            vehicle: session.vehicle,
            racer: session.racer,
            track: session.track,
            championship: session.championship,
            session: session.session
        )
        
        storedSession.laps = session.laps.map { StoredLap.fromLap($0) }
        
        return storedSession
    }
    
    // Convert to Session model
    func toSession() -> Session {
        Session(
            id: id,
            date: date,
            vehicle: vehicle,  // ✅ Correct order!
            racer: racer,
            track: track,
            championship: championship,
            session: session,
            laps: laps.map { $0.toLap() }
        )
    }
}
