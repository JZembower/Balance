//
//  BalanceAppApp.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//

import SwiftUI
import SwiftData

@main
struct BalanceAppApp: App {
    // Initialize UserSessionManager on app launch
    @StateObject private var userSession = UserSessionManager.shared
    @StateObject private var dataManager = DataManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSession)
                .environmentObject(dataManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
