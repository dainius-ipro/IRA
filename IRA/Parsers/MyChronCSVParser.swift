import Foundation

// MARK: - Parser Errors
enum MyChronParserError: LocalizedError {
    case emptyFile
    case invalidFormat
    case noValidData
    case invalidHeader
    case missingRequiredColumns([String])
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "CSV file is empty"
        case .invalidFormat:
            return "Invalid CSV format"
        case .noValidData:
            return "No valid telemetry data found"
        case .invalidHeader:
            return "CSV headers do not match expected format"
        case .missingRequiredColumns(let columns):
            return "Missing required columns: \(columns.joined(separator: ", "))"
        }
    }
}

// MARK: - MyChron CSV Parser
class MyChronCSVParser {
    
    // MARK: - Metadata
    struct Metadata {
        var vehicle: String?
        var racer: String?
        var track: String?
        var date: Date?
    }
    
    // MARK: - Parse Main Method
    func parse(_ data: Data) throws -> Session {
        print("\n🚀 ========== ULTIMATE PARSER START ==========")
        print("📦 Data size: \(data.count) bytes")
        
        // Try multiple encodings
        guard let csvString = tryDecoding(data) else {
            throw MyChronParserError.invalidFormat
        }
        
        print("✅ UTF-8 encoding successful")
        print("📄 CSV length: \(csvString.count) characters")
        
        let lines = csvString.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        print("📊 Total non-empty lines: \(lines.count)")
        
        guard !lines.isEmpty else {
            throw MyChronParserError.emptyFile
        }
        
        // Parse metadata from first 13 lines
        let metadata = parseMetadata(lines: Array(lines.prefix(13)))
        print("📋 Metadata parsed:")
        print("   Track: \(metadata.track ?? "nil")")
        print("   Racer: \(metadata.racer ?? "nil")")
        print("   Vehicle: \(metadata.vehicle ?? "nil")")
        
        // Find beacon markers line (search for "Beacon Markers")
        var beaconTimes: [Double] = []
        for (index, line) in lines.enumerated() {
            if line.lowercased().contains("beacon markers") {
                beaconTimes = parseBeaconMarkers(line: line)
                print("\n🎯 Beacon markers found at line \(index + 1): \(beaconTimes.count)")
                if !beaconTimes.isEmpty {
                    let timesString = beaconTimes.prefix(5).map { String(format: "%.3f", $0) }.joined(separator: ", ")
                    print("   Times: \(timesString)\(beaconTimes.count > 5 ? "..." : "")")
                }
                break
            }
        }
        
        // Find header row (search for line starting with "Time,")
        guard let headerIndex = findHeaderIndex(lines: lines) else {
            print("❌ Header row NOT found!")
            throw MyChronParserError.invalidHeader
        }
        
        print("\n✅ Header row found at line \(headerIndex + 1)")
        let headers = parseHeaders(line: lines[headerIndex])
        print("📑 Headers found: \(headers.count) columns")
        
        // Data starts at headerIndex + 2 (skip units row!)
        guard lines.count > headerIndex + 2 else {
            throw MyChronParserError.noValidData
        }
        
        let dataStartIndex = headerIndex + 2
        let dataLines = Array(lines[dataStartIndex...])
        
        print("📍 Data lines to parse: \(dataLines.count)")
        
        // Parse telemetry points
        let points = parseTelemetryPoints(dataLines: dataLines, headers: headers)
        print("📍 Total telemetry points parsed: \(points.count)")
        
        guard !points.isEmpty else {
            throw MyChronParserError.noValidData
        }
        
        // Split into laps using beacon markers
        let laps: [Lap]
        if !beaconTimes.isEmpty {
            laps = splitIntoLaps(points: points, beaconTimes: beaconTimes)
            print("\n🏁 Laps created using beacon markers: \(laps.count)")
        } else {
            // Fallback: single lap
            let lap = Lap(
                id: UUID(),
                lapNumber: 1,
                time: points.last?.time ?? 0,
                telemetryPoints: points
            )
            laps = [lap]
            print("\n🏁 Single lap created (no beacons): 1 lap")
        }
        
        // Print lap summary
        for (_, lap) in laps.prefix(5).enumerated() {
            print("  Lap \(lap.lapNumber): \(String(format: "%.3f", lap.time))s, \(lap.telemetryPoints.count) points")
        }
        if laps.count > 5 {
            print("  ... and \(laps.count - 5) more laps")
        }
        
        // Create session
        let session = Session(
            id: UUID(),
            date: metadata.date ?? Date(),
            vehicle: metadata.vehicle,
            racer: metadata.racer,
            track: metadata.track,
            laps: laps
        )
        
        print("\n✅ Session parsed successfully!")
        print("   Track: \(session.track ?? "Unknown")")
        print("   Racer: \(session.racer ?? "Unknown")")
        print("   Vehicle: \(session.vehicle ?? "Unknown")")
        print("   Laps: \(session.laps.count)")
        let totalDuration = session.laps.reduce(0) { $0 + $1.time }
        print("   Duration: \(String(format: "%.1f", totalDuration))s")
        print("========== PARSER END ==========\n")
        
        return session
    }
    
