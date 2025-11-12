//
//  CoachingInsight.swift
//  RaceAnalytics
//
//  Epic 5 - AI Coaching Insight Model
//

import Foundation

struct CoachingInsight: Identifiable, Codable {
    let id: UUID
    let type: AnalysisType
    let text: String
    let timestamp: Date
    let telemetrySnapshot: String
    
    init(type: AnalysisType, text: String, timestamp: Date, telemetrySnapshot: String) {
        self.id = UUID()
        self.type = type
        self.text = text
        self.timestamp = timestamp
        self.telemetrySnapshot = telemetrySnapshot
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}