import Foundation
import SwiftData

/// Storage service for managing sessions with SwiftData
@MainActor
class SessionStorage: ObservableObject {

```
private let modelContainer: ModelContainer
private let modelContext: ModelContext

@Published var sessions: [Session] = []

init() {
    // Configure SwiftData
    let schema = Schema([StoredSession.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    
    do {
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
        loadSessions()
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}

// MARK: - Public Methods

func save(_ session: Session) throws {
    let stored = StoredSession(from: session)
    modelContext.insert(stored)
    try modelContext.save()
    loadSessions()
}

func delete(_ session: Session) throws {
    let fetchDescriptor = FetchDescriptor<StoredSession>(
        predicate: #Predicate { $0.id == session.id }
    )
    
    if let stored = try modelContext.fetch(fetchDescriptor).first {
        modelContext.delete(stored)
        try modelContext.save()
        loadSessions()
    }
}

func loadSessions() {
    let fetchDescriptor = FetchDescriptor<StoredSession>(
        sortBy: [SortDescriptor(\.date, order: .reverse)]
    )
    
    do {
        let storedSessions = try modelContext.fetch(fetchDescriptor)
        sessions = storedSessions.map { $0.toSession() }
    } catch {
        print("Failed to fetch sessions: \(error)")
        sessions = []
    }
}
```

}