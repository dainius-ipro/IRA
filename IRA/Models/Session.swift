/// Session.swift
/// RaceAnalytics
///
/// Represents a complete racing session with multiple laps

import Foundation

struct Session: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    let date: Date
    let vehicle: String?
    let racer: String?
    let track: String?
    let championship: String?
    let session: String?
    let laps: [Lap]
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        vehicle: String? = nil,
        racer: String? = nil,
        track: String? = nil,
        championship: String? = nil,
        session: String? = nil,
        laps: [Lap] = []
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
    
    // MARK: - Computed Properties
    
    /// Total session duration (sum of all lap times)
    var duration: Double {
        laps.reduce(0) { $0 + $1.time }
    }
    
    /// Best (fastest) lap in the session
    var bestLap: Lap? {
        laps.min(by: { $0.time < $1.time })
    }
    
    /// Average lap time across all laps
    var averageLapTime: Double {
        guard !laps.isEmpty else { return 0 }
        return duration / Double(laps.count)
    }
    
    /// Maximum speed reached in the session
    var maxSpeed: Double {
        laps.compactMap { $0.maxSpeed }.max() ?? 0
    }
    
    /// Average speed across all laps
    var averageSpeed: Double {
        guard !laps.isEmpty else { return 0 }
        let totalSpeed = laps.reduce(0.0) { $0 + $1.averageSpeed }
        return totalSpeed / Double(laps.count)
    }
    
    /// Total distance covered (meters)
    var totalDistance: Double {
        laps.compactMap { $0.telemetryPoints.last?.distance }.max() ?? 0
    }
    
    /// Number of laps in session
    var lapCount: Int {
        laps.count
    }
    
    /// All telemetry points from all laps (flattened)
    var allTelemetryPoints: [TelemetryPoint] {
        laps.flatMap { $0.telemetryPoints }
    }
    
    // MARK: - Formatting Helpers
    
    /// Format session duration as MM:SS.mmm
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = duration.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%06.3f", minutes, seconds)
    }
    
    /// Format date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Session title for display
    var displayTitle: String {
        if let track = track {
            return track
        } else if let session = session {
            return session
        } else {
            return "Session \(formattedDate)"
        }
    }
    
    /// Session subtitle for display
    var displaySubtitle: String {
        var parts: [String] = []
        if let racer = racer {
            parts.append(racer)
        }
        if let vehicle = vehicle {
            parts.append(vehicle)
        }
        if parts.isEmpty {
            parts.append("\(lapCount) laps")
        }
        return parts.joined(separator: " • ")
    }
    
    // MARK: - Lap Statistics
    
    /// Standard deviation of lap times (consistency measure)
    var lapTimeStdDev: Double {
        guard laps.count > 1 else { return 0 }
        
        let mean = averageLapTime
        let variance = laps.reduce(0.0) { sum, lap in
            let diff = lap.time - mean
            return sum + (diff * diff)
        } / Double(laps.count)
        
        return sqrt(variance)
    }
    
    /// Consistency score (0-100, higher is better)
    var consistencyScore: Double {
        guard laps.count > 1, averageLapTime > 0 else { return 0 }
        
        // Lower std dev = higher consistency
        let coefficientOfVariation = lapTimeStdDev / averageLapTime
        let score = max(0, min(100, 100 * (1 - coefficientOfVariation * 2)))
        
        return score
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Session, rhs: Session) -> Bool {
        lhs.id == rhs.id &&
        lhs.date == rhs.date &&
        lhs.laps == rhs.laps
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension Session {
    /// Sample session for SwiftUI previews
    static var preview: Session {
        Session(
            id: UUID(),
            date: Date(),
            vehicle: "FA Kart 2025",
            racer: "Troy",
            track: "Circuit Osona",
            championship: "IAME X30 Junior",
            session: "Practice",
            laps: [
                Lap(
                    id: UUID(),
                    lapNumber: 1,
                    time: 65.234,
                    telemetryPoints: []
                ),
                Lap(
                    id: UUID(),
                    lapNumber: 2,
                    time: 64.891,
                    telemetryPoints: []
                )
            ]
        )
    }
}
#endif
