import Foundation

/// Represents a single lap with telemetry data
struct Lap: Codable, Identifiable {
    var id: UUID = UUID()
    var lapNumber: Int
    var lapTime: Double        // seconds
    var telemetryPoints: [TelemetryPoint]
    
    // MARK: - Computed Properties
    
    var formattedTime: String {
        let minutes = Int(lapTime) / 60
        let seconds = lapTime.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%05.2f", minutes, seconds)
    }
    
    var averageSpeed: Double {
        guard !telemetryPoints.isEmpty else { return 0 }
        let sum = telemetryPoints.reduce(0) { $0 + $1.speed }
        return sum / Double(telemetryPoints.count)
    }
    
    var maxSpeed: Double {
        telemetryPoints.map(\.speed).max() ?? 0
    }
    
    var minSpeed: Double {
        telemetryPoints.map(\.speed).min() ?? 0
    }
    
    var maxRPM: Int {
        telemetryPoints.map(\.rpm).max() ?? 0
    }
    
    var averageRPM: Double {
        guard !telemetryPoints.isEmpty else { return 0 }
        let sum = telemetryPoints.reduce(0) { $0 + Double($1.rpm) }
        return sum / Double(telemetryPoints.count)
    }
    
    var maxGForce: Double {
        telemetryPoints.map(\.gForce).max() ?? 0
    }
}

/// Represents a single telemetry sample (one moment in time)
struct TelemetryPoint: Codable {
    var time: Double          // seconds
    var speed: Double         // km/h
    var rpm: Int              // engine RPM
    var gForce: Double        // lateral or longitudinal G-force
}