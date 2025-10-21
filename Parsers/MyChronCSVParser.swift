//
//  MyChronCSVParser.swift
//  RaceAnalytics
//

import Foundation

/// Parser for MyChron 6T CSV telemetry data
/// Supports 26 telemetry parameters at 20 Hz sample rate
struct MyChronCSVParser {
    
    // MARK: - Error Types
    
    enum ParseError: Error, LocalizedError {
        case invalidFileFormat
        case missingHeaders
        case invalidData(line: Int, reason: String)
        case noLapsFound
        
        var errorDescription: String? {
            switch self {
            case .invalidFileFormat:
                return "Invalid CSV file format"
            case .missingHeaders:
                return "CSV headers not found"
            case .invalidData(let line, let reason):
                return "Invalid data at line \(line): \(reason)"
            case .noLapsFound:
                return "No lap data found in file"
            }
        }
    }
    
    // MARK: - CSV Column Names (from MyChron export)
    
    private struct ColumnNames {
        // Core
        static let time = "\"Time\""
        static let distance = "\"Distance\""
        static let speed = "\"Speed\""
        
        // GPS
        static let latitude = "\"Latitude\""
        static let longitude = "\"Longitude\""
        static let altitude = "\"Altitude\""
        static let satellites = "\"Satellites\""
        static let heading = "\"Heading\""
        static let posAccuracy = "\"PosAccuracy\""
        static let speedAccuracy = "\"SpeedAccuracy\""
        static let latAcc = "\"LatAcc\""
        static let lonAcc = "\"LonAcc\""
        static let slope = "\"Slope\""
        static let gyro = "\"Gyro\""
        static let radius = "\"Radius\""
        
        // Engine
        static let rpm = "\"RPM\""
        static let exhaustTemp = "\"ExhaustTemp\""
        static let waterTemp = "\"WaterTemp\""
        
        // Accelerometer
        static let accelerometerX = "\"AccelerometerX\""
        static let accelerometerY = "\"AccelerometerY\""
        static let accelerometerZ = "\"AccelerometerZ\""
        
        // Gyroscope
        static let gyroX = "\"GyroX\""
        static let gyroY = "\"GyroY\""
        static let gyroZ = "\"GyroZ\""
        
        // System
        static let loggerTemp = "\"LoggerTemp\""
        static let internalBattery = "\"InternalBattery\""
    }
    
    // MARK: - Public Interface
    
    /// Parse a MyChron CSV file into a Session
    /// - Parameter data: Raw CSV file data
    /// - Returns: Parsed Session with laps and telemetry
    /// - Throws: ParseError if file cannot be parsed
    func parse(_ data: Data) throws -> Session {
        // Convert data to string
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ParseError.invalidFileFormat
        }
        
        // Split into lines
        let lines = csvString.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        
        guard lines.count > 1 else {
            throw ParseError.invalidFileFormat
        }
        
        // Parse header line
        let headers = parseHeaders(lines[0])
        guard !headers.isEmpty else {
            throw ParseError.missingHeaders
        }
        
        // Parse data lines
        var telemetryPoints: [TelemetryPoint] = []
        
        for (index, line) in lines.dropFirst().enumerated() {
            do {
                let point = try parseTelemetryPoint(line: line, headers: headers)
                telemetryPoints.append(point)
            } catch {
                // Skip invalid lines but continue parsing
                print("Warning: Skipped line \(index + 2): \(error.localizedDescription)")
            }
        }
        
        guard !telemetryPoints.isEmpty else {
            throw ParseError.noLapsFound
        }
        
        // Split into laps (detect by distance reset or lap marker)
        let laps = splitIntoLaps(telemetryPoints)
        
        // Create session
        let session = Session(
            id: UUID(),
            date: Date(),
            vehicle: "IAME X30 Junior",
            racer: "Troy",
            track: "Circuit Osona",
            laps: laps
        )
        
