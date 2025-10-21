//
//  SessionListView.swift
//  IRA
//
//  RaceAnalytics - Epic 1: Session List & Import
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SessionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredSession.date, order: .reverse) private var sessions: [StoredSession]
    
    @State private var showingImporter = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isImporting = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionList
                }
                
                if isImporting {
                    loadingOverlay
                }
            }
            .navigationTitle("RaceAnalytics")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    importButton
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.commaSeparatedText, UTType(filenameExtension: "csv")!],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Import Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)
            
            Text("No Sessions")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Import a MyChron CSV file to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingImporter = true
            } label: {
                Label("Import CSV", systemImage: "square.and.arrow.down")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
    }
    
    private var sessionList: some View {
        List {
            ForEach(sessions) { session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    SessionRow(session: session)
                }
            }
            .onDelete(perform: deleteSessions)
        }
    }
    
    private var importButton: some View {
        Button {
            showingImporter = true
        } label: {
            Label("Import", systemImage: "plus")
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Importing Session...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    // MARK: - Actions
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        isImporting = true
        
        Task {
            do {
                guard let url = try result.get().first else { return }
                
                // Security scoped resource access
                guard url.startAccessingSecurityScopedResource() else {
                    throw ImportError.accessDenied
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                // Read CSV data
                let data = try Data(contentsOf: url)
                
                // Parse CSV
                let parser = MyChronCSVParser()
                let session = try parser.parse(data)
                
                // Convert to stored model
                let storedSession = StoredSession.fromSession(session)
                modelContext.insert(storedSession)
                
                try modelContext.save()
                
                await MainActor.run {
                    isImporting = false
                }
                
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            let session = sessions[index]
            modelContext.delete(session)
        }
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: StoredSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.track ?? "Unknown Track")
                    .font(.headline)
                
                Spacer()
                
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 16) {
                Label("\(session.laps.count) laps", systemImage: "flag.checkered")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let racer = session.racer {
                    Label(racer, systemImage: "person")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let vehicle = session.vehicle {
                    Label(vehicle, systemImage: "car")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Session Detail View Placeholder

struct SessionDetailView: View {
    let session: StoredSession
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Session Info Card
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
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Error Types

enum ImportError: LocalizedError {
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Could not access the selected file"
        }
    }
}

// MARK: - Preview

#Preview {
    SessionListView()
        .modelContainer(for: StoredSession.self, inMemory: true)
}
