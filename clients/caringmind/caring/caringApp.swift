//
//  caringApp.swift
//  caring
//
//  Created by Elijah Arbee on 12/1/24.
//

import SwiftUI
import UserNotifications

@main
struct caringApp: App {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var userManager = UserManager.shared
    
    init() {
        // Ensure UserDefaults are initialized before app starts
        UserDefaults.standard.synchronize()
        
        // Configure notifications synchronously to avoid initialization issues
        setupNotifications()
    }
    
    private func setupNotifications() {
        // Set up notification categories first
        let viewAction = UNNotificationAction(
            identifier: "VIEW_NOTIFICATION",
            title: "View",
            options: .foreground
        )
        
        let category = UNNotificationCategory(
            identifier: "NOTIFICATION_CATEGORY",
            actions: [viewAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "New Caring notification",
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        // Request authorization separately
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    await MainActor.run {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            } catch {
                print("Failed to request notification authorization: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AuthenticationSplashView()
                .environmentObject(settings)
                .environmentObject(userManager)
                .preferredColorScheme(settings.darkModeEnabled ? .dark : .light)
                .animation(.easeInOut(duration: 0.2), value: settings.darkModeEnabled)
        }
    }
}
