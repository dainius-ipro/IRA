//
//  RPMChartView.swift
//  IRA
//
//  Engine RPM chart with rev limit warnings
//

import SwiftUI
import Charts

struct RPMChartView: View {
    let lap: Lap
    
    private let revLimit = 13500 // IAME X30 Junior rev limit
    
    var isOverRevving: Bool {
        lap.maxRPM > revLimit
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Engine RPM")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        StatBadge(
                            label: "Max",
                            value: "\(lap.maxRPM) RPM",
                            color: isOverRevving ? .red : .green
                        )
                        
                        StatBadge(
                            label: "Avg",
                            value: String(format: "%.0f RPM", lap.averageRPM),
                            color: .blue
                        )
                        
                        if isOverRevving {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text("Over Rev!")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Chart
                Chart {
                    // RPM Line
                    ForEach(lap.telemetryPoints) { point in
                        if let rpm = point.rpm {
                            LineMark(
                                x: .value("Distance", point.distance),
                                y: .value("RPM", rpm)
                            )
                            .foregroundStyle(.green)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    
                    // Rev Limit Line
                    RuleMark(y: .value("Rev Limit", revLimit))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Rev Limit")
                                .font(.caption2)
                                .foregroundStyle(.red)
                                .padding(4)
                                .background(Color(.systemBackground))
                                .cornerRadius(4)
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
                            if let rpm = value.as(Int.self) {
                                Text("\(rpm)")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 300)
                .padding()
                
                // Warning if over-revving
                if isOverRevving {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Over-Revving Detected")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("Review braking points and gear shifts to protect engine")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Info
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    
                    Text("IAME X30 Junior optimal RPM range: 10,000-13,500")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Preview

#Preview {
    RPMChartView(lap: Lap.mockLap())
}
