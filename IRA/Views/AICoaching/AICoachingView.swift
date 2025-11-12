//
//  AICoachingView.swift
//  RaceAnalytics
//
//  Epic 5 - IRA-28 & IRA-29: AI Coaching Analysis
//  Main view for AI-powered coaching insights
//

import SwiftUI

struct AICoachingView: View {
    let session: Session
    @State private var selectedLap: Lap?
    @State private var selectedAnalysisType: AnalysisType = .overall
    @State private var isAnalyzing = false
    @State private var currentInsight: CoachingInsight?
    @State private var cachedInsights: [CoachingInsight] = []
    @State private var errorMessage: String?
    @State private var showAPIKeyAlert = false
    
    private let apiService = ClaudeAPIService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Lap Selector
                lapSelectorView
                
                // Analysis Type Selector
                analysisTypeSelectorView
                
                // Current Insight or Loading
                if isAnalyzing {
                    loadingView
                } else if let insight = currentInsight {
                    insightCard(insight)
                } else {
                    emptyStateView
                }
                
                // Cached Insights History
                if !cachedInsights.isEmpty {
                    cachedInsightsSection
                }
                
                // Error Display
                if let error = errorMessage {
                    errorView(error)
                }
            }
            .padding()
        }
        .navigationTitle("AI Coach")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCachedInsights()
            if selectedLap == nil, let firstLap = session.laps.first {
                selectedLap = firstLap
            }
            checkAPIConfiguration()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("AI Coaching Analysis")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Powered by Claude")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text("Get AI-powered insights on braking zones, apex trajectories, and racing line optimization")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Lap Selector
    
    private var lapSelectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Lap")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(session.laps) { lap in
                        LapSelectorCard(
                            lap: lap,
                            isSelected: selectedLap?.id == lap.id
                        ) {
                            selectedLap = lap
                            currentInsight = nil
                            errorMessage = nil
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Analysis Type Selector
    
    private var analysisTypeSelectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Focus")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([AnalysisType.braking, .apex, .acceleration, .consistency, .overall], id: \.self) { type in
                        AnalysisTypeButton(
                            type: type,
                            isSelected: selectedAnalysisType == type
                        ) {
                            selectedAnalysisType = type
                        }
                    }
                }
            }
            
            Button(action: analyzeCurrentLap) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Analyze with AI")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(selectedLap == nil || isAnalyzing || !Config.isClaudeAPIConfigured)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Analyzing telemetry data...")
                .font(.headline)
            
            Text("Claude is reviewing \(selectedAnalysisType.rawValue.lowercased())")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.badge.waveform")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Analysis Yet")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Select a lap and tap 'Analyze with AI' to get coaching insights")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Insight Card
    
    private func insightCard(_ insight: CoachingInsight) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: iconForAnalysisType(insight.type))
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(insight.type.rawValue)
                        .font(.headline)
                    
                    Text(insight.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { shareInsight(insight) }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                }
            }
            
            Divider()
            
            Text(insight.text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            if selectedAnalysisType == .braking {
                brakingZonesDetailView
            } else if selectedAnalysisType == .apex {
                apexDetailView
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Braking Zones Detail (IRA-28)
    
    private var brakingZonesDetailView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Braking Zones")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if let lap = selectedLap {
                let telemetryData = TelemetryFormatter.formatBrakingZones(lap)
                Text(telemetryData)
                    .font(.caption)
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Apex Detail (IRA-29)
    
    private var apexDetailView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Corner Apex Analysis")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if let lap = selectedLap {
                let telemetryData = TelemetryFormatter.formatApexAnalysis(lap)
                Text(telemetryData)
                    .font(.caption)
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Cached Insights Section
    
    private var cachedInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Insights")
                .font(.headline)
            
            ForEach(cachedInsights.prefix(3)) { insight in
                Button(action: { currentInsight = insight }) {
                    HStack {
                        Image(systemName: iconForAnalysisType(insight.type))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(insight.type.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(insight.formattedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Actions
    
    private func analyzeCurrentLap() {
        guard let lap = selectedLap else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        Task {
            do {
                let telemetryData: String
                switch selectedAnalysisType {
                case .braking:
                    telemetryData = TelemetryFormatter.formatBrakingZones(lap)
                case .apex:
                    telemetryData = TelemetryFormatter.formatApexAnalysis(lap)
                default:
                    telemetryData = TelemetryFormatter.formatLapSummary(lap, track: session.track)
                }
                
                let insight = try await apiService.analyzeTelemetry(
                    telemetryData,
                    analysisType: selectedAnalysisType
                )
                
                await MainActor.run {
                    currentInsight = insight
                    ClaudeAPIService.ResponseCache.shared.save(insight)
                    loadCachedInsights()
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAnalyzing = false
                    
                    if error.localizedDescription.contains("API key") {
                        showAPIKeyAlert = true
                    }
                }
            }
        }
    }
    
    private func loadCachedInsights() {
        cachedInsights = ClaudeAPIService.ResponseCache.shared.loadAll()
    }
    
    private func checkAPIConfiguration() {
        if !Config.isClaudeAPIConfigured {
            showAPIKeyAlert = true
        }
    }
    
    private func shareInsight(_ insight: CoachingInsight) {
        // TODO: Implement share sheet
    }
    
    private func iconForAnalysisType(_ type: AnalysisType) -> String {
        switch type {
        case .braking: return "brake.signal"
        case .apex: return "point.topleft.down.curvedto.point.bottomright.up"
        case .acceleration: return "speedometer"
        case .consistency: return "chart.line.uptrend.xyaxis"
        case .overall: return "sparkles"
        }
    }
}

// MARK: - Supporting Views

struct LapSelectorCard: View {
    let lap: Lap
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("Lap \(lap.lapNumber)")
                    .font(.headline)
                    .fontWeight(isSelected ? .bold : .regular)
                
                Text(formatTime(lap.time))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 100)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.tertiarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds / 60)
        let secs = seconds.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%06.3f", mins, secs)
    }
}

struct AnalysisTypeButton: View {
    let type: AnalysisType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type.rawValue)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.2) : Color(.tertiarySystemBackground))
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("AI Coaching") {
    NavigationView {
        AICoachingView(session: Session.mockSession())
    }
}


