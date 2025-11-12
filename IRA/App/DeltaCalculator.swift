//
//  DeltaCalculator.swift
//  RaceAnalytics
//

import Foundation

struct DeltaCalculator {
    
    func calculateDelta(reference: StoredLap, comparison: StoredLap) -> [DeltaPoint] {
        // Simplified - return empty for now
        return []
    }
}

struct DeltaPoint {
    let distance: Double
    let timeDelta: Double
}