//
//  TelemetryFormatter.swift
//  RaceAnalytics
//
//  Epic 5 - IRA-27: Format Telemetry for AI Prompts
//

import Foundation

struct TelemetryFormatter {
    
    // MARK: - Lap Summary
    
    static func formatLapSummary(_ lap: Lap, track: String? = nil) -> String {
        let stats = calculateLapStats(lap)
        
        var summary = """
        LAP SUMMARY
        -----------
        Lap Number: \(lap.lapNumber)
        Lap Time: \(formatTime(lap.time))
        Track: \(track ?? "Unknown")
        
        PERFORMANCE METRICS
        ------------------
        Speed (km/h):
        - Maximum: \(String(format: "%.1f", stats.maxSpeed))
        - Average: \(String(format: "%.1f", stats.avgSpeed))
        - Minimum: \(String(format: "%.1f", stats.minSpeed))
        
        G-Forces:
        - Max Lateral: \(String(format: "%.2f", stats.maxLatAcc))G
        - Max Longitudinal: \(String(format: "%.2f", stats.maxLonAcc))G
        - Peak Combined: \(String(format: "%.2f", stats.peakGForce))G
        
        Engine (IAME X30 Junior):
        - RPM Range: \(Int(stats.minRPM)) - \(Int(stats.maxRPM))
        - Avg RPM: \(Int(stats.avgRPM))
        - Time in Power Band: \(String(format: "%.1f", stats.timeInPowerBand))%
        
        Temperature:
        - Exhaust: \(String(format: "%.0f", stats.avgExhaustTemp))°C
        - Water: \(String(format: "%.0f", stats.avgWaterTemp))°C
        
        Data Quality:
        - Total Points: \(lap.telemetryPoints.count)
        - Sample Rate: 20Hz
        - Distance: \(String(format: "%.0f", lap.telemetryPoints.last?.distance ?? 0))m
        """
        
        return summary
    }
    
    // MARK: - Braking Zones
    
    static func formatBrakingZones(_ lap: Lap) -> String {
        let zones = detectBrakingZones(lap)
        
        var output = """
        BRAKING ANALYSIS
        ---------------
        Total Braking Zones: \(zones.count)
        
        """
        
        for (index, zone) in zones.enumerated() {
            output += """
            Zone \(index + 1):
            - Entry Speed: \(String(format: "%.1f", zone.entrySpeed)) km/h
            - Exit Speed: \(String(format: "%.1f", zone.exitSpeed)) km/h
            - Speed Delta: \(String(format: "%.1f", zone.speedDelta)) km/h
            - Duration: \(String(format: "%.2f", zone.duration))s
            - Distance: \(String(format: "%.0f", zone.startDistance))m - \(String(format: "%.0f", zone.endDistance))m
            - Max Braking G: \(String(format: "%.2f", zone.maxBrakingG))G
            - Efficiency: \(zone.efficiency)
            
            """
        }
        
        return output
    }
    
    // MARK: - Apex Analysis
    
    static func formatApexAnalysis(_ lap: Lap) -> String {
        let corners = detectCorners(lap)
        
        var output = """
        APEX ANALYSIS
        ------------
        Corners Detected: \(corners.count)
        
        """
        
        for (index, corner) in corners.enumerated() {
            output += """
            Corner \(index + 1):
            - Entry Speed: \(String(format: "%.1f", corner.entrySpeed)) km/h
            - Apex Speed: \(String(format: "%.1f", corner.apexSpeed)) km/h
            - Exit Speed: \(String(format: "%.1f", corner.exitSpeed)) km/h
            - Turn Radius: \(String(format: "%.1f", corner.turnRadius))m
            - Lateral G at Apex: \(String(format: "%.2f", corner.apexLateralG))G
            - Distance: \(String(format: "%.0f", corner.apexDistance))m
            - Line Quality: \(corner.lineQuality)
            
            """
        }
        
        return output
    }
    
    // MARK: - 2-Lap Comparison
    
