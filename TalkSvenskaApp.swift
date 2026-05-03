//
//  TalkSvenskaApp.swift
//  TalkSvenska
//
//  Created by EVYATAR DAYAN on 14/08/2025.
//

import SwiftUI
import UserNotifications

@main
struct TalkSvenskaApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showRandomSentence = false
    @State private var showLogo = true
    @StateObject private var sessionManager = SessionManager.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showLogo {
                    LogoView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showLogo = false
                        }
                    }
                } else {
                    ContentView(showRandomSentence: $showRandomSentence)
                        .preferredColorScheme(isDarkMode ? .dark : .light)
                        .onAppear {
                            setupNotificationHandling()
                            // Reset session when app appears (app launch)
                            SessionManager.shared.resetSession()
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .showRandomSentence)) { _ in
                            print("📱 App received showRandomSentence notification")
                            showRandomSentence = true
                        }
                        .onAppear {
                            print("📱 App appeared - notification handler should be set up")
                        }
                }
            }
        }
    }
    
    private func setupNotificationHandling() {
        print("🔧 Setting up notification handler")
        UNUserNotificationCenter.current().delegate = NotificationHandler.shared
        print("🔧 Notification handler delegate set to: \(NotificationHandler.shared)")
    }
}

class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationHandler()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 Notification tapped - didReceive response called")
        let userInfo = response.notification.request.content.userInfo
        print("🔔 UserInfo: \(userInfo)")
        
        if let action = userInfo["action"] as? String, action == "showRandomSentence" {
            print("🔔 Action detected: \(action)")
            // Post notification to show random sentence
            DispatchQueue.main.async {
                print("🔔 Posting showRandomSentence notification")
                NotificationCenter.default.post(name: .showRandomSentence, object: nil)
                print("🔔 Notification posted successfully")
            }
        } else {
            print("🔔 No action found or action doesn't match")
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}

extension Notification.Name {
    static let showRandomSentence = Notification.Name("showRandomSentence")
}
