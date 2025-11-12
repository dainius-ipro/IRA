// StoredLap.swift
import Foundation
import SwiftData

@Model
final class StoredLap {
    @Attribute(.unique) var id: UUID
    var lapNumber: Int
    var lapTime: Double
    var telemetryData: Data
    
    // Computed properties for convenience
    var time: Double { lapTime }
    
    var telemetryPoints: [TelemetryPoint] {
        get {
            (try? JSONDecoder().decode([TelemetryPoint].self, from: telemetryData)) ?? []
        }
    }
    
    init(id: UUID = UUID(), lapNumber: Int, lapTime: Double, telemetryData: Data) {
        self.id = id
        self.lapNumber = lapNumber
        self.lapTime = lapTime
        self.telemetryData = telemetryData
    }
    
    convenience init(lapNumber: Int, time: Double) {
        self.init(id: UUID(), lapNumber: lapNumber, lapTime: time, telemetryData: Data())
    }
    
    static func fromLap(_ lap: Lap) -> StoredLap {
        let data = (try? JSONEncoder().encode(lap.telemetryPoints)) ?? Data()
        return StoredLap(id: lap.id, lapNumber: lap.lapNumber, lapTime: lap.time, telemetryData: data)
    }
    
    func toLap() -> Lap {
        Lap(id: id, lapNumber: lapNumber, time: lapTime, telemetryPoints: telemetryPoints)
    }
}