    static func formatLapComparison(reference: Lap, comparison: Lap) -> String {
        let refStats = calculateLapStats(reference)
        let compStats = calculateLapStats(comparison)
        
        let timeDelta = comparison.time - reference.time
        let deltaSymbol = timeDelta > 0 ? "+" : ""
        
        return """
        LAP COMPARISON
        -------------
        Reference Lap: \(reference.lapNumber) (\(formatTime(reference.time)))
        Comparison Lap: \(comparison.lapNumber) (\(formatTime(comparison.time)))
        Delta: \(deltaSymbol)\(formatTime(abs(timeDelta)))
        
        SPEED COMPARISON
        ---------------
        Max Speed: \(formatDelta(compStats.maxSpeed - refStats.maxSpeed)) km/h
        Avg Speed: \(formatDelta(compStats.avgSpeed - refStats.avgSpeed)) km/h
        
        G-FORCE COMPARISON
        -----------------
        Peak G: \(formatDelta(compStats.peakGForce - refStats.peakGForce))G
        Max Lat: \(formatDelta(compStats.maxLatAcc - refStats.maxLatAcc))G
        Max Lon: \(formatDelta(compStats.maxLonAcc - refStats.maxLonAcc))G
        
        ENGINE COMPARISON
        ----------------
        Avg RPM: \(formatDelta(compStats.avgRPM - refStats.avgRPM, decimals: 0)) RPM
        Time in Power Band: \(formatDelta(compStats.timeInPowerBand - refStats.timeInPowerBand))%
        
        KEY DIFFERENCES
        --------------
        The comparison lap was \(timeDelta > 0 ? "slower" : "faster") by \(formatTime(abs(timeDelta))).
        """
    }
    
    // MARK: - Helper Methods
    
    private static func calculateLapStats(_ lap: Lap) -> LapStats {
        let points = lap.telemetryPoints
        guard !points.isEmpty else { return LapStats() }
        
        let speeds = points.compactMap { $0.speed }
        let rpms = points.compactMap { $0.rpm }.map { Double($0) }
        let latAccs = points.compactMap { $0.latAcc }.map { abs($0) }
        let lonAccs = points.compactMap { $0.lonAcc }.map { abs($0) }
        let gForces = points.compactMap { point -> Double? in
            guard let lat = point.latAcc, let lon = point.lonAcc else { return nil }
            return sqrt(lat * lat + lon * lon)
        }
        let exhaustTemps = points.compactMap { $0.exhaustTemp }
        let waterTemps = points.compactMap { $0.waterTemp }
        
        let pointsInPowerBand = points.filter { 
            guard let rpm = $0.rpm else { return false }
            return rpm >= 10000 && rpm <= 13500 
        }.count
        let timeInPowerBand = (Double(pointsInPowerBand) / Double(points.count)) * 100.0
        
        return LapStats(
            maxSpeed: speeds.max() ?? 0,
            avgSpeed: speeds.isEmpty ? 0 : speeds.reduce(0, +) / Double(speeds.count),
            minSpeed: speeds.min() ?? 0,
            maxRPM: rpms.max() ?? 0,
            avgRPM: rpms.isEmpty ? 0 : rpms.reduce(0, +) / Double(rpms.count),
            minRPM: rpms.min() ?? 0,
            maxLatAcc: latAccs.max() ?? 0,
            maxLonAcc: lonAccs.max() ?? 0,
            peakGForce: gForces.max() ?? 0,
            avgExhaustTemp: exhaustTemps.isEmpty ? 0 : exhaustTemps.reduce(0, +) / Double(exhaustTemps.count),
            avgWaterTemp: waterTemps.isEmpty ? 0 : waterTemps.reduce(0, +) / Double(waterTemps.count),
            timeInPowerBand: timeInPowerBand
        )
    }
    
