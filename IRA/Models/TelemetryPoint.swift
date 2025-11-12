/// TelemetryPoint.swift
/// RaceAnalytics
///
/// Represents a single telemetry data point from MyChron 6T
/// 26 parameters sampled at 20Hz

import Foundation
import CoreLocation

struct TelemetryPoint: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    
    // MARK: - System Data (4 parameters)
    let time: Double           // Time from session start (seconds)
    let distance: Double       // Distance from session start (meters)
    let loggerTemp: Double?    // Logger internal temperature (°C)
    let internalBattery: Double? // Battery voltage (V)
    
    // MARK: - GPS Data (13 parameters)
    let speed: Double?         // GPS speed (km/h)
    let satellites: Int?       // Number of GPS satellites
    let latitude: Double?      // GPS latitude (degrees)
    let longitude: Double?     // GPS longitude (degrees)
    let altitude: Double?      // GPS altitude (meters)
    let heading: Double?       // GPS heading (degrees)
    let slope: Double?         // Track slope (%)
    let latAcc: Double?        // Lateral acceleration (g)
    let lonAcc: Double?        // Longitudinal acceleration (g)
    let gyro: Double?          // Yaw rate (deg/s)
    let radius: Double?        // Turn radius (meters)
    let posAccuracy: Double?   // Position accuracy (meters)
    let speedAccuracy: Double? // Speed accuracy (km/h)
    
    // MARK: - Engine Data (3 parameters)
    let rpm: Int?              // Engine RPM
    let exhaustTemp: Double?   // Exhaust gas temperature (°C)
    let waterTemp: Double?     // Water/coolant temperature (°C)
    
    // MARK: - Motion Sensors (6 parameters)
    let accelX: Double?        // Accelerometer X-axis (g)
    let accelY: Double?        // Accelerometer Y-axis (g)
    let accelZ: Double?        // Accelerometer Z-axis (g)
    let gyroX: Double?         // Gyroscope X-axis (deg/s)
    let gyroY: Double?         // Gyroscope Y-axis (deg/s)
    let gyroZ: Double?         // Gyroscope Z-axis (deg/s)
    
    // MARK: - Computed Properties
    
    /// GPS coordinate for map display
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    /// Total G-force magnitude
    var gForce: Double? {
        guard let lat = latAcc, let lon = lonAcc else { return nil }
        return sqrt(lat * lat + lon * lon)
    }
    
    /// Whether GPS data is valid
    var hasValidGPS: Bool {
        latitude != nil && longitude != nil && 
        latitude != 0 && longitude != 0
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        time: Double,
        distance: Double,
        loggerTemp: Double? = nil,
        internalBattery: Double? = nil,
        speed: Double? = nil,
        satellites: Int? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        altitude: Double? = nil,
        heading: Double? = nil,
        slope: Double? = nil,
        latAcc: Double? = nil,
        lonAcc: Double? = nil,
        gyro: Double? = nil,
        radius: Double? = nil,
        posAccuracy: Double? = nil,
        speedAccuracy: Double? = nil,
        rpm: Int? = nil,
        exhaustTemp: Double? = nil,
        waterTemp: Double? = nil,
        accelX: Double? = nil,
        accelY: Double? = nil,
        accelZ: Double? = nil,
        gyroX: Double? = nil,
        gyroY: Double? = nil,
        gyroZ: Double? = nil
    ) {
        self.id = id
        self.time = time
        self.distance = distance
        self.loggerTemp = loggerTemp
        self.internalBattery = internalBattery
        self.speed = speed
        self.satellites = satellites
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.heading = heading
        self.slope = slope
        self.latAcc = latAcc
        self.lonAcc = lonAcc
        self.gyro = gyro
        self.radius = radius
        self.posAccuracy = posAccuracy
        self.speedAccuracy = speedAccuracy
        self.rpm = rpm
        self.exhaustTemp = exhaustTemp
        self.waterTemp = waterTemp
        self.accelX = accelX
        self.accelY = accelY
        self.accelZ = accelZ
        self.gyroX = gyroX
        self.gyroY = gyroY
        self.gyroZ = gyroZ
    }
    
    // MARK: - Equatable
    
    static func == (lhs: TelemetryPoint, rhs: TelemetryPoint) -> Bool {
        lhs.id == rhs.id &&
        lhs.time == rhs.time &&
        lhs.distance == rhs.distance
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Convenience Extensions

extension TelemetryPoint {
    /// Format speed for display
    var formattedSpeed: String {
        guard let speed = speed else { return "N/A" }
        return String(format: "%.1f km/h", speed)
    }
    
    /// Format RPM for display
    var formattedRPM: String {
        guard let rpm = rpm else { return "N/A" }
        return String(format: "%d RPM", rpm)
    }
    
    /// Format time for display
    var formattedTime: String {
        let minutes = Int(time) / 60
        let seconds = time.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%06.3f", minutes, seconds)
    }
}
