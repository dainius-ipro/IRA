// TelemetryPromptFormatter.swift
import Foundation

/// Formats telemetry data into structured prompts for Claude AI analysis
struct TelemetryPromptFormatter {
    
    /// Format a lap's telemetry data for AI analysis
    static func formatLapForAnalysis(_ lap: Lap, context: AnalysisContext) -> String {
        var prompt = """
        # Lap Analysis Request
        
        ## Session Context
        - Track: \(context.trackName ?? "Unknown")
        - Lap Number: \(lap.lapNumber)
        - Lap Time: \(formatTime(lap.time))
        - Data Points: \(lap.telemetryPoints.count)
        
        ## Performance Summary
        - Max Speed: \(String(format: "%.1f", lap.maxSpeed)) km/h
        - Average Speed: \(String(format: "%.1f", lap.averageSpeed)) km/h
        - Max RPM: \(lap.maxRPM)
        - Average RPM: \(String(format: "%.0f", lap.averageRPM))
        - Max Lateral G: \(String(format: "%.2f", lap.maxLatAcc))g
        - Max Longitudinal G: \(String(format: "%.2f", lap.maxLonAcc))g
        
        """
        
        // Add braking zones if requested
        if context.includeBrakingZones {
            prompt += formatBrakingZones(lap)
        }
        
        // Add cornering analysis if requested
        if context.includeCorneringAnalysis {
            prompt += formatCorneringAnalysis(lap)
        }
        
        // Add comparison if reference lap provided
        if let referenceLap = context.referenceLap {
            prompt += formatLapComparison(lap, reference: referenceLap)
        }
        
        prompt += """
        
        ## Analysis Request
        \(context.specificQuestion ?? "Please analyze this lap and provide coaching feedback on areas for improvement.")
        """
        
        return prompt
    }
    
    /// Format two laps for comparison analysis
    static func formatLapComparison(_ currentLap: Lap, reference referenceLap: Lap) -> String {
        let timeDelta = currentLap.time - referenceLap.time
        let deltaSign = timeDelta > 0 ? "+" : ""
        
        return """
        
        ## Lap Comparison
        - Current Lap: \(formatTime(currentLap.time))
        - Reference Lap: \(formatTime(referenceLap.time))
        - Delta: \(deltaSign)\(String(format: "%.3f", timeDelta))s
        
        ### Speed Comparison
        - Current Max: \(String(format: "%.1f", currentLap.maxSpeed)) km/h
        - Reference Max: \(String(format: "%.1f", referenceLap.maxSpeed)) km/h
        - Current Avg: \(String(format: "%.1f", currentLap.averageSpeed)) km/h
        - Reference Avg: \(String(format: "%.1f", referenceLap.averageSpeed)) km/h
        
        """
    }
    
    /// Format braking zones from telemetry data
    private static func formatBrakingZones(_ lap: Lap) -> String {
        let brakingZones = detectBrakingZones(lap)
        
        guard !brakingZones.isEmpty else {
            return "\n## Braking Zones\nNo significant braking zones detected.\n"
        }
        
        var output = "\n## Braking Zones (\(brakingZones.count) detected)\n"
        
        for (index, zone) in brakingZones.enumerated() {
            output += """
            
            ### Zone \(index + 1)
            - Entry Speed: \(String(format: "%.1f", zone.entrySpeed)) km/h
            - Minimum Speed: \(String(format: "%.1f", zone.minSpeed)) km/h
            - Peak Deceleration: \(String(format: "%.2f", zone.peakDecel))g
            - Distance: \(String(format: "%.0f", zone.distance))m
            
            """
        }
        
        return output
    }
    
    /// Format cornering analysis
    private static func formatCorneringAnalysis(_ lap: Lap) -> String {
        let corners = detectCorners(lap)
        
        guard !corners.isEmpty else {
            return "\n## Cornering Analysis\nNo significant corners detected.\n"
        }
        
        var output = "\n## Cornering Analysis (\(corners.count) corners)\n"
        
        for (index, corner) in corners.enumerated() {
            output += """
            
            ### Corner \(index + 1)
            - Entry Speed: \(String(format: "%.1f", corner.entrySpeed)) km/h
            - Apex Speed: \(String(format: "%.1f", corner.apexSpeed)) km/h
            - Exit Speed: \(String(format: "%.1f", corner.exitSpeed)) km/h
            - Lateral G: \(String(format: "%.2f", corner.maxLatG))g
            - Type: \(corner.direction.rawValue)
            
            """
        }
        
        return output
    }
    
