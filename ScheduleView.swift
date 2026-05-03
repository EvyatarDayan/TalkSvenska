import SwiftUI
import UserNotifications

struct ScheduleView: View {
    @AppStorage("scheduledNotificationsEnabled") private var scheduledNotificationsEnabled = false
    @AppStorage("notificationTime") private var notificationTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @Environment(\.colorScheme) private var colorScheme

    

    

    
    var body: some View {
        VStack(spacing: 30) {
            // Schedule title
            Text("Schedule")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.top, 20)
                .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 0)
            
            // Description text
            Text("Discover a fresh Swedish sentence each day and expand your skills!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            
            // Schedule content
            GeometryReader { geometry in
                List {
                    // Enable/Disable Schedule
                    HStack {
                        Image(systemName: scheduledNotificationsEnabled ? "bell.fill" : "bell.slash")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Daily Notifications")
                            .font(.body)
                        Spacer()
                        Toggle("", isOn: $scheduledNotificationsEnabled)
                            .labelsHidden()
                            .scaleEffect(0.8)
                            .onChange(of: scheduledNotificationsEnabled) { oldValue, newValue in
                                if newValue {
                                    requestNotificationPermissions()
                                } else {
                                    cancelAllNotifications()
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? geometry.size.width * 0.7 : .infinity)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    
                    // Time Picker Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notification Time")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        DatePicker("Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .onChange(of: notificationTime) {
                                if scheduledNotificationsEnabled {
                                    scheduleNotifications(selectedDays: [1, 2, 3, 4, 5, 6, 7]) // All days
                                }
                            }
                            .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? geometry.size.width * 0.7 : .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? geometry.size.width * 0.7 : .infinity)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    
                    // Notification Info Text
                    Text("You will be notified every day at \(formatTime(notificationTime))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? geometry.size.width * 0.7 : .infinity)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .clipped()
                    

                }
                .listStyle(PlainListStyle())
                .background(Color(.systemGroupedBackground))
            }
        }
        .background(Color(.systemGroupedBackground))

    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    scheduleNotifications(selectedDays: [1, 2, 3, 4, 5, 6, 7]) // All days
                } else {
                    scheduledNotificationsEnabled = false
                }
            }
        }
    }
    
    private func scheduleNotifications(selectedDays: [Int]) {
        guard scheduledNotificationsEnabled else { return }
        
        print("📅 Starting to schedule notifications for days: \(selectedDays)")
        
        // Cancel existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("📅 Cancelled existing notifications")
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to learn Swedish!"
        content.body = "Tap to see a new Swedish sentence"
        content.sound = .default
        content.userInfo = ["action": "showRandomSentence"]
        print("📅 Created notification content with userInfo: \(content.userInfo)")
        
        // Create trigger for each selected day
        for day in selectedDays {
            var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
            dateComponents.weekday = day
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            let request = UNNotificationRequest(
                identifier: "swedish-reminder-\(day)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule notification for day \(day): \(error)")
                } else {
                    print("✅ Successfully scheduled notification for day \(day)")
                }
            }
        }
    }
    
    private func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}



#Preview {
    ScheduleView()
}
