import Foundation

/// Parser for MyChron 6T CSV telemetry files
class MyChronCSVParser {

```
enum ParseError: Error {
    case invalidFormat
    case missingHeaders
    case invalidData(line: Int)
}

// MARK: - Public Methods

func parse(_ data: Data) throws -> Session {
    guard let content = String(data: data, encoding: .utf8) else {
        throw ParseError.invalidFormat
    }
    
    let lines = content.components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
    
    guard lines.count > 1 else {
        throw ParseError.invalidFormat
    }
    
    // Parse metadata from first few lines
    let metadata = parseMetadata(lines: lines)
    
    // Find header line
    guard let headerIndex = lines.firstIndex(where: { $0.contains("Time") && $0.contains("Distance") }) else {
        throw ParseError.missingHeaders
    }
    
    let headers = parseHeaders(lines[headerIndex])
    let dataLines = Array(lines[(headerIndex + 1)...])
    
    // Parse telemetry points
    var allPoints: [TelemetryPoint] = []
    for (index, line) in dataLines.enumerated() {
        if let point = try? parseTelemetryPoint(line: line, headers: headers) {
            allPoints.append(point)
        }
    }
    
    // Split into laps based on distance resets
    let laps = splitIntoLaps(points: allPoints)
    
    return Session(
        date: metadata.date,
        vehicle: metadata.vehicle,
        racer: metadata.racer,
        track: metadata.track,
        laps: laps
    )
}

// MARK: - Private Methods

private func parseMetadata(lines: [String]) -> (date: Date, vehicle: String?, racer: String?, track: String?) {
    var date = Date()
    var vehicle: String?
    var racer: String?
    var track: String?
    
    for line in lines.prefix(10) {
        let lower = line.lowercased()
        if lower.contains("date:") {
            // Try to parse date
            let dateStr = line.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let parsed = formatter.date(from: dateStr) {
                date = parsed
            }
        } else if lower.contains("vehicle:") {
            vehicle = line.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
        } else if lower.contains("racer:") {
            racer = line.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
        } else if lower.contains("track:") {
            track = line.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
        }
    }
    
    return (date, vehicle, racer, track)
}

private func parseHeaders(_ line: String) -> [String] {
    return line.components(separatedBy: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
}

private func parseTelemetryPoint(line: String, headers: [String]) throws -> TelemetryPoint {
    let values = line.components(separatedBy: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
    
    guard values.count == headers.count else {
        throw ParseError.invalidData(line: 0)
    }
    
    var dict: [String: String] = [:]
    for (header, value) in zip(headers, values) {
        dict[header] = value
    }
    
    return TelemetryPoint(
        time: Double(dict["Time"] ?? "0") ?? 0,
        distance: Double(dict["Distance"] ?? "0") ?? 0,
        speed: Double(dict["Speed"] ?? "0") ?? 0,
        satellites: Int(dict["Satellites"] ?? "0") ?? 0,
        latAcc: Double(dict["LatAcc"] ?? "0") ?? 0,
        lonAcc: Double(dict["LonAcc"] ?? "0") ?? 0,
        slope: Double(dict["Slope"] ?? "0") ?? 0,
        heading: Double(dict["Heading"] ?? "0") ?? 0,
        gyro: Double(dict["Gyro"] ?? "0") ?? 0,
        altitude: Double(dict["Altitude"] ?? "0") ?? 0,
        posAccuracy: Double(dict["PosAccuracy"] ?? "0") ?? 0,
        speedAccuracy: Double(dict["SpeedAccuracy"] ?? "0") ?? 0,
        radius: Double(dict["Radius"] ?? "0") ?? 0,
        latitude: Double(dict["Latitude"] ?? "0") ?? 0,
        longitude: Double(dict["Longitude"] ?? "0") ?? 0,
        rpm: Int(dict["RPM"] ?? "0") ?? 0,
        exhaustTemp: Double(dict["ExhaustTemp"] ?? "0") ?? 0,
        waterTemp: Double(dict["WaterTemp"] ?? "0") ?? 0,
        accelerometerX: Double(dict["AccelerometerX"] ?? "0") ?? 0,
        accelerometerY: Double(dict["AccelerometerY"] ?? "0") ?? 0,
        accelerometerZ: Double(dict["AccelerometerZ"] ?? "0") ?? 0,
        gyroX: Double(dict["GyroX"] ?? "0") ?? 0,
        gyroY: Double(dict["GyroY"] ?? "0") ?? 0,
        gyroZ: Double(dict["GyroZ"] ?? "0") ?? 0,
        loggerTemp: Double(dict["LoggerTemp"] ?? "0") ?? 0,
        internalBattery: Double(dict["InternalBattery"] ?? "0") ?? 0
    )
}

private func splitIntoLaps(points: [TelemetryPoint]) -> [Lap] {
    var laps: [Lap] = []
    var currentLapPoints: [TelemetryPoint] = []
    var lapNumber = 1
    var lastDistance: Double = 0
    
    for point in points {
        // Detect lap completion when distance resets
        if point.distance < lastDistance && !currentLapPoints.isEmpty {
            // Complete current lap
            if let firstPoint = currentLapPoints.first,
               let lastPoint = currentLapPoints.last {
                let lapTime = lastPoint.time - firstPoint.time
                laps.append(Lap(
                    lapNumber: lapNumber,
                    time: lapTime,
                    telemetryPoints: currentLapPoints
                ))
                lapNumber += 1
            }
            currentLapPoints = []
        }
        
        currentLapPoints.append(point)
        lastDistance = point.distance
    }
    
    // Add final lap
    if !currentLapPoints.isEmpty,
       let firstPoint = currentLapPoints.first,
       let lastPoint = currentLapPoints.last {
        let lapTime = lastPoint.time - firstPoint.time
        laps.append(Lap(
            lapNumber: lapNumber,
            time: lapTime,
            telemetryPoints: currentLapPoints
        ))
    }
    
    return laps
}
```

}