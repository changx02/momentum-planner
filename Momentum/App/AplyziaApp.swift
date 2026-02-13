//
//  AplyziaApp.swift
//  Aplyzia Planner
//
//  Smart Digital Planner with Multi-View Sync, Handwriting Recognition & Intelligent Reminders
//

import SwiftUI
import SwiftData

@main
struct AplyziaApp: App {
    // SwiftData model container
    let modelContainer: ModelContainer

    // Shared services
    @State private var notificationService = NotificationService.shared
    @State private var routingService = RoutingService.shared

    init() {
        // Initialize SwiftData container with all models
        do {
            let schema = Schema([
                Entry.self,
                Reminder.self,
                TextBox.self,
                Goal.self,
                RoutingRecord.self,
                NotePage.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic // Enable CloudKit sync
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environmentObject(notificationService)
                .environmentObject(routingService)
        }
    }
}
