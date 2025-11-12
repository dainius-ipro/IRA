/// Lap.swift
/// RaceAnalytics
///
/// Represents a single lap with telemetry data

import Foundation

struct Lap: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    let lapNumber: Int
    let time: Double
    let telemetryPoints: [TelemetryPoint]
    
    // MARK: - Computed Properties
    
    var maxSpeed: Double {
        telemetryPoints.compactMap(\.speed).max() ?? 0
    }
    
    var averageSpeed: Double {
        let speeds = telemetryPoints.compactMap(\.speed)
        guard !speeds.isEmpty else { return 0 }
        return speeds.reduce(0, +) / Double(speeds.count)
    }
    
    var maxRPM: Int {
        telemetryPoints.compactMap(\.rpm).max() ?? 0
    }
    
    var averageRPM: Double {
        let rpms = telemetryPoints.compactMap(\.rpm)
        guard !rpms.isEmpty else { return 0 }
        return Double(rpms.reduce(0, +)) / Double(rpms.count)
    }
    
    var maxLonAcc: Double {
        telemetryPoints.compactMap { $0.lonAcc }.map { abs($0) }.max() ?? 0
    }
    
    var maxLatAcc: Double {
        telemetryPoints.compactMap { $0.latAcc }.map { abs($0) }.max() ?? 0
    }
    
    // MARK: - Formatting Helpers
    
    var formattedTime: String {
        let minutes = Int(time) / 60
        let seconds = time.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%06.3f", minutes, seconds)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Lap, rhs: Lap) -> Bool {
        lhs.id == rhs.id &&
        lhs.lapNumber == rhs.lapNumber &&
        lhs.time == rhs.time &&
        lhs.telemetryPoints == rhs.telemetryPoints
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
