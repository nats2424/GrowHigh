import SwiftUI
import CoreData
import Combine

/// アプリ全体の状態を管理するObservableObject
class AppState: ObservableObject {
    // MARK: - Navigation State
    @Published var navigationPath = NavigationPath()
    @Published var showingAddTodo = false
    @Published var showingGenderSelection = false
    @Published var showingTaskTutorial = false
    @Published var showingStatsTutorial = false
    @Published var showingJobPromotionAlert = false
    @Published var showingLevelUpModal = false
    
    // MARK: - User State
    @Published var currentUser: User?
    @Published var refreshTrigger = false
    
    // MARK: - Experience & Level System
    @Published var showingExperienceSnackbar = false
    @Published var earnedExperience = 0
    @Published var newJobName = ""
    @Published var newJobDescription = ""
    @Published var levelUpStatistics: LevelUpStatistics?
    
    // MARK: - Services
    private let experienceService = ExperienceService.shared
    private let jobSystemService = JobSystemService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Core Data Context
    var viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        setupNotifications()
        loadCurrentUser()
    }
    
    // MARK: - Setup
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: NSNotification.Name("UserLeveledUp"))
            .sink { [weak self] notification in
                self?.handleLevelUpNotification(notification)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - User Management
    func loadCurrentUser() {
        let request: NSFetchRequest<User> = User.fetchRequest()
        do {
            let users = try viewContext.fetch(request)
            currentUser = users.first
        } catch {
            print("Failed to load user: \(error)")
        }
    }
    
    func refreshData() {
        refreshTrigger.toggle()
        loadCurrentUser()
        
        // Core Dataのリフレッシュ
        viewContext.refreshAllObjects()
    }
    
    // MARK: - Navigation Management
    func navigateToHome() {
        navigationPath = NavigationPath()
    }
    
    func navigateToTodoList() {
        if !navigationPath.isEmpty {
            navigationPath = NavigationPath()
        }
        navigationPath.append("TodoList")
    }
    
    func navigateToStats() {
        if !navigationPath.isEmpty {
            navigationPath = NavigationPath()
        }
        navigationPath.append("Stats")
    }
    
    func navigateToSettings() {
        if !navigationPath.isEmpty {
            navigationPath = NavigationPath()
        }
        navigationPath.append("Settings")
    }
    
    // MARK: - Experience Management
    func showExperienceSnackbar(experience: Int) {
        earnedExperience = experience
        showingExperienceSnackbar = true
        
        // 2秒後に自動で非表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showingExperienceSnackbar = false
        }
    }
    
    // MARK: - Level Up Management
    private func handleLevelUpNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let statistics = userInfo["statistics"] as? LevelUpStatistics else {
            print("❌ Level up notification missing statistics")
            return
        }
        
        print("✅ Level up notification received: Level \(statistics.currentLevel)")
        
        // 既存の職業昇格アラートよりもレベルアップモーダルを優先
        showingJobPromotionAlert = false
        
        // レベルアップモーダルを表示
        levelUpStatistics = statistics
        
        // ハプティックフィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // 少しの遅延を加えて、他のアニメーションと競合しないようにする
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showingLevelUpModal = true
        }
    }
    
    func closeLevelUpModal() {
        showingLevelUpModal = false
        levelUpStatistics = nil
    }
    
    // MARK: - Task Management
    func completeTask(_ task: TodoItem) {
        guard let user = currentUser else { return }
        
        // タスク完了処理
        task.isCompleted = true
        task.completedAt = Date()
        
        // 経験値計算
        let baseExp = experienceService.experienceForTaskCompletion()
        let bonusExp = experienceService.bonusExperience(consecutiveDays: 1) // 簡略実装
        let totalExp = baseExp + bonusExp
        
        // ユーザーに経験値を追加
        user.addExperience(totalExp)
        
        // TaskType変換
        if let taskTypeString = task.taskType,
           let taskType = TaskType(rawValue: taskTypeString) {
            user.completeTask(taskType: taskType)
        }
        
        // Core Dataに保存
        do {
            try viewContext.save()
            
            // 経験値スナックバー表示
            showExperienceSnackbar(experience: totalExp)
            
            // データをリフレッシュ
            refreshData()
            
        } catch {
            print("Failed to save completed task: \(error)")
        }
    }
    
    // MARK: - Modal Management
    func showAddTodo() {
        showingAddTodo = true
    }
    
    func hideAddTodo() {
        showingAddTodo = false
    }
}

// MARK: - Environment Key
struct AppStateKey: EnvironmentKey {
    static let defaultValue = AppState(viewContext: PersistenceController.preview.container.viewContext)
}

extension EnvironmentValues {
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}