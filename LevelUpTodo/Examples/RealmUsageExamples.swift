import Foundation
import RealmSwift

// MARK: - Realm Usage Examples
/**
 * Realmデータ永続化システムの使用例とサンプルコード
 * 
 * このファイルには以下の内容が含まれています：
 * 1. 基本的なCRUD操作の例
 * 2. アプリケーション統合例
 * 3. エラーハンドリング
 * 4. パフォーマンス最適化のヒント
 * 5. テスト用のデータ生成
 */

class RealmUsageExamples {
    
    // MARK: - Service Instances
    private let userService = RealmUserService.shared
    private let taskService = RealmTaskService.shared
    private let databaseManager = RealmDatabaseManager.shared
    
    // MARK: - 1. 基本的なユーザー操作
    
    /// ユーザーの基本操作例
    func userBasicOperationsExample() {
        print("📋 User Basic Operations Example")
        
        do {
            // 1. ユーザー作成
            let user = try userService.createUser(name: "テストユーザー", avatarType: "starter_male")
            print("✅ User created: \(user.name) (Level: \(user.level))")
            
            // 2. ユーザー情報取得
            if let fetchedUser = userService.getPrimaryUser() {
                print("📖 Fetched user: \(fetchedUser.name)")
                
                // 3. ユーザー情報更新
                try userService.updateUser(fetchedUser, name: "更新されたユーザー名")
                print("🔄 User updated: \(fetchedUser.name)")
                
                // 4. 経験値追加とレベルアップ
                try userService.addExperience(to: fetchedUser, amount: 100)
                print("⭐ Experience added. Level: \(fetchedUser.level), EXP: \(fetchedUser.experience)")
                
                // 5. ステータス成長（タスク完了時）
                try userService.completeTask(user: fetchedUser, taskType: .strength, experienceReward: 25)
                print("💪 Task completed. Strength: \(fetchedUser.strength)")
            }
            
        } catch {
            print("❌ Error in user operations: \(error)")
        }
    }
    
    // MARK: - 2. 基本的なタスク操作
    
    /// タスクの基本操作例
    func taskBasicOperationsExample() {
        print("\n📋 Task Basic Operations Example")
        
        guard let user = userService.getPrimaryUser() else {
            print("❌ No user found")
            return
        }
        
        do {
            // 1. タスク作成
            let task1 = try taskService.createTask(
                for: user,
                title: "プロジェクト資料作成",
                description: "来週のプレゼンテーション用資料を作成する",
                experienceReward: 50,
                priority: 3,
                taskType: .intelligence,
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
            )
            
            let task2 = try taskService.createTask(
                for: user,
                title: "ジョギング30分",
                experienceReward: 25,
                priority: 2,
                taskType: .strength
            )
            
            print("✅ Tasks created: \(task1.title), \(task2.title)")
            
            // 2. タスク一覧取得
            let allTasks = taskService.getAllTasks(for: user)
            print("📚 Total tasks: \(allTasks.count)")
            
            // 3. 未完了タスク取得
            let pendingTasks = taskService.getPendingTasks(for: user)
            print("⏳ Pending tasks: \(pendingTasks.count)")
            
            // 4. タスク完了
            try taskService.completeTask(task2)
            print("🎉 Task completed: \(task2.title)")
            
            // 5. タスク更新
            try taskService.updateTask(task1, priority: 1)
            print("🔄 Task priority updated: \(task1.title)")
            
            // 6. 高優先度タスクを検索
            let highPriorityTasks = taskService.getTasksByPriority(for: user, priority: 3)
            print("🔥 High priority tasks: \(highPriorityTasks.count)")
            
        } catch {
            print("❌ Error in task operations: \(error)")
        }
    }
    
    // MARK: - 3. 高度なクエリと統計
    
