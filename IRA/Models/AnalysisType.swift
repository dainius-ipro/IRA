//
//  AnalysisType.swift
//  RaceAnalytics
//
//  Epic 5 - AI Coaching Analysis Types
//

import Foundation

enum AnalysisType: String, CaseIterable, Identifiable, Codable {
    case overall = "Overall Performance"
    case braking = "Braking Zones"
    case apex = "Apex Trajectory"
    case acceleration = "Acceleration Zones"
    case consistency = "Lap Consistency"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .overall: return "sparkles"
        case .braking: return "brake.signal"
        case .apex: return "point.topleft.down.curvedto.point.bottomright.up"
        case .acceleration: return "speedometer"
        case .consistency: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var description: String {
        switch self {
        case .overall:
            return "Complete lap analysis covering all performance aspects"
        case .braking:
            return "Braking point optimization and deceleration zones"
        case .apex:
            return "Corner entry, apex positioning, and exit trajectory"
        case .acceleration:
            return "Throttle application and traction zones"
        case .consistency:
            return "Lap-to-lap consistency and repeatability metrics"
        }
    }
}