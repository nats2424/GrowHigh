import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var notificationService = NotificationService()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodoListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("タスク")
                }
                .tag(0)
            
            AvatarView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("アバター")
                }
                .tag(1)
            
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("統計")
                }
                .tag(2)
        }
        .accentColor(.purple)
        .environmentObject(notificationService)
        .onAppear {
            setupInitialUser()
            notificationService.requestNotificationPermission()
            notificationService.scheduleReminderNotification()
        }
        .alert("レベルアップ！", isPresented: $notificationService.showLevelUpAlert) {
            Button("OK") { }
        } message: {
            Text("おめでとうございます！レベル\(notificationService.newLevel)に到達しました！")
        }
        .alert("タスク完了！", isPresented: $notificationService.showTaskCompleteAlert) {
            Button("OK") { }
        } message: {
            Text("\(notificationService.earnedExperience) EXPを獲得しました！")
        }
    }
    
    private func setupInitialUser() {
        let userService = UserService(context: viewContext)
        _ = userService.getOrCreateUser()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}