    /// 高度なクエリと統計の例
    func advancedQueryExamples() {
        print("\n📊 Advanced Query Examples")
        
        guard let user = userService.getPrimaryUser() else {
            print("❌ No user found")
            return
        }
        
        // 1. ユーザー統計取得
        let userStats = userService.getUserStats(for: user)
        print("📈 User Stats:")
        print("  - Level: \(userStats.level)")
        print("  - Total EXP: \(userStats.totalExperience)")
        print("  - Completion Rate: \(String(format: "%.1f", userStats.completionRate * 100))%")
        print("  - Days Active: \(userStats.daysActive)")
        
        // 2. タスク統計取得
        let taskStats = taskService.getTaskStatistics(for: user)
        print("\n📊 Task Stats:")
        print("  - Total: \(taskStats.totalTasks)")
        print("  - Completed: \(taskStats.completedTasks)")
        print("  - Completion Rate: \(String(format: "%.1f", taskStats.completionRate * 100))%")
        print("  - Most Productive Day: \(taskStats.mostProductiveDay)")
        print("  - Completion Streak: \(taskStats.completionStreak) days")
        
        // 3. タスクタイプ別統計
        print("\n🎯 Task Type Statistics:")
        for (taskType, stats) in taskStats.taskTypeStatistics {
            print("  - \(taskType): \(stats.completed)/\(stats.total) (\(String(format: "%.1f", stats.completionRate * 100))%)")
        }
        
        // 4. 期限切れタスクと今日のタスク
        let overdueTasks = taskService.getOverdueTasks(for: user)
        let todayTasks = taskService.getTodayTasks(for: user)
        print("\n📅 Schedule:")
        print("  - Overdue tasks: \(overdueTasks.count)")
        print("  - Today's tasks: \(todayTasks.count)")
    }
    
    // MARK: - 4. バッチ操作の例
    
    /// バッチ操作の例
    func batchOperationsExample() {
        print("\n🔄 Batch Operations Example")
        
        guard let user = userService.getPrimaryUser() else {
            print("❌ No user found")
            return
        }
        
        do {
            // 1. バッチタスク作成
            let taskTemplates = [
                TaskTemplate(title: "朝の運動", description: nil, experienceReward: 20, priority: 2, taskType: .strength, dueDate: nil),
                TaskTemplate(title: "読書30分", description: "技術書を読む", experienceReward: 15, priority: 1, taskType: .intelligence, dueDate: nil),
                TaskTemplate(title: "瞑想10分", description: nil, experienceReward: 10, priority: 1, taskType: .focus, dueDate: nil),
                TaskTemplate(title: "クリエイティブライティング", description: "日記を書く", experienceReward: 15, priority: 1, taskType: .creativity, dueDate: nil)
            ]
            
            let createdTasks = try taskService.createBatchTasks(for: user, taskTemplates: taskTemplates)
            print("✅ Batch created \(createdTasks.count) tasks")
            
            // 2. バッチ更新（優先度を一括変更）
            let lowPriorityTasks = Array(taskService.getTasksByPriority(for: user, priority: 1))
            try taskService.updateBatchTasks(lowPriorityTasks) { task in
                task.experienceReward += 5 // 経験値ボーナスを追加
            }
            print("🔄 Batch updated \(lowPriorityTasks.count) tasks")
            
        } catch {
            print("❌ Error in batch operations: \(error)")
        }
    }
    
    // MARK: - 5. エラーハンドリングの例
    
    /// エラーハンドリングの例
    func errorHandlingExamples() {
        print("\n⚠️ Error Handling Examples")
        
        // 1. 無効なタスク完了の試行
        do {
            if let task = taskService.getTask(byId: "invalid-id") {
                try taskService.completeTask(task)
            } else {
                print("📝 Task with invalid ID not found (expected)")
            }
        } catch {
            print("❌ Expected error caught: \(error)")
        }
        
        // 2. 存在しないアバターへの変更試行
        if let user = userService.getPrimaryUser() {
            do {
                try userService.changeAvatar(user: user, to: "invalid_avatar")
            } catch DatabaseError.operationFailed(let message) {
                print("📝 Avatar change failed (expected): \(message)")
            } catch {
                print("❌ Unexpected error: \(error)")
            }
        }
        
        // 3. データベース整合性チェック
        let migrationService = RealmMigrationService.shared
        let validation = migrationService.validateDataIntegrity()
        print("\n🔍 Data Validation:")
        print(validation.summary)
    }
    
