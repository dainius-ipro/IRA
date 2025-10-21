//
//  ContentView.swift
//  IRA
//
//  RaceAnalytics - Epic 1 Root View
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        SessionListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: StoredSession.self, inMemory: true)
}
