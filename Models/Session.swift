import Foundation

/// Represents a complete karting session with multiple laps
struct Session: Codable, Identifiable {
let id: UUID
let date: Date
let vehicle: String?
let racer: String?
let track: String?
let laps: [Lap]

```
// MARK: - Computed Properties
var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

var totalLaps: Int {
    laps.count
}

var bestLap: Lap? {
    laps.min { $0.time < $1.time }
}

var bestLapTime: String {
    bestLap?.formattedTime ?? "N/A"
}

var averageLapTime: Double {
    guard !laps.isEmpty else { return 0 }
    let sum = laps.reduce(0) { $0 + $1.time }
    return sum / Double(laps.count)
}

var formattedAverageLapTime: String {
    let minutes = Int(averageLapTime) / 60
    let seconds = averageLapTime.truncatingRemainder(dividingBy: 60)
    return String(format: "%d:%06.3f", minutes, seconds)
}

var totalDuration: Double {
    laps.reduce(0) { $0 + $1.time }
}

var formattedTotalDuration: String {
    let minutes = Int(totalDuration) / 60
    let seconds = Int(totalDuration) % 60
    return String(format: "%d:%02d", minutes, seconds)
}

var maxSpeed: Double {
    laps.map(\.maxSpeed).max() ?? 0
}

var totalDistance: Double {
    laps.reduce(0) { $0 + $1.totalDistance }
}

var hasGPSData: Bool {
    laps.contains { $0.hasValidGPS }
}

init(
    id: UUID = UUID(),
    date: Date,
    vehicle: String? = nil,
    racer: String? = nil,
    track: String? = nil,
    laps: [Lap]
) {
    self.id = id
    self.date = date
    self.vehicle = vehicle
    self.racer = racer
    self.track = track
    self.laps = laps
}
```

}

// MARK: - Sample Data
extension Session {
static var sample: Session {
let laps = (1…10).map { lapNumber in
let baseTime = 65.0 + Double.random(in: -2…2)
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
            lapNumber: lapNumber,
            time: baseTime,
            telemetryPoints: points
        )
    }
    
    return Session(
        date: Date(),
        vehicle: "FA 2025",
        racer: "Troy",
        track: "Circuit Osona",
        laps: laps
    )
}
```

}