    // MARK: - 6. データエクスポート例
    
    /// データエクスポート例
    func dataExportExample() {
        print("\n💾 Data Export Example")
        
        guard let user = userService.getPrimaryUser() else {
            print("❌ No user found")
            return
        }
        
        // 1. ユーザーデータのJSONエクスポート
        let exportedData = userService.exportUserData(user: user)
        print("📤 User data exported with \(exportedData.keys.count) sections")
        
        // 2. タスクデータのCSVエクスポート
        let csvData = taskService.exportTasksToCSV(for: user)
        print("📊 Task CSV generated (\(csvData.count) characters)")
        
        // 3. データベース統計
        let stats = databaseManager.getDatabaseStats()
        print("📈 Database Stats:")
        for (key, value) in stats {
            print("  - \(key): \(value)")
        }
    }
    
    // MARK: - 7. 実際のアプリケーション統合例
    
    /// SwiftUI View Controller統合例
    func swiftUIIntegrationExample() {
        print("\n🎯 SwiftUI Integration Example")
        
        /*
        // SwiftUI View内での使用例:
        
        struct TaskListView: View {
            @StateObject private var taskObserver = TaskObserver()
            private let userService = RealmUserService.shared
            private let taskService = RealmTaskService.shared
            
            var body: some View {
                NavigationView {
                    List {
                        if let user = userService.getPrimaryUser() {
                            ForEach(Array(taskService.getPendingTasks(for: user)), id: \.id) { task in
                                TaskRowView(task: task)
                            }
                            .onDelete(perform: deleteTasks)
                        }
                    }
                    .navigationTitle("タスク一覧")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("追加") {
                                addNewTask()
                            }
                        }
                    }
                }
            }
            
            private func deleteTasks(offsets: IndexSet) {
                guard let user = userService.getPrimaryUser() else { return }
                let tasks = Array(taskService.getPendingTasks(for: user))
                
                for index in offsets {
                    do {
                        try taskService.deleteTask(tasks[index])
                    } catch {
                        print("Error deleting task: \(error)")
                    }
                }
            }
            
            private func addNewTask() {
                guard let user = userService.getPrimaryUser() else { return }
                
                do {
                    _ = try taskService.createTask(
                        for: user,
                        title: "新しいタスク",
                        experienceReward: 10,
                        priority: 1,
                        taskType: .strength
                    )
                } catch {
                    print("Error creating task: \(error)")
                }
            }
        }
        
        // Realm Observer for SwiftUI
        class TaskObserver: ObservableObject {
            @Published var tasks: [RealmTask] = []
            private var notificationToken: NotificationToken?
            
            init() {
                setupObserver()
            }
            
            deinit {
                notificationToken?.invalidate()
            }
            
            private func setupObserver() {
                guard let user = RealmUserService.shared.getPrimaryUser() else { return }
                
                let results = RealmTaskService.shared.getPendingTasks(for: user)
                notificationToken = results.observe { [weak self] changes in
                    switch changes {
                    case .initial(let results):
                        self?.tasks = Array(results)
                    case .update(let results, _, _, _):
                        self?.tasks = Array(results)
                    case .error(let error):
                        print("Realm observation error: \(error)")
                    }
                }
            }
        }
        */
        
        print("📱 SwiftUI integration code example available in comments")
    }
    
    // MARK: - 8. テストデータ生成
    
