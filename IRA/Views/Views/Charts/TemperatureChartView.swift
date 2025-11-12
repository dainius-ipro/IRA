//
//  TemperatureChartView.swift
//  IRA
//
//  Engine temperature monitoring (exhaust & water)
//

import SwiftUI
import Charts

struct TemperatureChartView: View {
    let lap: Lap
    
    private let exhaustTempWarning = 600.0 // °C
    private let waterTempWarning = 80.0    // °C
    
    var maxExhaustTemp: Double {
        lap.telemetryPoints.compactMap(\.exhaustTemp).max() ?? 0
    }
    
    var maxWaterTemp: Double {
        lap.telemetryPoints.compactMap(\.waterTemp).max() ?? 0
    }
    
    var hasWarning: Bool {
        maxExhaustTemp > exhaustTempWarning || maxWaterTemp > waterTempWarning
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Engine Temperature")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        StatBadge(
                            label: "Max Exhaust",
                            value: String(format: "%.0f°C", maxExhaustTemp),
                            color: maxExhaustTemp > exhaustTempWarning ? .red : .orange
                        )
                        
                        StatBadge(
                            label: "Max Water",
                            value: String(format: "%.0f°C", maxWaterTemp),
                            color: maxWaterTemp > waterTempWarning ? .red : .blue
                        )
                        
                        if hasWarning {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("High Temp")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Chart
                Chart {
                    // Exhaust Temperature
                    ForEach(lap.telemetryPoints) { point in
                        if let temp = point.exhaustTemp {
                            LineMark(
                                x: .value("Distance", point.distance),
                                y: .value("Temperature", temp)
                            )
                            .foregroundStyle(.red)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    
                    // Water Temperature
                    ForEach(lap.telemetryPoints) { point in
                        if let temp = point.waterTemp {
                            LineMark(
                                x: .value("Distance", point.distance),
                                y: .value("Temperature", temp)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    
                    // Warning lines
                    if maxExhaustTemp > exhaustTempWarning {
                        RuleMark(y: .value("Exhaust Warning", exhaustTempWarning))
                            .foregroundStyle(.red.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                    
                    if maxWaterTemp > waterTempWarning {
                        RuleMark(y: .value("Water Warning", waterTempWarning))
                            .foregroundStyle(.blue.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
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
                            if let temp = value.as(Double.self) {
                                Text("\(Int(temp))°C")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 300)
                .padding()
                
                // Legend
                HStack(spacing: 24) {
                    LegendItem(color: .red, label: "Exhaust Temp")
                    LegendItem(color: .blue, label: "Water Temp")
                }
                .padding(.horizontal)
                
                // Warning
                if hasWarning {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("High Temperature Warning")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("Check cooling system, fuel mixture, and airflow")
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
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Normal exhaust temp: 450-550°C")
                            .font(.caption)
                        Text("Normal water temp: 50-75°C")
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
    TemperatureChartView(lap: Lap.mockLap())
}
