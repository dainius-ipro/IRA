// SessionDetailView.swift
// UPDATED: Added AI Coaching navigation (Epic 5)

import SwiftUI
import MapKit

struct SessionDetailView: View {
    let session: StoredSession
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Session Info & Laps
            SessionInfoView(session: session)
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
                .tag(0)
            
            // Tab 2: Track Map
            TrackMapView(session: session.toSession()) // Convert to Session model
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(1)
            
            // Tab 3: Charts
            TelemetryChartsView(session: session.toSession())
                .tabItem {
                    Label("Charts", systemImage: "chart.xyaxis.line")
                }
                .tag(2)
        }
        .navigationTitle(session.track ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
        // NEW: AI Coaching navigation button (Epic 5)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: AICoachingView(session: session.toSession())) {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                        Text("AI Coach")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Session Info Tab

struct SessionInfoView: View {
    let session: StoredSession
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Session Details Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Session Details")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    InfoRow(label: "Track", value: session.track ?? "Unknown")
                    InfoRow(label: "Date", value: session.date.formatted(date: .long, time: .shortened))
                    InfoRow(label: "Racer", value: session.racer ?? "Unknown")
                    InfoRow(label: "Vehicle", value: session.vehicle ?? "Unknown")
                    InfoRow(label: "Laps", value: "\(session.laps.count)")
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                
                // Laps List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Laps")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ForEach(session.laps.sorted(by: { $0.lapNumber < $1.lapNumber })) { lap in
                        LapRow(lap: lap)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct LapRow: View {
    let lap: StoredLap
    
    var body: some View {
        HStack {
            Text("Lap \(lap.lapNumber)")
                .font(.headline)
            
            Spacer()
            
            Text(formatTime(lap.time))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Text("\(lap.telemetryPoints.count) pts")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = seconds.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%06.3f", minutes, secs)
    }
}
