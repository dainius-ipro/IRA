//
//  StoredSession.swift
//  IRA
//
//  SwiftData persistent model for Session
//

import Foundation
import SwiftData

@Model
final class StoredSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var vehicle: String?
    var racer: String?
    var track: String?
    
    @Relationship(deleteRule: .cascade, inverse: \StoredLap.session)
    var laps: [StoredLap] = []
    
    init(id: UUID = UUID(),
         date: Date,
         vehicle: String? = nil,
         racer: String? = nil,
         track: String? = nil) {
        self.id = id
        self.date = date
        self.vehicle = vehicle
        self.racer = racer
        self.track = track
    }
    
    // MARK: - Conversion from Session
    
    static func fromSession(_ session: Session) -> StoredSession {
        let stored = StoredSession(
            id: session.id,
            date: session.date,
            vehicle: session.vehicle,
            racer: session.racer,
            track: session.track
        )
        
        // Convert laps
        stored.laps = session.laps.map { lap in
            StoredLap.fromLap(lap, session: stored)
        }
        
        return stored
    }
    
    // MARK: - Convert to Session
    
    func toSession() -> Session {
        Session(
            id: id,
            date: date,
            vehicle: vehicle,
            racer: racer,
            track: track,
            laps: laps.map { $0.toLap() }
        )
    }
}
