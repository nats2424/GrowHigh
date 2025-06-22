import SwiftUI
import UserNotifications

class NotificationService: ObservableObject {
    @Published var showLevelUpAlert = false
    @Published var newLevel = 1
    @Published var showTaskCompleteAlert = false
    @Published var earnedExperience = 0
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("通知の許可が得られました")
            } else {
                print("通知の許可が得られませんでした")
            }
        }
    }
    
    func showLevelUpNotification(newLevel: Int) {
        DispatchQueue.main.async {
            self.newLevel = newLevel
            self.showLevelUpAlert = true
        }
        
        // システム通知も送信
        let content = UNMutableNotificationContent()
        content.title = "レベルアップ！"
        content.body = "おめでとうございます！レベル\(newLevel)に到達しました！"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "levelup_\(newLevel)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func showTaskCompleteNotification(experience: Int) {
        DispatchQueue.main.async {
            self.earnedExperience = experience
            self.showTaskCompleteAlert = true
        }
    }
    
    func scheduleReminderNotification() {
        // 毎日の特定時間にリマインダー通知を送信
        let content = UNMutableNotificationContent()
        content.title = "タスクをチェックしましょう"
        content.body = "今日も頑張ってレベルアップしましょう！"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 9 // 朝9時
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}