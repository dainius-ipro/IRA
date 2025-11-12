//
//  MultiParameterChartView.swift
//  RaceAnalytics
//
//  Epic 3 - IRA-20: Multi-Parameter Overlay
//

import SwiftUI
import Charts

enum TelemetryParameter: String, CaseIterable, Identifiable {
    case speed = "Speed"
    case rpm = "RPM"
    case gForce = "G-Force"
    case exhaustTemp = "Exhaust Temp"
    case waterTemp = "Water Temp"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .speed: return .blue
        case .rpm: return .green
        case .gForce: return .red
        case .exhaustTemp: return .orange
        case .waterTemp: return .cyan
        }
    }
    
    var unit: String {
        switch self {
        case .speed: return "km/h"
        case .rpm: return "RPM"
        case .gForce: return "G"
        case .exhaustTemp, .waterTemp: return "°C"
        }
    }
    
    var usesSecondaryAxis: Bool {
        switch self {
        case .gForce, .exhaustTemp, .waterTemp: return true
        case .speed, .rpm: return false
        }
    }
    
    func value(from point: TelemetryPoint) -> Double? {
        switch self {
        case .speed: return point.speed
        case .rpm: return point.rpm.map(Double.init)
        case .gForce: 
            guard let lat = point.latAcc, let lon = point.lonAcc else { return nil }
            return sqrt(lat * lat + lon * lon)
        case .exhaustTemp: return point.exhaustTemp
        case .waterTemp: return point.waterTemp
        }
    }
    
    func yAxisRange(from points: [TelemetryPoint]) -> ClosedRange<Double> {
        let values = points.compactMap { value(from: $0) }
        guard let min = values.min(), let max = values.max() else {
            return 0...100
        }
        
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let distance: Double
    let value: Double
    let parameter: TelemetryParameter
}

struct MultiParameterChartView: View {
    let lap: Lap
    @State private var selectedParameters: Set<TelemetryParameter> = [.speed, .gForce]
    @State private var showLegend = true
    
    private var chartData: [ChartDataPoint] {
        var data: [ChartDataPoint] = []
        
        for parameter in selectedParameters {
            for point in lap.telemetryPoints {
                if let value = parameter.value(from: point) {
                    data.append(ChartDataPoint(
                        distance: point.distance,
                        value: value,
                        parameter: parameter
                    ))
                }
            }
        }
        
        return data
    }
    
    private var primaryParameters: [TelemetryParameter] {
        selectedParameters.filter { !$0.usesSecondaryAxis }.sorted { $0.rawValue < $1.rawValue }
    }
    
    private var secondaryParameters: [TelemetryParameter] {
        selectedParameters.filter { $0.usesSecondaryAxis }.sorted { $0.rawValue < $1.rawValue }
    }
    
    private func primaryAxisRange() -> ClosedRange<Double>? {
        guard !primaryParameters.isEmpty else { return nil }
        
        var allValues: [Double] = []
        for param in primaryParameters {
            allValues.append(contentsOf: lap.telemetryPoints.compactMap { param.value(from: $0) })
        }
        
        guard let min = allValues.min(), let max = allValues.max() else { return nil }
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }
    
    private func secondaryAxisRange() -> ClosedRange<Double>? {
        guard !secondaryParameters.isEmpty else { return nil }
        
        var allValues: [Double] = []
        for param in secondaryParameters {
            allValues.append(contentsOf: lap.telemetryPoints.compactMap { param.value(from: $0) })
        }
        
        guard let min = allValues.min(), let max = allValues.max() else { return nil }
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            parameterSelectorView
                .padding(.horizontal)
                .padding(.vertical, 12)
            
            if selectedParameters.isEmpty {
                emptyStateView
            } else {
                chartView
                    .padding(.horizontal)
            }
            
            if showLegend && !selectedParameters.isEmpty {
                legendView
                    .padding()
            }
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
    
    private var headerView: some View {
        HStack {
            Text("Multi-Parameter Analysis")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: { showLegend.toggle() }) {
                Image(systemName: showLegend ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    private var parameterSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TelemetryParameter.allCases) { parameter in
                    ParameterToggleButton(
                        parameter: parameter,
                        isSelected: selectedParameters.contains(parameter)
                    ) {
                        toggleParameter(parameter)
                    }
                }
            }
        }
    }
    
    private var chartView: some View {
        Chart {
            ForEach(chartData) { dataPoint in
                LineMark(
                    x: .value("Distance", dataPoint.distance),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(dataPoint.parameter.color)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
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
            if let range = primaryAxisRange() {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text(formatPrimaryAxisValue(val))
                                .font(.caption)
                                .foregroundColor(primaryAxisColor())
                        }
                    }
                }
            }
        }
        .chartYScale(domain: primaryAxisRange() ?? 0...100)
        .frame(height: 300)
        .padding(.vertical)
    }
    
    private func formatPrimaryAxisValue(_ value: Double) -> String {
        if primaryParameters.contains(.speed) {
            return "\(Int(value))"
        } else if primaryParameters.contains(.rpm) {
            return "\(Int(value / 1000))k"
        }
        return "\(Int(value))"
    }
    
    private func primaryAxisColor() -> Color {
        primaryParameters.first?.color ?? .primary
    }
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            ForEach(Array(selectedParameters).sorted(by: { $0.rawValue < $1.rawValue })) { parameter in
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(parameter.color)
                        .frame(width: 30, height: 3)
                    
                    Text(parameter.rawValue)
                        .font(.caption)
                    
                    Text("(\(parameter.unit))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if parameter.usesSecondaryAxis {
                        Text("• Right Axis")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Select Parameters")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Choose one or more parameters from above to visualize telemetry data")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }
    
    private func toggleParameter(_ parameter: TelemetryParameter) {
        if selectedParameters.contains(parameter) {
            selectedParameters.remove(parameter)
        } else {
            if selectedParameters.count < 3 {
                selectedParameters.insert(parameter)
            } else {
                if let oldest = selectedParameters.first {
                    selectedParameters.remove(oldest)
                    selectedParameters.insert(parameter)
                }
            }
        }
    }
}

struct ParameterToggleButton: View {
    let parameter: TelemetryParameter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(parameter.color)
                    .frame(width: 8, height: 8)
                
                Text(parameter.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? parameter.color.opacity(0.2) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? parameter.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Multi-Parameter Chart") {
    MultiParameterChartView(lap: TelemetryPoint.mockLap)
}

extension TelemetryPoint {
    static var mockLap: Lap {
        let points = (0..<100).map { i -> TelemetryPoint in
            let distance = Double(i) * 30.0
            let speed = 50.0 + 30.0 * sin(Double(i) * 0.1)
            let rpm = 8000.0 + 3000.0 * sin(Double(i) * 0.15)
            let gForce = 0.5 + 0.8 * sin(Double(i) * 0.2)
            
            return TelemetryPoint(
                time: Double(i) * 0.05,
                distance: distance,
                speed: speed,
                latitude: 41.9498,
                longitude: 2.2809,
                latAcc: gForce * cos(Double(i) * 0.2),
                lonAcc: gForce * sin(Double(i) * 0.2),
                gyro: 5.0 * sin(Double(i) * 0.3),
                rpm: Int(rpm),
                exhaustTemp: 450.0 + 50.0 * sin(Double(i) * 0.1),
                waterTemp: 60.0 + 10.0 * sin(Double(i) * 0.08)
            )
        }
        
        return Lap(
            id: UUID(),
            lapNumber: 1,
            time: 62.5,
            telemetryPoints: points
        )
    }
}
