import SwiftUI
import Charts

/// Lap consistency analysis view
/// Epic 4: Lap Analysis - IRA-25
struct ConsistencyView: View {

```
let session: StoredSession

private let analyzer = ConsistencyAnalyzer()

private var consistencyScore: Double {
    analyzer.calculateConsistencyScore(laps: session.laps)
}

private var interpretation: (level: String, color: String, message: String) {
    analyzer.interpretScore(consistencyScore)
}

private var outliers: [StoredLap] {
    analyzer.findOutliers(laps: session.laps)
}

private var avgDeviation: Double {
    analyzer.averageDeviationFromBest(laps: session.laps)
}

var body: some View {
    VStack(alignment: .leading, spacing: 20) {
        // Header with score
        headerView
        
        // Lap times chart
        lapTimesChart
        
        // Statistics
        statisticsView
        
        // Interpretation
        interpretationView
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
}

// MARK: - Header View

private var headerView: some View {
    VStack(spacing: 12) {
        Text("Consistency Analysis")
            .font(.system(size: 20, weight: .bold))
        
        // Consistency score badge
        VStack(spacing: 8) {
            Text("\(Int(consistencyScore))")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(colorForLevel(interpretation.color))
            
            Text(interpretation.level)
                .font(.headline)
                .foregroundColor(colorForLevel(interpretation.color))
            
            Text("Consistency Score")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(colorForLevel(interpretation.color).opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Lap Times Chart

private var lapTimesChart: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Lap Times")
            .font(.headline)
        
        Chart {
            // Average line
            let avgTime = session.laps.map(\.time).reduce(0, +) / Double(session.laps.count)
            RuleMark(y: .value("Average", avgTime))
                .foregroundStyle(.blue.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            
            // Lap time bars
            ForEach(session.laps.sorted(by: { $0.number < $1.number })) { lap in
                let isOutlier = outliers.contains(where: { $0.id == lap.id })
                
                BarMark(
                    x: .value("Lap", lap.number),
                    y: .value("Time", lap.time)
                )
                .foregroundStyle(isOutlier ? .red : .blue)
                .annotation(position: .top) {
                    if isOutlier {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let lap = value.as(Int.self) {
                        Text("L\(lap)")
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let time = value.as(Double.self) {
                        Text(String(format: "%.1fs", time))
                            .font(.caption)
                    }
                }
            }
        }
    }
}

// MARK: - Statistics View

private var statisticsView: some View {
    VStack(spacing: 12) {
        HStack(spacing: 16) {
            StatCard(
                title: "Total Laps",
                value: "\(session.laps.count)",
                icon: "flag.checkered",
                color: .blue
            )
            
            StatCard(
                title: "Outliers",
                value: "\(outliers.count)",
                icon: "exclamationmark.triangle",
                color: .red
            )
        }
        
        HStack(spacing: 16) {
            StatCard(
                title: "Avg Deviation",
                value: String(format: "%.3fs", avgDeviation),
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            )
            
            if let bestTime = session.laps.map(\.time).min() {
                StatCard(
                    title: "Best Lap",
                    value: formatLapTime(bestTime),
                    icon: "star.fill",
                    color: .purple
                )
            }
        }
    }
}

// MARK: - Interpretation View

private var interpretationView: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("Analysis")
            .font(.headline)
        
        Text(interpretation.message)
            .font(.subheadline)
            .foregroundColor(.secondary)
        
        if !outliers.isEmpty {
            Divider()
                .padding(.vertical, 4)
            
            Text("Outlier Laps:")
                .font(.subheadline.bold())
            
            ForEach(outliers.sorted(by: { $0.number < $1.number })) { lap in
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text("Lap \(lap.number): \(formatLapTime(lap.time))")
                        .font(.caption)
                    
                    Spacer()
                }
            }
        }
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(10)
}

// MARK: - Helper Functions

private func colorForLevel(_ level: String) -> Color {
    switch level {
    case "green": return .green
    case "blue": return .blue
    case "orange": return .orange
    case "red": return .red
    default: return .gray
    }
}

private func formatLapTime(_ seconds: Double) -> String {
    let minutes = Int(seconds) / 60
    let secs = seconds.truncatingRemainder(dividingBy: 60)
    return String(format: "%d:%06.3f", minutes, secs)
}
```

}

// MARK: - Supporting Views

struct StatCard: View {
let title: String
let value: String
let icon: String
let color: Color

```
var body: some View {
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        Text(value)
            .font(.title3.bold())
            .foregroundColor(color)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(color.opacity(0.1))
    .cornerRadius(10)
}
```

}

// MARK: - Preview

#Preview {
let mockSession = StoredSession(
id: UUID(),
date: Date(),
sessionName: “Preview Session”,
vehicle: “FA 2025”,
racer: “Troy”,
venue: “Circuit Osona”,
championship: “Test”,
laps: []
)

```
return ScrollView {
    ConsistencyView(session: mockSession)
        .padding()
}
```

}