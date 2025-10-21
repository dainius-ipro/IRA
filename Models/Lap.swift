//
//  Lap.swift
//  RaceAnalytics
//

import Foundation

/// In-memory model for a single lap
struct Lap: Identifiable, Codable {
    
    // MARK: - Properties
    
    let id: UUID
    let lapNumber: Int
    let time: Double // Lap time in seconds
    let telemetryPoints: [TelemetryPoint]
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        lapNumber: Int,
        time: Double,
        telemetryPoints: [TelemetryPoint] = []
    ) {
        self.id = id
        self.lapNumber = lapNumber
        self.time = time
        self.telemetryPoints = telemetryPoints
    }
    
    // MARK: - Computed Properties
    
    /// Maximum speed in this lap (km/h)
    var maxSpeed: Double? {
        telemetryPoints.map { $0.speed }.max()
    }
    
    /// Average speed in this lap (km/h)
    var averageSpeed: Double {
        guard !telemetryPoints.isEmpty else { return 0 }
        let total = telemetryPoints.reduce(0.0) { $0 + $1.speed }
        return total / Double(telemetryPoints.count)
    }
    
    /// Maximum RPM in this lap
    var maxRPM: Int? {
        telemetryPoints.map { $0.rpm }.max()
    }
    
    /// Total distance covered in this lap (meters)
    var distance: Double {
        guard let last = telemetryPoints.last,
              let first = telemetryPoints.first else {
            return 0
        }
        return last.distance - first.distance
    }
}

// MARK: - Equatable

extension Lap: Equatable {
    static func == (lhs: Lap, rhs: Lap) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension Lap: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}