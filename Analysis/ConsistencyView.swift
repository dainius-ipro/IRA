// RaceAnalytics/Views/ConsistencyView.swift

import SwiftUI
import SwiftData
import Charts

/// Displays lap time consistency analysis with visualization
struct ConsistencyView: View {
    let session: StoredSession
    
    @State private var selectedMetric: ConsistencyMetric = .lapTime
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Metric selector
                metricPicker
                
                // Main chart
                consistencyChart
                
                // Statistics grid
                statisticsGrid
                
                // Lap times table
                lapTimesTable
            }
            .padding()
        }
        .navigationTitle("Consistency Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Metric Picker
    
    private var metricPicker: some View {
        Picker("Metric", selection: $selectedMetric) {
            ForEach(ConsistencyMetric.allCases) { metric in
                Text(metric.displayName).tag(metric)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Consistency Chart
    
    private var consistencyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lap Time Distribution")
                .font(.headline)
            
            Chart {
                ForEach(Array(session.laps.enumerated()), id: \.element.id) { index, lap in
                    BarMark(
                        x: .value("Lap", index + 1),
                        y: .value("Time", lap.time)
                    )
                    .foregroundStyle(colorForLap(lap))
                }
                
                // Average line
                RuleMark(y: .value("Average", statistics.averageLapTime))
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Avg: \(formatTime(statistics.averageLapTime))")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let seconds = value.as(Double.self) {
                        AxisValueLabel {
                            Text(formatTime(seconds))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Statistics Grid
    
    private var statisticsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Best Lap",
                    value: formatTime(statistics.bestLapTime),
                    icon: "trophy.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Average",
                    value: formatTime(statistics.averageLapTime),
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Std Dev",
                    value: String(format: "%.3fs", statistics.standardDeviation),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
                
                StatCard(
                    title: "Consistency",
                    value: String(format: "%.1f%%", statistics.consistencyScore),
                    icon: "target",
                    color: consistencyColor
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Lap Times Table
    
    private var lapTimesTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lap Times")
                .font(.headline)
            
            ForEach(Array(session.laps.enumerated()), id: \.element.id) { index, lap in
                HStack {
                    // Lap number
                    Text("Lap \(index + 1)")
                        .font(.subheadline)
                        .frame(width: 60, alignment: .leading)
                    
                    // Time
                    Text(formatTime(lap.time))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(colorForLap(lap))
                    
                    Spacer()
                    
                    // Delta to best
                    if lap.time != statistics.bestLapTime {
                        let delta = lap.time - statistics.bestLapTime
                        Text("+\(String(format: "%.3f", delta))s")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 8)
                
                if index < session.laps.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Computed Properties
    
    private var statistics: ConsistencyStatistics {
        ConsistencyCalculator.calculate(for: session)
    }
    
    private var consistencyColor: Color {
        let score = statistics.consistencyScore
        if score >= 95 { return .green }
        if score >= 90 { return .yellow }
        return .orange
    }
    
    // MARK: - Helper Methods
    
    private func colorForLap(_ lap: StoredLap) -> Color {
        let delta = lap.time - statistics.bestLapTime
        if delta == 0 { return .green }
        if delta < 0.5 { return .blue }
        if delta < 1.0 { return .orange }
        return .red
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = seconds.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%06.3f", minutes, secs)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Models

enum ConsistencyMetric: String, CaseIterable, Identifiable {
    case lapTime = "Lap Time"
    case sectorTime = "Sector Time"
    case topSpeed = "Top Speed"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .lapTime: return "Lap Times"
        case .sectorTime: return "Sectors"
        case .topSpeed: return "Speed"
        }
    }
}

struct ConsistencyStatistics {
    let bestLapTime: Double
    let averageLapTime: Double
    let standardDeviation: Double
    let consistencyScore: Double
    let variance: Double
}

// MARK: - Calculator

enum ConsistencyCalculator {
    static func calculate(for session: StoredSession) -> ConsistencyStatistics {
        let times = session.laps.map(\.time)
        
        guard !times.isEmpty else {
            return ConsistencyStatistics(
                bestLapTime: 0,
                averageLapTime: 0,
                standardDeviation: 0,
                consistencyScore: 0,
                variance: 0
            )
        }
        
        let best = times.min() ?? 0
        let average = times.reduce(0, +) / Double(times.count)
        
        // Calculate standard deviation
        let squaredDiffs = times.map { pow($0 - average, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(times.count)
        let stdDev = sqrt(variance)
        
        // Consistency score: 100% = perfect consistency
        // Lower std dev = higher consistency
        let consistencyScore = max(0, 100 - (stdDev / average * 100))
        
        return ConsistencyStatistics(
            bestLapTime: best,
            averageLapTime: average,
            standardDeviation: stdDev,
            consistencyScore: consistencyScore,
            variance: variance
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConsistencyView(session: SampleData.session)
            .modelContainer(SampleData.container)
    }
}

// MARK: - Sample Data

enum SampleData {
    @MainActor
    static var container: ModelContainer = {
        let schema = Schema([StoredSession.self, StoredLap.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        
        // Insert sample data
        let session = StoredSession(
            date: Date(),
            vehicle: "FA 2025",
            racer: "Troy",
            track: "Circuit Osona"
        )
        
        // Create sample laps with varying times
        let baseLapTime = 42.350
        let lapTimes: [Double] = [
            baseLapTime,
            baseLapTime + 0.120,
            baseLapTime + 0.050,
            baseLapTime - 0.080, // Best lap
            baseLapTime + 0.200,
            baseLapTime + 0.090,
            baseLapTime + 0.030,
            baseLapTime + 0.150,
            baseLapTime + 0.070,
            baseLapTime + 0.040
        ]
        
        for (index, lapTime) in lapTimes.enumerated() {
            let lap = StoredLap(
                lapNumber: index + 1,
                time: lapTime
            )
            session.laps.append(lap)
        }
        
        container.mainContext.insert(session)
        try? container.mainContext.save()
        
        return container
    }()
    
    @MainActor
    static var session: StoredSession {
        let context = container.mainContext
        let descriptor = FetchDescriptor<StoredSession>()
        return try! context.fetch(descriptor).first!
    }
}