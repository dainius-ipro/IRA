//
//  TelemetryPoint.swift
//  RaceAnalytics
//

import Foundation

/// Represents a single telemetry data point from MyChron 6T logger
/// Sample rate: 20 Hz (20 samples per second)
/// Total parameters: 26 telemetry channels
struct TelemetryPoint: Codable, Equatable {
    
    // MARK: - Core Data
    let time: Double        // Time in seconds from session start
    let distance: Double    // Distance in meters from start
    let speed: Double       // Speed in km/h
    
    // MARK: - GPS Data (13 parameters)
    let latitude: Double           // Latitude in degrees
    let longitude: Double          // Longitude in degrees
    let altitude: Double           // Altitude in meters
    let satellites: Int            // Number of GPS satellites
    let heading: Double            // Heading in degrees (0-360)
    let posAccuracy: Double        // Position accuracy in meters
    let speedAccuracy: Double      // Speed accuracy in km/h
    let latAcc: Double             // Lateral acceleration in G
    let lonAcc: Double             // Longitudinal acceleration in G
    let slope: Double              // Slope/grade in degrees
    let gyro: Double               // Gyroscope reading (yaw rate)
    let radius: Double             // Turn radius in meters
    
    // MARK: - Engine Data (3 parameters)
    let rpm: Int                   // Engine RPM
    let exhaustTemp: Double        // Exhaust temperature in °C
    let waterTemp: Double          // Water/coolant temperature in °C
    
    // MARK: - Accelerometer (3 parameters)
    let accelerometerX: Double     // X-axis acceleration in G
    let accelerometerY: Double     // Y-axis acceleration in G
    let accelerometerZ: Double     // Z-axis acceleration in G
    
    // MARK: - Gyroscope (3 parameters)
    let gyroX: Double              // X-axis gyro (roll rate)
    let gyroY: Double              // Y-axis gyro (pitch rate)
    let gyroZ: Double              // Z-axis gyro (yaw rate)
    
    // MARK: - System (2 parameters)
    let loggerTemp: Double         // Logger internal temperature in °C
    let internalBattery: Double    // Battery voltage
    
    // MARK: - Computed Properties
    
    /// Total G-force magnitude
    var gForce: Double {
        sqrt(latAcc * latAcc + lonAcc * lonAcc + lonAcc * lonAcc)
    }
    
    /// Whether this point has valid GPS coordinates
    var isValidGPS: Bool {
        latitude != 0 && longitude != 0 && satellites >= 4
    }
    
    // MARK: - Sample Data
    
    #if DEBUG
    /// Sample telemetry point for testing and previews
    static let sample = TelemetryPoint(
        time: 0.0,
        distance: 0.0,
        speed: 60.0,
        latitude: 41.8266,
        longitude: 2.0967,
        altitude: 150.0,
        satellites: 12,
        heading: 90.0,
        posAccuracy: 2.5,
        speedAccuracy: 0.5,
        latAcc: 0.5,
        lonAcc: -0.3,
        slope: 0.0,
        gyro: 0.0,
        radius: 0.0,
        rpm: 10000,
        exhaustTemp: 600.0,
        waterTemp: 50.0,
        accelerometerX: 0.0,
        accelerometerY: 0.0,
        accelerometerZ: 9.81,
        gyroX: 0.0,
        gyroY: 0.0,
        gyroZ: 0.0,
        loggerTemp: 35.0,
        internalBattery: 4.2
    )
    #endif
}
