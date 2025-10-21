//
//  StoredLap.swift
//  IRA
//
//  SwiftData persistent model for Lap
//

import Foundation
import SwiftData

@Model
final class StoredLap {
    @Attribute(.unique) var id: UUID
    var lapNumber: Int
    var time: Double
    
    // Computed property for backwards compatibility
    var lapTime: Double {
        get { time }
        set { time = newValue }
    }
    
    var session: StoredSession?
    
    @Attribute(.externalStorage)
    var telemetryData: Data?
    
    // Cache for decoded telemetry points
    private var cachedTelemetryPoints: [TelemetryPoint]?
    
    var telemetryPoints: [TelemetryPoint] {
        get {
            if let cached = cachedTelemetryPoints {
                return cached
            }
            
            guard let data = telemetryData else { return [] }
            
            do {
                let decoder = JSONDecoder()
                let points = try decoder.decode([TelemetryPoint].self, from: data)
                cachedTelemetryPoints = points
                return points
            } catch {
                print("Failed to decode telemetry points: \(error)")
                return []
            }
        }
        set {
            cachedTelemetryPoints = newValue
            
            do {
                let encoder = JSONEncoder()
                telemetryData = try encoder.encode(newValue)
            } catch {
                print("Failed to encode telemetry points: \(error)")
            }
        }
    }
    
    init(id: UUID = UUID(),
         lapNumber: Int,
         time: Double,
         session: StoredSession? = nil) {
        self.id = id
        self.lapNumber = lapNumber
        self.time = time
        self.session = session
    }
    
    // MARK: - Conversion from Lap
    
    static func fromLap(_ lap: Lap, session: StoredSession) -> StoredLap {
        let stored = StoredLap(
            id: lap.id,
            lapNumber: lap.lapNumber,
            time: lap.time,
            session: session
        )
        
        // Encode telemetry points
        stored.telemetryPoints = lap.telemetryPoints
        
        return stored
    }
    
    // MARK: - Convert to Lap
    
    func toLap() -> Lap {
        Lap(
            id: id,
            lapNumber: lapNumber,
            time: time,
            telemetryPoints: telemetryPoints
        )
    }
}
