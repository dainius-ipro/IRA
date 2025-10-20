import Foundation

/// Service for calculating delta time between two laps
/// Epic 4: Lap Analysis - IRA-22
class DeltaCalculator {

```
/// Calculate delta time at each point along the track
func calculateDelta(referenceLap: StoredLap, comparisonLap: StoredLap) -> [DeltaPoint] {
    var deltaPoints: [DeltaPoint] = []
    
    // Use reference lap's distance points
    for refPoint in referenceLap.telemetryPoints {
        // Interpolate comparison lap time at this distance
        let compTime = interpolateTime(
            at: refPoint.distance,
            in: comparisonLap.telemetryPoints
        )
        
        // Calculate delta (positive = comparison is slower)
        let delta = compTime - refPoint.time
        
        deltaPoints.append(DeltaPoint(
            distance: refPoint.distance,
            delta: delta,
            referenceTime: refPoint.time,
            comparisonTime: compTime
        ))
    }
    
    return deltaPoints
}

/// Interpolate time at a specific distance
private func interpolateTime(at distance: Double, in points: [StoredTelemetryPoint]) -> Double {
    // Find surrounding points
    guard let before = points.last(where: { $0.distance <= distance }),
          let after = points.first(where: { $0.distance >= distance }) else {
        // Fallback to nearest point
        return points.min(by: { abs($0.distance - distance) < abs($1.distance - distance) })?.time ?? 0
    }
    
    // If exact match, return that time
    if before.distance == distance {
        return before.time
    }
    
    // Linear interpolation
    let distanceRange = after.distance - before.distance
    if distanceRange == 0 {
        return before.time
    }
    
    let ratio = (distance - before.distance) / distanceRange
    return before.time + ratio * (after.time - before.time)
}

/// Calculate cumulative delta over the lap
func cumulativeDelta(_ deltaPoints: [DeltaPoint]) -> Double {
    deltaPoints.last?.delta ?? 0
}

/// Find biggest gains/losses
func significantDeltas(_ deltaPoints: [DeltaPoint]) -> (gains: [DeltaPoint], losses: [DeltaPoint]) {
    // Find points where delta changes significantly
    var gains: [DeltaPoint] = []
    var losses: [DeltaPoint] = []
    
    for i in 1..<deltaPoints.count {
        let deltaChange = deltaPoints[i].delta - deltaPoints[i-1].delta
        
        if deltaChange < -0.1 { // Gaining time (delta decreasing)
            gains.append(deltaPoints[i])
        } else if deltaChange > 0.1 { // Losing time (delta increasing)
            losses.append(deltaPoints[i])
        }
    }
    
    // Sort by magnitude
    gains.sort(by: { abs($0.delta) > abs($1.delta) })
    losses.sort(by: { abs($0.delta) > abs($1.delta) })
    
    return (Array(gains.prefix(5)), Array(losses.prefix(5)))
}
```

}

// MARK: - Supporting Types

struct DeltaPoint: Identifiable {
let id = UUID()
let distance: Double
let delta: Double
let referenceTime: Double
let comparisonTime: Double

```
var isGaining: Bool {
    delta < 0
}

var isLosing: Bool {
    delta > 0
}
```

}