        return session
    }
    
    // MARK: - Private Parsing Methods
    
    /// Parse CSV header line
    private func parseHeaders(_ line: String) -> [String: Int] {
        let columns = line.components(separatedBy: ",")
        var headers: [String: Int] = [:]
        
        for (index, column) in columns.enumerated() {
            let cleaned = column.trimmingCharacters(in: .whitespaces)
            headers[cleaned] = index
        }
        
        return headers
    }
    
    /// Parse a single telemetry point from CSV line
    private func parseTelemetryPoint(line: String, headers: [String: Int]) throws -> TelemetryPoint {
        let values = line.components(separatedBy: ",")
        
        // Helper to get value by column name
        func getValue(_ columnName: String) -> String {
            guard let index = headers[columnName], index < values.count else {
                return "0"
            }
            return values[index].trimmingCharacters(in: .whitespaces)
        }
        
        // Helper to parse double
        func parseDouble(_ str: String) -> Double {
            return Double(str) ?? 0.0
        }
        
        // Helper to parse int
        func parseInt(_ str: String) -> Int {
            return Int(str) ?? 0
        }
        
        // Parse required fields
        guard let time = Double(getValue(ColumnNames.time)) else {
            throw ParseError.invalidData(line: 0, reason: "Invalid time value")
        }
        
        // Create telemetry point with all 26 parameters
        return TelemetryPoint(
            // Core data
            time: time,
            distance: parseDouble(getValue(ColumnNames.distance)),
            speed: parseDouble(getValue(ColumnNames.speed)),
            
            // GPS (13 params)
            latitude: parseDouble(getValue(ColumnNames.latitude)),
            longitude: parseDouble(getValue(ColumnNames.longitude)),
            altitude: parseDouble(getValue(ColumnNames.altitude)),
            satellites: parseInt(getValue(ColumnNames.satellites)),
            heading: parseDouble(getValue(ColumnNames.heading)),
            posAccuracy: parseDouble(getValue(ColumnNames.posAccuracy)),
            speedAccuracy: parseDouble(getValue(ColumnNames.speedAccuracy)),
            latAcc: parseDouble(getValue(ColumnNames.latAcc)),
            lonAcc: parseDouble(getValue(ColumnNames.lonAcc)),
            slope: parseDouble(getValue(ColumnNames.slope)),
            gyro: parseDouble(getValue(ColumnNames.gyro)),
            radius: parseDouble(getValue(ColumnNames.radius)),
            
            // Engine (3 params)
            rpm: parseInt(getValue(ColumnNames.rpm)),
            exhaustTemp: parseDouble(getValue(ColumnNames.exhaustTemp)),
            waterTemp: parseDouble(getValue(ColumnNames.waterTemp)),
            
            // Motion sensors (6 params)
            accelerometerX: parseDouble(getValue(ColumnNames.accelerometerX)),
            accelerometerY: parseDouble(getValue(ColumnNames.accelerometerY)),
            accelerometerZ: parseDouble(getValue(ColumnNames.accelerometerZ)),
            gyroX: parseDouble(getValue(ColumnNames.gyroX)),
            gyroY: parseDouble(getValue(ColumnNames.gyroY)),
            gyroZ: parseDouble(getValue(ColumnNames.gyroZ)),
            
            // System (2 params)
            loggerTemp: parseDouble(getValue(ColumnNames.loggerTemp)),
            internalBattery: parseDouble(getValue(ColumnNames.internalBattery))
        )
    }
    
    /// Split telemetry points into individual laps
    /// Detects lap boundaries by distance resets or time gaps
    private func splitIntoLaps(_ points: [TelemetryPoint]) -> [Lap] {
        guard !points.isEmpty else { return [] }
        
        var laps: [Lap] = []
        var currentLapPoints: [TelemetryPoint] = []
        var lapNumber = 1
        
        for (index, point) in points.enumerated() {
            currentLapPoints.append(point)
            
            // Check for lap boundary (distance reset or significant time gap)
            if index < points.count - 1 {
                let nextPoint = points[index + 1]
                
                // Distance reset indicates new lap
                let distanceReset = nextPoint.distance < point.distance
                
                // Time gap > 5 seconds indicates new lap
                let timeGap = nextPoint.time - point.time > 5.0
                
                if distanceReset || timeGap {
                    // Create lap
                    if let lap = createLap(number: lapNumber, points: currentLapPoints) {
                        laps.append(lap)
                        lapNumber += 1
                    }
                    currentLapPoints = []
                }
            }
        }
        
        // Add final lap
        if !currentLapPoints.isEmpty {
            if let lap = createLap(number: lapNumber, points: currentLapPoints) {
                laps.append(lap)
            }
        }
        
        return laps
    }
    
    /// Create a Lap from telemetry points
    private func createLap(number: Int, points: [TelemetryPoint]) -> Lap? {
        guard !points.isEmpty else { return nil }
        
        // Calculate lap time (last point time - first point time)
        let lapTime = points.last!.time - points.first!.time
        
        // Only create lap if it has reasonable duration (> 10 seconds)
        guard lapTime > 10.0 else { return nil }
        
        return Lap(
            id: UUID(),
            lapNumber: number,
            time: lapTime,
            telemetryPoints: points
        )
    }
}

// MARK: - Sample Data for Testing

#if DEBUG
extension MyChronCSVParser {
    /// Generate sample CSV string for testing
    static func generateSampleCSV() -> String {
        let header = "\"Time\",\"Distance\",\"Speed\",\"Latitude\",\"Longitude\",\"Altitude\",\"Satellites\",\"Heading\",\"PosAccuracy\",\"SpeedAccuracy\",\"LatAcc\",\"LonAcc\",\"Slope\",\"Gyro\",\"Radius\",\"RPM\",\"ExhaustTemp\",\"WaterTemp\",\"AccelerometerX\",\"AccelerometerY\",\"AccelerometerZ\",\"GyroX\",\"GyroY\",\"GyroZ\",\"LoggerTemp\",\"InternalBattery\""
        
        var lines = [header]
        
        // Generate 100 sample points (5 seconds at 20 Hz)
        for i in 0..<100 {
            let time = Double(i) * 0.05
            let distance = Double(i) * 1.5
            let speed = 60.0 + Double.random(in: -5...5)
            
            let line = "\(time),\(distance),\(speed),41.8266,2.0967,150.0,12,90.0,2.5,0.5,0.5,-0.3,0.0,0.0,0.0,10000,600.0,50.0,0.0,0.0,9.81,0.0,0.0,0.0,35.0,4.2"
            lines.append(line)
        }
        
        return lines.joined(separator: "\n")
    }
}
#endif
