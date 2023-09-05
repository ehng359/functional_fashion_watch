//
//  NotificationDelegate.swift
//  hb_read Watch App
//
//  Created by Edward Ng on 9/5/23.
//

import Foundation
import UserNotifications

/// Note: Electrocardiogram app disables any possibility to receive notifications while it is in the foreground.
class NotificationManager {
    func generateRequest() {
        let content = UNMutableNotificationContent()
        content.title = "ECG Data retrieved"
        content.body = "Navigate back to the application to set Valence/Arousal."
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: .none)
       
        UNUserNotificationCenter.current().add(request) { (error) in
            if let _ = error {
                print("Error sending notification.")
            }
        }
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let _ = error {
                print("Error occurred when setting up notifications.")
            } else if success {
                print("Permission granted")
            }
        }
    }
}
