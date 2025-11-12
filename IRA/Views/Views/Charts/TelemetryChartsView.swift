//
//  TelemetryChartsView.swift
//  IRA
//
//  Epic 3: Telemetry Charts
//  UPDATED: Added Multi-parameter chart tab (IRA-20)
//

import SwiftUI

struct TelemetryChartsView: View {
    let session: Session
    @State private var selectedLapIndex = 0
    @State private var selectedChartTab = 0
    
    var selectedLap: Lap? {
        guard !session.laps.isEmpty, selectedLapIndex < session.laps.count else { return nil }
        return session.laps[selectedLapIndex]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Lap Selector Header
            lapSelectorHeader
                .padding()
                .background(Color(.systemGroupedBackground))
            
            // Chart Type Picker - UPDATED: Added Multi tab
            Picker("Chart Type", selection: $selectedChartTab) {
                Text("Speed").tag(0)
                Text("G-Force").tag(1)
                Text("RPM").tag(2)
                Text("Temp").tag(3)
                Text("Multi").tag(4) // ← NEW!
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Chart Content - UPDATED: Added MultiParameterChartView
            if let lap = selectedLap {
                TabView(selection: $selectedChartTab) {
                    SpeedDistanceChartView(lap: lap)
                        .tag(0)
                    
                    GForceChartView(lap: lap)
                        .tag(1)
                    
                    RPMChartView(lap: lap)
                        .tag(2)
                    
                    TemperatureChartView(lap: lap)
                        .tag(3)
                    
                    // NEW: Multi-parameter chart (IRA-20)
                    MultiParameterChartView(lap: lap)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            } else {
                emptyStateView
            }
        }
    }
    
    // MARK: - Subviews
    
    private var lapSelectorHeader: some View {
        HStack {
            Text("Lap")
                .font(.headline)
            
            Spacer()
            
            Menu {
                ForEach(session.laps.indices, id: \.self) { index in
                    Button {
                        selectedLapIndex = index
                    } label: {
                        HStack {
                            Text("Lap \(session.laps[index].lapNumber)")
                            Text(session.laps[index].formattedTime)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if let lap = selectedLap {
                        Text("Lap \(lap.lapNumber)")
                            .fontWeight(.semibold)
                    } else {
                        Text("Select Lap")
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Telemetry Data")
                .font(.headline)
            
            Text("This session doesn't have any laps to display")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    TelemetryChartsView(session: Session.mockSession())
}
