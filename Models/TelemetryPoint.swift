import Foundation

/// Represents a single telemetry data point from MyChron at 20Hz
struct TelemetryPoint: Codable, Identifiable {
let id: UUID

```
// MARK: - Core Data
let time: Double           // Seconds from start
let distance: Double       // Meters from start

// MARK: - GPS Data (13 parameters)
let speed: Double          // km/h
let satellites: Int
let latAcc: Double         // Lateral acceleration (G)
let lonAcc: Double         // Longitudinal acceleration (G)
let slope: Double          // Degrees
let heading: Double        // Degrees
let gyro: Double           // Degrees/second
let altitude: Double       // Meters
let posAccuracy: Double    // Meters
let speedAccuracy: Double  // km/h
let radius: Double         // Meters
let latitude: Double       // Decimal degrees
let longitude: Double      // Decimal degrees

// MARK: - Engine Data (3 parameters)
let rpm: Int
let exhaustTemp: Double    // Celsius
let waterTemp: Double      // Celsius

// MARK: - Motion Sensors (6 parameters)
let accelerometerX: Double // G
let accelerometerY: Double // G
let accelerometerZ: Double // G
let gyroX: Double          // Degrees/second
let gyroY: Double          // Degrees/second
let gyroZ: Double          // Degrees/second

// MARK: - System Data (4 parameters)
let loggerTemp: Double     // Celsius
let internalBattery: Double // Volts

// MARK: - Computed Properties
var gForce: Double {
    sqrt(latAcc * latAcc + lonAcc * lonAcc)
}

var isValidGPS: Bool {
    latitude != 0 && longitude != 0 && satellites >= 4
}

var coordinate: (latitude: Double, longitude: Double) {
    (latitude, longitude)
}

init(
    id: UUID = UUID(),
    time: Double,
    distance: Double,
    speed: Double,
    satellites: Int,
    latAcc: Double,
    lonAcc: Double,
    slope: Double,
    heading: Double,
    gyro: Double,
    altitude: Double,
    posAccuracy: Double,
    speedAccuracy: Double,
    radius: Double,
    latitude: Double,
    longitude: Double,
    rpm: Int,
    exhaustTemp: Double,
    waterTemp: Double,
    accelerometerX: Double,
    accelerometerY: Double,
    accelerometerZ: Double,
    gyroX: Double,
    gyroY: Double,
    gyroZ: Double,
    loggerTemp: Double,
    internalBattery: Double
) {
    self.id = id
    self.time = time
    self.distance = distance
    self.speed = speed
    self.satellites = satellites
    self.latAcc = latAcc
    self.lonAcc = lonAcc
    self.slope = slope
    self.heading = heading
    self.gyro = gyro
    self.altitude = altitude
    self.posAccuracy = posAccuracy
    self.speedAccuracy = speedAccuracy
    self.radius = radius
    self.latitude = latitude
    self.longitude = longitude
    self.rpm = rpm
    self.exhaustTemp = exhaustTemp
    self.waterTemp = waterTemp
    self.accelerometerX = accelerometerX
    self.accelerometerY = accelerometerY
    self.accelerometerZ = accelerometerZ
    self.gyroX = gyroX
    self.gyroY = gyroY
    self.gyroZ = gyroZ
    self.loggerTemp = loggerTemp
    self.internalBattery = internalBattery
}
```

}

// MARK: - Sample Data
extension TelemetryPoint {
static var sample: TelemetryPoint {
TelemetryPoint(
time: 0.0,
distance: 0.0,
speed: 65.5,
satellites: 12,
latAcc: 0.8,
lonAcc: -0.5,
slope: 2.5,
heading: 180.0,
gyro: 15.0,
altitude: 450.0,
posAccuracy: 2.0,
speedAccuracy: 1.0,
radius: 25.0,
latitude: 41.7425,
longitude: 2.0863,
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
}