    /// テスト用のサンプルデータを生成
    func generateSampleData() {
        print("\n🎭 Generating Sample Data")
        
        do {
            // ユーザー作成
            let user = userService.getOrCreateUser(name: "サンプルユーザー")
            
            // レベルアップのために経験値追加
            try userService.addExperience(to: user, amount: 500)
            
            // さまざまなタスクを作成
            let sampleTasks = [
                ("プログラミング学習", "Swift の基礎を学ぶ", 30, 3, TaskType.intelligence),
                ("筋トレ30分", "腕立て伏せとスクワット", 25, 2, TaskType.strength),
                ("英語の勉強", "TOEIC対策問題を解く", 20, 2, TaskType.intelligence),
                ("ジョギング", "公園を30分走る", 20, 1, TaskType.strength),
                ("読書", "技術書を1時間読む", 15, 1, TaskType.intelligence),
                ("イラスト描画", "デジタルイラストの練習", 25, 2, TaskType.creativity),
                ("瞑想", "マインドフルネス瞑想10分", 15, 1, TaskType.focus),
                ("料理", "新しいレシピに挑戦", 20, 1, TaskType.creativity),
                ("資格勉強", "情報処理技術者試験対策", 35, 3, TaskType.intelligence),
                ("ストレッチ", "全身ストレッチ15分", 10, 1, TaskType.focus)
            ]
            
            for (title, description, exp, priority, taskType) in sampleTasks {
                let task = try taskService.createTask(
                    for: user,
                    title: title,
                    description: description,
                    experienceReward: exp,
                    priority: priority,
                    taskType: taskType,
                    dueDate: Calendar.current.date(byAdding: .day, value: Int.random(in: 1...7), to: Date())
                )
                
                // ランダムに一部のタスクを完了
                if Bool.random() && Bool.random() { // 25%の確率で完了
                    try taskService.completeTask(task)
                }
            }
            
            print("✅ Sample data generated successfully")
            print("👤 User: \(user.name) (Level: \(user.level))")
            print("📋 Tasks: \(user.tasks.count) total")
            print("💪 Stats - STR: \(user.strength), FOC: \(user.focus), INT: \(user.intelligence), CRE: \(user.creativity), END: \(user.endurance)")
            
        } catch {
            print("❌ Error generating sample data: \(error)")
        }
    }
    
    // MARK: - 9. パフォーマンス最適化例
    
    /// パフォーマンス最適化の例
    func performanceOptimizationExample() {
        print("\n⚡ Performance Optimization Example")
        
        guard let user = userService.getPrimaryUser() else {
            print("❌ No user found")
            return
        }
        
        // 1. 効率的なクエリの例
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // インデックスを活用したクエリ
        let completedTasks = taskService.getCompletedTasks(for: user)
        print("📊 Found \(completedTasks.count) completed tasks")
        
        // 複合クエリ
        let highPriorityIntelligenceTasks = user.tasks
            .filter("priority == 3 AND taskType == %@ AND isCompleted == false", TaskType.intelligence.rawValue)
            .sorted(byKeyPath: "createdAt", ascending: false)
        
        print("🎯 Found \(highPriorityIntelligenceTasks.count) high priority intelligence tasks")
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("⏱ Query execution time: \(String(format: "%.3f", timeElapsed)) seconds")
        
        // 2. バッチ処理によるパフォーマンス向上
        do {
            let batchStartTime = CFAbsoluteTimeGetCurrent()
            
            try databaseManager.safeWrite {
                // 全ての未完了タスクの経験値を一度に更新
                for task in user.tasks.filter("isCompleted == false") {
                    task.experienceReward += 1
                }
            }
            
            let batchTimeElapsed = CFAbsoluteTimeGetCurrent() - batchStartTime
            print("🔄 Batch update time: \(String(format: "%.3f", batchTimeElapsed)) seconds")
            
        } catch {
            print("❌ Batch operation error: \(error)")
        }
    }
    
    // MARK: - 10. すべての例を実行
    
    /// 全ての使用例を順番に実行
    func runAllExamples() {
        print("🚀 Running All Realm Usage Examples")
        print("=" * 50)
        
        // 既存データをクリア（テスト用）
        do {
            try databaseManager.resetDatabase()
            print("🧹 Database reset for testing")
        } catch {
            print("⚠️ Could not reset database: \(error)")
        }
        
        // 各例を実行
        userBasicOperationsExample()
        taskBasicOperationsExample()
        advancedQueryExamples()
        batchOperationsExample()
        errorHandlingExamples()
        dataExportExample()
        swiftUIIntegrationExample()
        generateSampleData()
        performanceOptimizationExample()
        
        print("\n✅ All examples completed successfully!")
    }
}

// MARK: - String Extension for Formatting
extension String {
    static func *(left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}