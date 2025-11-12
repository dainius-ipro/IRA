//
//  SpeedDistanceChartView.swift
//  IRA
//
//  Speed vs Distance chart with sector markers
//

import SwiftUI
import Charts

struct SpeedDistanceChartView: View {
    let lap: Lap
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with statistics
                VStack(alignment: .leading, spacing: 8) {
                    Text("Speed vs Distance")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        StatBadge(
                            label: "Max",
                            value: String(format: "%.1f km/h", lap.maxSpeed),
                            color: .green
                        )
                        
                        StatBadge(
                            label: "Avg",
                            value: String(format: "%.1f km/h", lap.averageSpeed),
                            color: .blue
                        )
                        
                        if let minSpeed = lap.telemetryPoints.compactMap(\.speed).min() {
                            StatBadge(
                                label: "Min",
                                value: String(format: "%.1f km/h", minSpeed),
                                color: .orange
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                // Chart
                Chart {
                    ForEach(lap.telemetryPoints) { point in
                        if let speed = point.speed {
                            LineMark(
                                x: .value("Distance", point.distance),
                                y: .value("Speed", speed)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.catmullRom)
                        }
                    }
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
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let speed = value.as(Double.self) {
                                Text("\(Int(speed))")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 300)
                .padding()
                
                // Info
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    
                    Text("Speed measured via GPS at 20Hz sampling rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    SpeedDistanceChartView(lap: Lap.mockLap())
}
