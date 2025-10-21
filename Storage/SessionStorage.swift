// RaceAnalytics/Storage/SessionStorage.swift

import Foundation
import SwiftData

@Observable
class SessionStorage {
    
    private let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: StoredSession.self,
                configurations: ModelConfiguration()
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    func save(_ session: Session) throws {
        let stored = StoredSession(
            id: session.id,
            date: session.date,
            vehicle: session.vehicle,
            racer: session.racer,
            track: session.track
        )
        
        for lap in session.laps {
            let storedLap = StoredLap(
                id: lap.id,
                lapNumber: lap.lapNumber,
                time: lap.time
            )
            stored.laps.append(storedLap)
        }
        
        modelContainer.mainContext.insert(stored)
        try modelContainer.mainContext.save()
    }
    
    func delete(_ session: Session) throws {
        let fetchDescriptor = FetchDescriptor<StoredSession>(
            predicate: #Predicate { $0.id == session.id }
        )
        
        if let stored = try modelContainer.mainContext.fetch(fetchDescriptor).first {
            modelContainer.mainContext.delete(stored)
            try modelContainer.mainContext.save()
        }
    }
    
    func loadSessions() throws -> [Session] {
        let fetchDescriptor = FetchDescriptor<StoredSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let storedSessions = try modelContainer.mainContext.fetch(fetchDescriptor)
        
        return storedSessions.map { stored in
            Session(
                id: stored.id,
                date: stored.date,
                vehicle: stored.vehicle,
                racer: stored.racer,
                track: stored.track,
                laps: stored.laps.map { storedLap in
                    Lap(
                        id: storedLap.id,
                        lapNumber: storedLap.lapNumber,
                        time: storedLap.time,
                        telemetryPoints: []
                    )
                }
            )
        }
    }
}
