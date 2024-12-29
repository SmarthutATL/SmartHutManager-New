import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NotificationSettingsView: View {
    @State private var enableNotifications: Bool = true
    @State private var jobUpdates: Bool = true
    @State private var promotionalOffers: Bool = false
    @State private var messageAlerts: Bool = true
    
    var body: some View {
        Form {
            Section(header: Text("General")) {
                Toggle(isOn: $enableNotifications) {
                    Text("Enable Notifications")
                }
            }
            
            if enableNotifications {
                Section(header: Text("Notification Preferences")) {
                    Toggle(isOn: $jobUpdates) {
                        Text("Job Updates")
                    }
                    
                    Toggle(isOn: $promotionalOffers) {
                        Text("Promotional Offers")
                    }
                    
                    Toggle(isOn: $messageAlerts) {
                        Text("Message Alerts")
                    }
                }
            }
        }
        .navigationTitle("Notification Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveNotificationSettings()
                }
            }
        }
    }
    
    private func saveNotificationSettings() {
        guard let email = Auth.auth().currentUser?.email else { return }
        let db = Firestore.firestore()
        
        let notificationSettings: [String: Any] = [
            "enableNotifications": enableNotifications,
            "jobUpdates": jobUpdates,
            "promotionalOffers": promotionalOffers,
            "messageAlerts": messageAlerts
        ]
        
        db.collection("users").document(email).updateData(["notificationSettings": notificationSettings]) { error in
            if let error = error {
                print("Error saving notification settings: \(error.localizedDescription)")
            } else {
                print("Notification settings saved successfully.")
            }
        }
    }
}
