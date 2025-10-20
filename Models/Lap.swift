import Foundation

/// Represents a single lap with telemetry data
struct Lap: Codable, Identifiable {
let id: UUID
let lapNumber: Int
let time: Double // seconds
let telemetryPoints: [TelemetryPoint]

```
// MARK: - Computed Properties
var formattedTime: String {
    let minutes = Int(time) / 60
    let seconds = time.truncatingRemainder(dividingBy: 60)
    return String(format: "%d:%06.3f", minutes, seconds)
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

var totalDistance: Double {
    telemetryPoints.last?.distance ?? 0
}

var validGPSPoints: [TelemetryPoint] {
    telemetryPoints.filter(\.isValidGPS)
}

var hasValidGPS: Bool {
    !validGPSPoints.isEmpty
}

init(
    id: UUID = UUID(),
    lapNumber: Int,
    time: Double,
    telemetryPoints: [TelemetryPoint]
) {
    self.id = id
    self.lapNumber = lapNumber
    self.time = time
    self.telemetryPoints = telemetryPoints
}
```

}

// MARK: - Sample Data
extension Lap {
static var sample: Lap {
let points = (0..<100).map { i in
TelemetryPoint(
time: Double(i) * 0.05,
distance: Double(i) * 10,
speed: 65.0 + Double.random(in: -5…5),
satellites: 12,
latAcc: Double.random(in: -1…1),
lonAcc: Double.random(in: -1…1),
slope: 2.0,
heading: 180.0,
gyro: 15.0,
altitude: 450.0,
posAccuracy: 2.0,
speedAccuracy: 1.0,
radius: 25.0,
latitude: 41.7425 + Double(i) * 0.0001,
longitude: 2.0863 + Double(i) * 0.0001,
rpm: 12500,
exhaustTemp: 420.0,
waterTemp: 65.0,
accelerometerX: 0.1,
accelerometerY: 0.8,
accelerometerZ: 9.8,
gyroX: 5.0,
gyroY: 10.0,
gyroZ: 15.0,
loggerTemp: 35.0,
internalBattery: 12.6
)
}

```
    return Lap(
        lapNumber: 1,
        time: 65.432,
        telemetryPoints: points
    )
}
```

}