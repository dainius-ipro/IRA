//
//  GForceChartView.swift
//  IRA
//
//  G-Force visualization (lateral & longitudinal)
//

import SwiftUI
import Charts

struct GForceChartView: View {
    let lap: Lap
    
    var maxGForce: Double {
        let latMax = lap.telemetryPoints.compactMap { $0.latAcc }.map { abs($0) }.max() ?? 0
        let lonMax = lap.telemetryPoints.compactMap { $0.lonAcc }.map { abs($0) }.max() ?? 0
        return max(latMax, lonMax)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("G-Force Analysis")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        StatBadge(
                            label: "Max Lat",
                            value: String(format: "%.2fG", lap.maxLatAcc),
                            color: .blue
                        )
                        
                        StatBadge(
                            label: "Max Lon",
                            value: String(format: "%.2fG", lap.maxLonAcc),
                            color: .red
                        )
                        
                        StatBadge(
                            label: "Peak",
                            value: String(format: "%.2fG", maxGForce),
                            color: .purple
                        )
                    }
                }
                .padding(.horizontal)
                
                // Chart
                Chart {
                    // Lateral Acceleration (Cornering)
                    ForEach(lap.telemetryPoints) { point in
                        if let latAcc = point.latAcc {
                            LineMark(
                                x: .value("Distance", point.distance),
                                y: .value("G-Force", latAcc)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    
                    // Longitudinal Acceleration (Braking/Acceleration)
                    ForEach(lap.telemetryPoints) { point in
                        if let lonAcc = point.lonAcc {
                            LineMark(
                                x: .value("Distance", point.distance),
                                y: .value("G-Force", lonAcc)
                            )
                            .foregroundStyle(.red)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    
                    // Zero reference line
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let distance = value.as(Double.self) {
                                Text("\(Int(distance))m")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 8)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let gforce = value.as(Double.self) {
                                Text(String(format: "%.1fG", gforce))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 300)
                .padding()
                
                // Legend
                HStack(spacing: 24) {
                    LegendItem(color: .blue, label: "Lateral (Cornering)")
                    LegendItem(color: .red, label: "Longitudinal (Braking/Accel)")
                }
                .padding(.horizontal)
                
                // Info
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Positive longitudinal = acceleration")
                            .font(.caption)
                        Text("Negative longitudinal = braking")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Supporting Views

private struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(width: 24, height: 3)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    GForceChartView(lap: Lap.mockLap())
}
