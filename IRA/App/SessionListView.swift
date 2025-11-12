//
//  SessionListView.swift
//  RaceAnalytics
//
//  Created by Claude AI on 2025-10-29
//  Epic 1 - Session List with CSV Import
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Main view displaying list of imported racing sessions
struct SessionListView: View {
    
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredSession.date, order: .reverse) private var sessions: [StoredSession]
    
    @State private var showingImporter = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                if sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionList
                }
            }
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Import CSV", systemImage: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
            .alert("Import Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Sessions Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Import a MyChron CSV file to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingImporter = true
            } label: {
                Label("Import CSV", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    private var sessionList: some View {
        List {
            ForEach(sessions) { session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    SessionRowView(session: session)
                }
            }
            .onDelete(perform: deleteSessions)
        }
    }
    
    // MARK: - Actions
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else {
                throw ImportError.noFileSelected
            }
            
            // Security-scoped resource access
            guard selectedFile.startAccessingSecurityScopedResource() else {
                throw ImportError.accessDenied
            }
            
            defer {
                selectedFile.stopAccessingSecurityScopedResource()
            }
            
            // Read file data
            let data = try Data(contentsOf: selectedFile)
            
            // Parse CSV
            let parser = MyChronCSVParser()
            let session = try parser.parse(data)
            
            // Store in SwiftData
            let storage = SessionStorage(modelContext: modelContext)
            try storage.save(session)
            
        } catch let error as ImportError {
            showingError = true
            errorMessage = error.localizedDescription
        } catch {
            showingError = true
            errorMessage = "Failed to import: \(error.localizedDescription)"
        }
    }
    
    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            let session = sessions[index]
            modelContext.delete(session)
        }
    }
}

// MARK: - Session Row View

struct SessionRowView: View {
    
    let session: StoredSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(session.track ?? session.vehicle ?? "Training Session")
                .font(.headline)
            
            // Metadata
            HStack {
                Label("\(session.laps.count) laps", systemImage: "flag.checkered")
                
                Spacer()
                
                Text(session.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Import Error

enum ImportError: LocalizedError {
    case noFileSelected
    case accessDenied
    case invalidFormat
    case parsingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noFileSelected:
            return "No file was selected"
        case .accessDenied:
            return "Cannot access the selected file"
        case .invalidFormat:
            return "Invalid CSV format"
        case .parsingFailed(let details):
            return "Parsing failed: \(details)"
        }
    }
}

// MARK: - Preview

#Preview {
    SessionListView()
        .modelContainer(for: StoredSession.self, inMemory: true)
}