    // MARK: - Try Multiple Encodings
    private func tryDecoding(_ data: Data) -> String? {
        // Try UTF-8
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        // Try ISO Latin 1
        if let string = String(data: data, encoding: .isoLatin1) {
            return string
        }
        
        // Try ASCII
        if let string = String(data: data, encoding: .ascii) {
            return string
        }
        
        return nil
    }
    
    // MARK: - Find Header Index
    private func findHeaderIndex(lines: [String]) -> Int? {
        // Search for line starting with "Time," and having many columns
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Time,") || trimmed.hasPrefix("\"Time\"") {
                // Verify it has enough columns (should be 26)
                let columnCount = line.components(separatedBy: ",").count
                if columnCount >= 20 {  // At least 20 columns means it's the real header
                    return index
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Parse Metadata
    private func parseMetadata(lines: [String]) -> Metadata {
        var metadata = Metadata()
        
        for line in lines {
            // ✅ FIXED: Use comma separator for Troy's CSV format
            // Format: Session,"Osona2"
            let parts = line.components(separatedBy: ",")
            guard parts.count >= 2 else { continue }
            
            let key = parts[0].trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: "\"")))
                .lowercased()
            let value = parts[1].trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: "\"")))
            
            switch key {
            case "session", "track":
                metadata.track = value.isEmpty ? nil : value
            case "racer":
                metadata.racer = value.isEmpty ? nil : value
            case "vehicle":
                metadata.vehicle = value.isEmpty ? nil : value
            case "date":
                metadata.date = parseDate(value)
            default:
                break
            }
        }
        
        return metadata
    }
    
    // MARK: - Parse Beacon Markers
    private func parseBeaconMarkers(line: String) -> [Double] {
        // ✅ FIXED: Use comma separator
        // Format: Beacon Markers,"20.803","113.42","202.244","242.997"
        let parts = line.components(separatedBy: ",")
        
        guard parts.count > 1 else {
            return []
        }
        
        // Skip first element ("Beacon Markers"), parse rest as doubles
        return parts.dropFirst().compactMap {
            let cleaned = $0.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: "\"")))
            return Double(cleaned)
        }
    }
    
    // MARK: - Parse Headers
    private func parseHeaders(line: String) -> [String] {
        return line.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: "\""))) }
    }
    
    // MARK: - Parse Telemetry Points
    private func parseTelemetryPoints(dataLines: [String], headers: [String]) -> [TelemetryPoint] {
        var points: [TelemetryPoint] = []
        
        for line in dataLines {
            let values = line.components(separatedBy: ",")
            
            guard values.count == headers.count else {
                continue
            }
            
            // Build dictionary
            var dict: [String: String] = [:]
            for (index, header) in headers.enumerated() {
                let cleanValue = values[index].trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: "\"")))
                dict[header] = cleanValue
            }
            
            // Parse required fields with flexible matching
            // ✅ FIXED: Added "Distance on GPS Speed" to match Troy's CSV
            guard let time = getDouble(dict, keys: ["Time", "time"]),
                  let distance = getDouble(dict, keys: ["Distance on GPS Speed", "Distance", "distance"]) else {
                continue
            }
            
            // Parse all telemetry parameters with correct column names
            // ✅ FIXED: Using exact column names from Troy's CSV (with spaces!)
            
            // System parameters (first in init order!)
            let loggerTemp = getDouble(dict, keys: ["Logger Temperature", "LoggerTemp", "logger_temp"])
            let internalBattery = getDouble(dict, keys: ["Internal Batt", "InternalBattery", "battery"])
            
            // GPS parameters
            let speed = getDouble(dict, keys: ["GPS Speed", "Speed", "speed"])
            let satellites = getInt(dict, keys: ["GPS Nsat", "GPS_Satellites", "Satellites", "satellites"])
            let latitude = getDouble(dict, keys: ["GPS Latitude", "GPS_Latitude", "Latitude", "latitude"])
            let longitude = getDouble(dict, keys: ["GPS Longitude", "GPS_Longitude", "Longitude", "longitude"])
            let altitude = getDouble(dict, keys: ["GPS Altitude", "GPS_Altitude", "Altitude", "altitude"])
            let heading = getDouble(dict, keys: ["GPS Heading", "GPS_Heading", "Heading", "heading"])
            let slope = getDouble(dict, keys: ["GPS Slope", "GPS_Slope", "Slope", "slope"])
            let latAcc = getDouble(dict, keys: ["GPS LatAcc", "GPS_LatAcc", "LatAcc", "lat_acc"])
            let lonAcc = getDouble(dict, keys: ["GPS LonAcc", "GPS_LonAcc", "LonAcc", "lon_acc"])
            let gyro = getDouble(dict, keys: ["GPS Gyro", "GPS_Gyro", "Gyro", "gyro"])
            let radius = getDouble(dict, keys: ["GPS Radius", "GPS_Radius", "Radius", "radius"])
            let posAccuracy = getDouble(dict, keys: ["GPS PosAccuracy", "GPS_PosAccuracy", "PosAccuracy", "pos_accuracy"])
            let speedAccuracy = getDouble(dict, keys: ["GPS SpdAccuracy", "GPS_SpeedAccuracy", "SpeedAccuracy", "speed_accuracy"])
            
            // Engine parameters
            let rpm = getInt(dict, keys: ["RPM", "rpm"])
            let exhaustTemp = getDouble(dict, keys: ["Exhaust Temp", "T_Exhaust", "ExhaustTemp", "exhaust_temp"])
            let waterTemp = getDouble(dict, keys: ["Water Temp", "T_Water", "WaterTemp", "water_temp"])
            
            // Motion parameters
            let accelerometerX = getDouble(dict, keys: ["AccelerometerX", "AccX", "acc_x"])
            let accelerometerY = getDouble(dict, keys: ["AccelerometerY", "AccY", "acc_y"])
            let accelerometerZ = getDouble(dict, keys: ["AccelerometerZ", "AccZ", "acc_z"])
            let gyroX = getDouble(dict, keys: ["GyroX", "gyro_x"])
            let gyroY = getDouble(dict, keys: ["GyroY", "gyro_y"])
            let gyroZ = getDouble(dict, keys: ["GyroZ", "gyro_z"])
            
            // ✅ FIXED: Create telemetry point with correct parameter order matching TelemetryPoint init!
            let point = TelemetryPoint(
                time: time,
                distance: distance,
                loggerTemp: loggerTemp,
                internalBattery: internalBattery,
                speed: speed,
                satellites: satellites,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                heading: heading,
                slope: slope,
                latAcc: latAcc,
                lonAcc: lonAcc,
                gyro: gyro,
                radius: radius,
                posAccuracy: posAccuracy,
                speedAccuracy: speedAccuracy,
                rpm: rpm,
                exhaustTemp: exhaustTemp,
                waterTemp: waterTemp,
                accelX: accelerometerX,
                accelY: accelerometerY,
                accelZ: accelerometerZ,
                gyroX: gyroX,
                gyroY: gyroY,
                gyroZ: gyroZ
            )
            
            // Skip invalid GPS points (0, 0)
            if let lat = point.latitude, let lon = point.longitude,
               lat == 0 && lon == 0 {
                continue
            }
            
            points.append(point)
        }
        
        return points
    }
    
    // MARK: - Split Into Laps
    private func splitIntoLaps(points: [TelemetryPoint], beaconTimes: [Double]) -> [Lap] {
        guard !beaconTimes.isEmpty else {
            return []
        }
        
        var laps: [Lap] = []
        var currentLapPoints: [TelemetryPoint] = []
        var beaconIndex = 0
        var lapNumber = 1
        
        for point in points {
            currentLapPoints.append(point)
            
            // Check if we've reached the next beacon
            if beaconIndex < beaconTimes.count && point.time >= beaconTimes[beaconIndex] {
                // Create lap
                if !currentLapPoints.isEmpty {
                    let lapTime = currentLapPoints.last?.time ?? 0
                    let lap = Lap(
                        id: UUID(),
                        lapNumber: lapNumber,
                        time: lapTime,
                        telemetryPoints: currentLapPoints
                    )
                    laps.append(lap)
                    lapNumber += 1
                    currentLapPoints = []
                }
                beaconIndex += 1
            }
        }
        
        // Add remaining points as final lap if any
        if !currentLapPoints.isEmpty {
            let lapTime = currentLapPoints.last?.time ?? 0
            let lap = Lap(
                id: UUID(),
                lapNumber: lapNumber,
                time: lapTime,
                telemetryPoints: currentLapPoints
            )
            laps.append(lap)
        }
        
        return laps
    }
    
    // MARK: - Helper Methods
    private func getDouble(_ dict: [String: String], keys: [String]) -> Double? {
        for key in keys {
            if let value = dict[key], let double = Double(value) {
                return double
            }
        }
        return nil
    }
    
    private func getInt(_ dict: [String: String], keys: [String]) -> Int? {
        for key in keys {
            if let value = dict[key], let int = Int(value) {
                return int
            }
        }
        return nil
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.date(from: dateString)
    }
}
