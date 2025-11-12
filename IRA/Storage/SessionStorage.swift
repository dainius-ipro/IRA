// SessionStorage.swift
import Foundation
import SwiftData

class SessionStorage {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func save(_ session: Session) throws {
        let storedSession = StoredSession(
            id: session.id,
            date: session.date,
            vehicle: session.vehicle,
            racer: session.racer,
            track: session.track,
            championship: session.championship,
            session: session.session
        )
        
        for lap in session.laps {
            let telemetryData = try JSONEncoder().encode(lap.telemetryPoints)
            let storedLap = StoredLap(
                id: lap.id,
                lapNumber: lap.lapNumber,
                lapTime: lap.time,
                telemetryData: telemetryData
            )
            storedSession.laps.append(storedLap)
        }
        
        modelContext.insert(storedSession)
        try modelContext.save()
    }
    
    func loadAll() throws -> [Session] {
        let descriptor = FetchDescriptor<StoredSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let storedSessions = try modelContext.fetch(descriptor)
        
        return storedSessions.map { storedSession in
            storedSession.toSession()
        }
    }
}