    private static func detectBrakingZones(_ lap: Lap) -> [TelemetryBrakingZone] {
        var zones: [TelemetryBrakingZone] = []
        var inBraking = false
        var zoneStart: TelemetryPoint?
        
        for i in 0..<lap.telemetryPoints.count - 1 {
            let current = lap.telemetryPoints[i]
            let next = lap.telemetryPoints[i + 1]
            
            guard let currentSpeed = current.speed,
                  let nextSpeed = next.speed,
                  let currentLonAcc = current.lonAcc else {
                continue
            }
            
            let speedDelta = nextSpeed - currentSpeed
            let isBraking = speedDelta < -5.0 && currentLonAcc < -0.3
            
            if isBraking && !inBraking {
                zoneStart = current
                inBraking = true
            } else if !isBraking && inBraking {
                if let start = zoneStart {
                    let startIdx = max(0, i - 10)
                    let endIdx = min(lap.telemetryPoints.count - 1, i)
                    let zone = TelemetryBrakingZone(
                        start: start,
                        end: current,
                        points: Array(lap.telemetryPoints[startIdx...endIdx])
                    )
                    zones.append(zone)
                }
                inBraking = false
                zoneStart = nil
            }
        }
        
        return zones
    }
    
    private static func detectCorners(_ lap: Lap) -> [TelemetryCorner] {
        var corners: [TelemetryCorner] = []
        
        for i in 10..<lap.telemetryPoints.count - 10 {
            let point = lap.telemetryPoints[i]
            
            guard let latAcc = point.latAcc,
                  let speed = point.speed else {
                continue
            }
            
            if abs(latAcc) > 0.8 && speed < 80 {
                let entry = lap.telemetryPoints[i - 5]
                let exit = lap.telemetryPoints[i + 5]
                
                let corner = TelemetryCorner(
                    apex: point,
                    entry: entry,
                    exit: exit
                )
                corners.append(corner)
            }
        }
        
        return corners
    }
    
    private static func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds / 60)
        let secs = seconds.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%06.3f", mins, secs)
    }
    
    private static func formatDelta(_ value: Double, decimals: Int = 1) -> String {
        let format = "%.\(decimals)f"
        let symbol = value >= 0 ? "+" : ""
        return "\(symbol)\(String(format: format, value))"
    }
}

// MARK: - Supporting Types

struct LapStats {
    var maxSpeed: Double = 0
    var avgSpeed: Double = 0
    var minSpeed: Double = 0
    var maxRPM: Double = 0
    var avgRPM: Double = 0
    var minRPM: Double = 0
    var maxLatAcc: Double = 0
    var maxLonAcc: Double = 0
    var peakGForce: Double = 0
    var avgExhaustTemp: Double = 0
    var avgWaterTemp: Double = 0
    var timeInPowerBand: Double = 0
}

struct TelemetryBrakingZone {
    let start: TelemetryPoint
    let end: TelemetryPoint
    let points: [TelemetryPoint]
    
    var entrySpeed: Double { start.speed ?? 0 }
    var exitSpeed: Double { end.speed ?? 0 }
    var speedDelta: Double { entrySpeed - exitSpeed }
    var duration: Double { end.time - start.time }
    var startDistance: Double { start.distance }
    var endDistance: Double { end.distance }
    var maxBrakingG: Double {
        points.compactMap { $0.lonAcc }.map { abs($0) }.max() ?? 0
    }
    var efficiency: String {
        if maxBrakingG > 1.2 { return "Excellent" }
        if maxBrakingG > 0.8 { return "Good" }
        return "Needs Improvement"
    }
}

struct TelemetryCorner {
    let apex: TelemetryPoint
    let entry: TelemetryPoint
    let exit: TelemetryPoint
    
    var entrySpeed: Double { entry.speed ?? 0 }
    var apexSpeed: Double { apex.speed ?? 0 }
    var exitSpeed: Double { exit.speed ?? 0 }
    var apexDistance: Double { apex.distance }
    var apexLateralG: Double { abs(apex.latAcc ?? 0) }
    var turnRadius: Double {
        let v = apexSpeed / 3.6
        let g = 9.81
        let lateralG = abs(apex.latAcc ?? 0.1)
        guard lateralG > 0 else { return 0 }
        return (v * v) / (g * lateralG)
    }
    var lineQuality: String {
        let speedGain = exitSpeed - entrySpeed
        if speedGain > 5 { return "Excellent exit" }
        if speedGain > 0 { return "Good" }
        return "Losing speed through corner"
    }
}