    // MARK: - Helper Functions
    
    private static func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = seconds.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%06.3f", minutes, secs)
    }
    
    private static func detectBrakingZones(_ lap: Lap) -> [BrakingZone] {
        var zones: [BrakingZone] = []
        var currentZone: BrakingZone?
        
        for (index, point) in lap.telemetryPoints.enumerated() {
            guard let lonAcc = point.lonAcc, let speed = point.speed else { continue }
            
            // Braking detected (negative longitudinal acceleration)
            if lonAcc < -0.5 {
                if currentZone == nil {
                    currentZone = BrakingZone(
                        startIndex: index,
                        entrySpeed: speed,  // ✅ Unwrapped
                        minSpeed: speed,    // ✅ Unwrapped
                        peakDecel: abs(lonAcc),
                        distance: 0
                    )
                } else if var zone = currentZone {
                    // Update zone with new minimum speed and peak decel
                    zone.minSpeed = min(zone.minSpeed, speed)
                    zone.peakDecel = max(zone.peakDecel, abs(lonAcc))
                    currentZone = zone
                }
            } else if let zone = currentZone {
                // Braking ended
                let endIndex = index
                let distance = lap.telemetryPoints[endIndex].distance - lap.telemetryPoints[zone.startIndex].distance
                var finalZone = zone
                finalZone.distance = distance
                zones.append(finalZone)
                currentZone = nil
            }
        }
        
        return zones
    }
    
    private static func detectCorners(_ lap: Lap) -> [Corner] {
        var corners: [Corner] = []
        var currentCorner: Corner?
        
        for (index, point) in lap.telemetryPoints.enumerated() {
            guard let latAcc = point.latAcc, let speed = point.speed else { continue }
            
            // Corner detected (significant lateral acceleration)
            if abs(latAcc) > 0.5 {
                if currentCorner == nil {
                    let direction: CornerDirection = latAcc > 0 ? .right : .left
                    currentCorner = Corner(
                        startIndex: index,
                        entrySpeed: speed,  // ✅ Unwrapped
                        apexSpeed: speed,   // ✅ Unwrapped
                        exitSpeed: speed,   // ✅ Unwrapped
                        maxLatG: abs(latAcc),
                        direction: direction
                    )
                } else if var corner = currentCorner {
                    // Update corner with apex speed and max lateral G
                    corner.apexSpeed = min(corner.apexSpeed, speed)
                    corner.maxLatG = max(corner.maxLatG, abs(latAcc))
                    currentCorner = corner
                }
            } else if let corner = currentCorner, let speed = point.speed {
                // Corner ended
                var finalCorner = corner
                finalCorner.exitSpeed = speed  // ✅ Unwrapped
                corners.append(finalCorner)
                currentCorner = nil
            }
        }
        
        return corners
    }
}

// MARK: - Supporting Types

struct AnalysisContext {
    let trackName: String?
    let includeBrakingZones: Bool
    let includeCorneringAnalysis: Bool
    let referenceLap: Lap?
    let specificQuestion: String?
    
    init(
        trackName: String? = nil,
        includeBrakingZones: Bool = true,
        includeCorneringAnalysis: Bool = true,
        referenceLap: Lap? = nil,
        specificQuestion: String? = nil
    ) {
        self.trackName = trackName
        self.includeBrakingZones = includeBrakingZones
        self.includeCorneringAnalysis = includeCorneringAnalysis
        self.referenceLap = referenceLap
        self.specificQuestion = specificQuestion
    }
}

struct BrakingZone {
    let startIndex: Int
    let entrySpeed: Double   // ✅ Non-optional - we unwrap when creating
    var minSpeed: Double     // ✅ Non-optional
    var peakDecel: Double    // ✅ Non-optional
    var distance: Double     // ✅ Non-optional
}

struct Corner {
    let startIndex: Int
    let entrySpeed: Double   // ✅ Non-optional - we unwrap when creating
    var apexSpeed: Double    // ✅ Non-optional
    var exitSpeed: Double    // ✅ Non-optional
    var maxLatG: Double      // ✅ Non-optional
    let direction: CornerDirection
}

enum CornerDirection: String {
    case left = "Left"
    case right = "Right"
}
