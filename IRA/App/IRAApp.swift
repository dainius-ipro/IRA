//
//  IRAApp.swift
//  IRA
//
//  Created by user283632 on 10/19/25.
//

import SwiftUI
import SwiftData

@main
struct IRAApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [StoredSession.self, StoredLap.self])
    }
}
