//
//  Session.swift
//  RaceAnalytics
//

import Foundation

struct Session: Identifiable, Codable, Equatable, Hashable {
    
    // MARK: - Properties
    
    let id: UUID
    let date: Date
    var vehicle: String?
    var racer: String?
    var track: String?
    var trackLength: Double?
    var laps: [Lap]
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        vehicle: String? = nil,
        racer: String? = nil,
        track: String? = nil,
        trackLength: Double? = nil,
        laps: [Lap] = []
    ) {
        self.id = id
        self.date = date
        self.vehicle = vehicle
        self.racer = racer
        self.track = track
        self.trackLength = trackLength
        self.laps = laps
    }
    
    // MARK: - Computed Properties
    
    var totalDuration: Double {
        laps.reduce(0) { $0 + $1.time }
    }
    
    var bestLapTime: Double? {
        laps.map { $0.time }.min()
    }
    
    var bestLapNumber: Int? {
        guard let bestTime = bestLapTime else { return nil }
        return laps.first { $0.time == bestTime }?.lapNumber
    }
    
    var averageLapTime: Double {
        guard !laps.isEmpty else { return 0 }
        return totalDuration / Double(laps.count)
    }
    
    var totalDistance: Double {
        guard let lastLap = laps.last,
              let lastPoint = lastLap.telemetryPoints.last else {
            return 0
        }
        return lastPoint.distance
    }
    
    var maxSpeed: Double? {
        laps.flatMap { $0.telemetryPoints.map { $0.speed } }.max()
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var displayTitle: String {
        if let track = track {
            return "\(track) - \(formattedDate)"
        } else {
            return formattedDate
        }
    }
    
    var consistencyScore: Double {
        guard laps.count >= 2 else { return 100 }
        let times = laps.map { $0.time }
        let avg = averageLapTime
        let variance = times.reduce(0) { $0 + pow($1 - avg, 2) } / Double(times.count)
        let stdDev = sqrt(variance)
        let variation = stdDev / avg
        let score = max(0, 100 - (variation * 2000))
        return min(100, max(0, score))
    }
    
    // MARK: - Methods
    
    func lap(number: Int) -> Lap? {
        laps.first { $0.lapNumber == number }
    }
    
    func bestLap() -> Lap? {
        guard let bestNumber = bestLapNumber else { return nil }
        return lap(number: bestNumber)
    }
    
    static func == (lhs: Session, rhs: Session) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sample Data

#if DEBUG
extension Session {
    static let sample: Session = {
        let points = (0..<900).map { i -> TelemetryPoint in
            TelemetryPoint(
                time: Double(i) * 0.05,
                distance: Double(i) * 0.75,
                speed: 40 + Double(i % 60),
                latitude: 41.8266,
                longitude: 2.0947,
                altitude: 150.0,
                satellites: 12,
                heading: 0.0, posAccuracy: 0.0, speedAccuracy: 0.0,
                latAcc: 0.0, lonAcc: 0.0,
                slope: 2.5, gyro: 0.5, radius: 0.0,
                rpm: 10000,
                exhaustTemp: 600.0, waterTemp: 50.0,
                accelerometerX: 0.0, accelerometerY: 0.0, accelerometerZ: 9.81,
                gyroX: 0.0, gyroY: 0.0, gyroZ: 0.0,
                loggerTemp: 35.0, internalBattery: 4.2
            )
        }
        
        let laps = (1...10).map { num in
            Lap(id: UUID(), lapNumber: num, time: 45.0, telemetryPoints: points)
        }
        
        return Session(
            date: Date(),
            vehicle: "FA 2025 IAME X30",
            racer: "Troy",
            track: "Circuit Osona",
            trackLength: 850.0,
            laps: laps
        )
    }()
}
#endif
