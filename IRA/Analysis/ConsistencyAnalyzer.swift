//
//  ConsistencyAnalyzer.swift
//  RaceAnalytics
//

import Foundation
import SwiftUI

struct ConsistencyAnalyzer {
    
    func calculateConsistencyScore(laps: [StoredLap]) -> Double {
        guard laps.count >= 2 else { return 100 }
        
        let times = laps.map { $0.lapTime }
        let avg = times.reduce(0, +) / Double(times.count)
        let variance = times.reduce(0) { $0 + pow($1 - avg, 2) } / Double(times.count)
        let stdDev = sqrt(variance)
        let variation = stdDev / avg
        let score = max(0, 100 - (variation * 2000))
        
        return min(100, max(0, score))
    }
    
    func interpretScore(_ score: Double) -> (level: String, color: Color, message: String) {
        switch score {
        case 90...100:
            return ("Excellent", .green, "Very consistent lap times. Great job!")
        case 70..<90:
            return ("Good", .orange, "Decent consistency. Room for improvement.")
        default:
            return ("Needs Work", .red, "High variation in lap times. Focus on consistency.")
        }
    }
    
    func findOutliers(laps: [StoredLap]) -> [StoredLap] {
        guard laps.count >= 3 else { return [] }
        
        let times = laps.map { $0.lapTime }
        let avg = times.reduce(0, +) / Double(times.count)
        let variance = times.reduce(0) { $0 + pow($1 - avg, 2) } / Double(times.count)
        let stdDev = sqrt(variance)
        
        return laps.filter { abs($0.lapTime - avg) > stdDev * 2 }
    }
    
    func averageDeviationFromBest(laps: [StoredLap]) -> Double {
        guard !laps.isEmpty else { return 0 }
        guard let bestTime = laps.map({ $0.lapTime }).min() else { return 0 }
        
        let deviations = laps.map { $0.lapTime - bestTime }
        return deviations.reduce(0, +) / Double(deviations.count)
    }
}