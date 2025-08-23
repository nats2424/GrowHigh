import Foundation
import RealmSwift

// MARK: - Realm Task Service
class RealmTaskService {
    
    // MARK: - Singleton
    static let shared = RealmTaskService()
    
    // MARK: - Properties
    private let databaseManager = RealmDatabaseManager.shared
    private let userService = RealmUserService.shared
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Task CRUD Operations
    
    /// 新しいタスクを作成（IDはUUID自動生成・新仕様対応）
    func createTask(
        for user: RealmUser,
        title: String,
        description: String? = nil,
        priority: Int = 1,
        taskCategory: TaskCategory = .strength,
        isRoutineTask: Bool = false,
        isUnexperiencedTask: Bool = false,
        requiredHours: Double = 1.0,
        hasAnxiety: Bool = false,
        dueDate: Date? = nil
    ) throws -> RealmTask {
        
        let task = RealmTask()
        task.title = title
        task.taskDescription = description
        task.priority = priority
        task.taskCategory = taskCategory.rawValue
        task.isRoutineTask = isRoutineTask
        task.isUnexperiencedTask = isUnexperiencedTask
        task.requiredHours = requiredHours
        task.hasAnxiety = hasAnxiety
        task.createdAt = Date()
        task.dueDate = dueDate
        
        // 経験値は4項目から自動計算される（computed property）
        
        try databaseManager.safeWrite {
            user.tasks.append(task)
        }
        
        print("✅ Task created: \(title) (+\(task.experienceReward) EXP)")
        return task
    }
    
    /// タスクを取得
    func getTask(byId id: String) -> RealmTask? {
        return databaseManager.fetch(RealmTask.self, primaryKey: id)
    }
    
    /// ユーザーの全タスクを取得
    func getAllTasks(for user: RealmUser) -> Results<RealmTask> {
        return user.tasks.sorted(byKeyPath: "createdAt", ascending: false)
    }
    
    /// 未完了タスクを取得
    func getPendingTasks(for user: RealmUser) -> Results<RealmTask> {
        return user.tasks.filter("isCompleted == false").sorted(byKeyPath: "priority", ascending: false)
    }
    
    /// 完了済みタスクを取得
    func getCompletedTasks(for user: RealmUser) -> Results<RealmTask> {
        return user.tasks.filter("isCompleted == true").sorted(byKeyPath: "completedAt", ascending: false)
    }
    
    /// 優先度別タスクを取得
    func getTasksByPriority(for user: RealmUser, priority: Int) -> Results<RealmTask> {
        return user.tasks.filter("priority == %@ AND isCompleted == false", priority)
            .sorted(byKeyPath: "createdAt", ascending: true)
    }
    
    /// タスクカテゴリ別タスクを取得（新仕様）
    func getTasksByCategory(for user: RealmUser, taskCategory: TaskCategory) -> Results<RealmTask> {
        return user.tasks.filter("taskCategory == %@ AND isCompleted == false", taskCategory.rawValue)
            .sorted(byKeyPath: "priority", ascending: false)
    }
    
    /// 期限切れタスクを取得
    func getOverdueTasks(for user: RealmUser) -> Results<RealmTask> {
        let now = Date()
        return user.tasks.filter("dueDate < %@ AND isCompleted == false", now)
            .sorted(byKeyPath: "dueDate", ascending: true)
    }
    
    /// 今日期限のタスクを取得
    func getTodayTasks(for user: RealmUser) -> Results<RealmTask> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return user.tasks.filter("dueDate >= %@ AND dueDate < %@ AND isCompleted == false", startOfDay, endOfDay)
            .sorted(byKeyPath: "priority", ascending: false)
    }
    
    /// タスク検索
    func searchTasks(for user: RealmUser, query: String) -> Results<RealmTask> {
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR taskDescription CONTAINS[cd] %@", query, query)
        return user.tasks.filter(predicate).sorted(byKeyPath: "createdAt", ascending: false)
    }
    
    // MARK: - Task Update Operations
    
    /// タスク情報を更新（新仕様）
    func updateTask(
        _ task: RealmTask,
        title: String? = nil,
        description: String? = nil,
        priority: Int? = nil,
        taskCategory: TaskCategory? = nil,
        isRoutineTask: Bool? = nil,
        isUnexperiencedTask: Bool? = nil,
        requiredHours: Double? = nil,
        hasAnxiety: Bool? = nil,
        dueDate: Date? = nil
    ) throws {
        
        try databaseManager.safeWrite {
            if let newTitle = title {
                task.title = newTitle
            }
            if let newDescription = description {
                task.taskDescription = newDescription
            }
            if let newPriority = priority {
                task.priority = newPriority
            }
            if let newTaskCategory = taskCategory {
                task.taskCategory = newTaskCategory.rawValue
            }
            if let newIsRoutineTask = isRoutineTask {
                task.isRoutineTask = newIsRoutineTask
            }
            if let newIsUnexperiencedTask = isUnexperiencedTask {
                task.isUnexperiencedTask = newIsUnexperiencedTask
            }
            if let newRequiredHours = requiredHours {
                task.requiredHours = newRequiredHours
            }
            if let newHasAnxiety = hasAnxiety {
                task.hasAnxiety = newHasAnxiety
            }
            if let newDueDate = dueDate {
                task.dueDate = newDueDate
            }
            
            // 経験値は4項目から自動計算される（computed property）
        }
        
        print("✅ Task updated: \(task.title) (EXP: \(task.experienceReward))")
    }
    
    /// タスクを完了
    func completeTask(_ task: RealmTask) throws {
        guard !task.isCompleted else {
            print("⚠️ Task already completed: \(task.title)")
            return
        }
        
        try databaseManager.safeWrite {
            task.isCompleted = true
            task.completedAt = Date()
        }
        
        // ユーザーのステータス成長処理（新仕様）
        if let user = task.user.first,
           let taskCategoryEnum = task.taskCategoryEnum {
            try userService.completeTask(
                user: user,
                taskCategory: taskCategoryEnum,
                experienceReward: task.experienceReward
            )
        }
        
        print("🎉 Task completed: \(task.title) (+\(task.experienceReward) EXP)")
    }
    
    /// タスク完了を取り消し
    func uncompleteTask(_ task: RealmTask) throws {
        guard task.isCompleted else {
            print("⚠️ Task is not completed: \(task.title)")
            return
        }
        
        try databaseManager.safeWrite {
            task.isCompleted = false
            task.completedAt = nil
        }
        
        // 経験値の減算処理（ステータスは減算しない設計）
        if let user = task.user.first {
            try userService.addExperience(to: user, amount: -task.experienceReward)
        }
        
        print("↩️ Task uncompleted: \(task.title) (-\(task.experienceReward) EXP)")
    }
    
    /// タスクを削除
    func deleteTask(_ task: RealmTask) throws {
        // 完了済みの場合は経験値を減算
        if task.isCompleted, let user = task.user.first {
            try userService.addExperience(to: user, amount: -task.experienceReward)
        }
        
        try databaseManager.delete(task)
        print("🗑 Task deleted: \(task.title)")
    }
    
    /// 複数のタスクを削除
    func deleteTasks(_ tasks: [RealmTask]) throws {
        for task in tasks {
            try deleteTask(task)
        }
    }
    
    /// 完了済みタスクを一括削除
    func deleteCompletedTasks(for user: RealmUser) throws {
        let completedTasks = Array(getCompletedTasks(for: user))
        try deleteTasks(completedTasks)
        print("🧹 Completed tasks cleared: \(completedTasks.count) tasks")
    }
    
    // MARK: - Task Statistics
    
    /// タスク統計を取得
    func getTaskStatistics(for user: RealmUser) -> TaskStatistics {
        let allTasks = getAllTasks(for: user)
        let completedTasks = getCompletedTasks(for: user)
        let pendingTasks = getPendingTasks(for: user)
        let overdueTasks = getOverdueTasks(for: user)
        let todayTasks = getTodayTasks(for: user)
        
        // タスクカテゴリ別統計（新仕様）
        let taskCategoryStats = TaskCategory.allCases.reduce(into: [String: TaskCategoryStats]()) { result, taskCategory in
            let categoryTasks = user.tasks.filter("taskCategory == %@", taskCategory.rawValue)
            let completed = Array(categoryTasks.filter("isCompleted == true"))
            
            let totalExp = completed.reduce(0) { sum, task in
                sum + task.experienceReward // computed property
            }
            
            result[taskCategory.rawValue] = TaskCategoryStats(
                total: categoryTasks.count,
                completed: completed.count,
                pending: categoryTasks.count - completed.count,
                totalExperience: totalExp
            )
        }
        
        // 優先度別統計
        let priorityStats = (1...3).reduce(into: [Int: Int]()) { result, priority in
            result[priority] = pendingTasks.filter("priority == %@", priority).count
        }
        
        // 完了済みタスクの総経験値計算（computed property使用）
        let completedTasksArray = Array(completedTasks)
        let totalExperienceEarned = completedTasksArray.reduce(0) { sum, task in
            sum + task.experienceReward
        }
        
        // 平均タスク価値計算
        let allTasksArray = Array(allTasks)
        let averageTaskValue = allTasksArray.isEmpty ? 0.0 : 
            Double(allTasksArray.reduce(0) { $0 + $1.experienceReward }) / Double(allTasksArray.count)
        
        return TaskStatistics(
            totalTasks: allTasks.count,
            completedTasks: completedTasks.count,
            pendingTasks: pendingTasks.count,
            overdueTasks: overdueTasks.count,
            todayTasks: todayTasks.count,
            completionRate: allTasks.count > 0 ? Double(completedTasks.count) / Double(allTasks.count) : 0.0,
            totalExperienceEarned: totalExperienceEarned,
            averageTaskValue: averageTaskValue,
            taskCategoryStatistics: taskCategoryStats,
            priorityStatistics: priorityStats,
            mostProductiveDay: getMostProductiveDay(for: user),
            completionStreak: getCompletionStreak(for: user)
        )
    }
    
    /// 最も生産性の高い曜日を取得
    private func getMostProductiveDay(for user: RealmUser) -> String {
        let completedTasks = getCompletedTasks(for: user)
        let calendar = Calendar.current
        
        let dayStats = completedTasks.reduce(into: [Int: Int]()) { result, task in
            if let completedAt = task.completedAt {
                let weekday = calendar.component(.weekday, from: completedAt)
                result[weekday, default: 0] += 1
            }
        }
        
        let mostProductiveDay = dayStats.max(by: { $0.value < $1.value })?.key ?? 1
        return calendar.weekdaySymbols[mostProductiveDay - 1]
    }
    
    /// 連続完了日数を取得
    private func getCompletionStreak(for user: RealmUser) -> Int {
        let completedTasks = getCompletedTasks(for: user)
        let calendar = Calendar.current
        
        // 日付別に完了タスクをグループ化
        let tasksByDate = Dictionary(grouping: completedTasks) { task in
            guard let completedAt = task.completedAt else { return Date.distantPast }
            return calendar.startOfDay(for: completedAt)
        }
        
        let sortedDates = tasksByDate.keys.sorted(by: >)
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if date < currentDate {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Batch Operations
    
    /// 複数タスクを一括作成
    func createBatchTasks(for user: RealmUser, taskTemplates: [TaskTemplate]) throws -> [RealmTask] {
        var createdTasks: [RealmTask] = []
        
        try databaseManager.safeWrite {
            for template in taskTemplates {
                let task = RealmTask()
                task.title = template.title
                task.taskDescription = template.description
                task.priority = template.priority
                task.taskCategory = template.taskCategory.rawValue
                task.isRoutineTask = template.isRoutineTask
                task.isUnexperiencedTask = template.isUnexperiencedTask
                task.requiredHours = template.requiredHours
                task.hasAnxiety = template.hasAnxiety
                task.dueDate = template.dueDate
                task.createdAt = Date()
                // 経験値は自動計算される
                
                user.tasks.append(task)
                createdTasks.append(task)
            }
        }
        
        print("📝 Batch created: \(createdTasks.count) tasks")
        return createdTasks
    }
    
    /// タスクの一括更新
    func updateBatchTasks(_ tasks: [RealmTask], updateBlock: @escaping (RealmTask) -> Void) throws {
        try databaseManager.safeWrite {
            for task in tasks {
                updateBlock(task)
            }
        }
        
        print("📝 Batch updated: \(tasks.count) tasks")
    }
    
    // MARK: - Data Export
    
    /// タスクデータをCSVで出力
    func exportTasksToCSV(for user: RealmUser) -> String {
        let tasks = getAllTasks(for: user)
        var csvContent = "ID,Title,Description,ExperienceReward,Priority,TaskType,IsCompleted,CreatedAt,CompletedAt,DueDate\n"
        
        for task in tasks {
            let row = [
                task.id,
                task.title.replacingOccurrences(of: ",", with: ";"),
                (task.taskDescription ?? "").replacingOccurrences(of: ",", with: ";"),
                "\(task.experienceReward)",
                "\(task.priority)",
                task.taskType,
                "\(task.isCompleted)",
                ISO8601DateFormatter().string(from: task.createdAt),
                task.completedAt.map { ISO8601DateFormatter().string(from: $0) } ?? "",
                task.dueDate.map { ISO8601DateFormatter().string(from: $0) } ?? ""
            ].joined(separator: ",")
            
            csvContent += row + "\n"
        }
        
        return csvContent
    }
}

// MARK: - Supporting Types

struct TaskTemplate {  // 新仕様
    let title: String
    let description: String?
    let priority: Int
    let taskCategory: TaskCategory
    let isRoutineTask: Bool
    let isUnexperiencedTask: Bool
    let requiredHours: Double
    let hasAnxiety: Bool
    let dueDate: Date?
}

struct TaskStatistics {
    let totalTasks: Int
    let completedTasks: Int
    let pendingTasks: Int
    let overdueTasks: Int
    let todayTasks: Int
    let completionRate: Double
    let totalExperienceEarned: Int
    let averageTaskValue: Double
    let taskCategoryStatistics: [String: TaskCategoryStats]  // 新仕様
    let priorityStatistics: [Int: Int]
    let mostProductiveDay: String
    let completionStreak: Int
}

struct TaskCategoryStats {  // 新仕様
    let total: Int
    let completed: Int
    let pending: Int
    let totalExperience: Int
    
    var completionRate: Double {
        return total > 0 ? Double(completed) / Double(total) : 0.0
    }
}

// MARK: - Task Filters
enum TaskFilter {
    case all
    case pending
    case completed
    case overdue
    case today
    case priority(Int)
    case taskCategory(TaskCategory)
    
    func apply(to tasks: Results<RealmTask>) -> Results<RealmTask> {
        switch self {
        case .all:
            return tasks
        case .pending:
            return tasks.filter("isCompleted == false")
        case .completed:
            return tasks.filter("isCompleted == true")
        case .overdue:
            return tasks.filter("dueDate < %@ AND isCompleted == false", Date())
        case .today:
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return tasks.filter("dueDate >= %@ AND dueDate < %@ AND isCompleted == false", startOfDay, endOfDay)
        case .priority(let priority):
            return tasks.filter("priority == %@ AND isCompleted == false", priority)
        case .taskCategory(let taskCategory):
            return tasks.filter("taskCategory == %@ AND isCompleted == false", taskCategory.rawValue)
        }
    }
}

// MARK: - Task Sort Options
enum TaskSortOption {
    case createdDate(ascending: Bool)
    case dueDate(ascending: Bool)
    case priority(ascending: Bool)
    case experienceReward(ascending: Bool)
    case title(ascending: Bool)
    
    func apply(to tasks: Results<RealmTask>) -> Results<RealmTask> {
        switch self {
        case .createdDate(let ascending):
            return tasks.sorted(byKeyPath: "createdAt", ascending: ascending)
        case .dueDate(let ascending):
            return tasks.sorted(byKeyPath: "dueDate", ascending: ascending)
        case .priority(let ascending):
            return tasks.sorted(byKeyPath: "priority", ascending: ascending)
        case .experienceReward(let ascending):
            return tasks.sorted(byKeyPath: "experienceReward", ascending: ascending)
        case .title(let ascending):
            return tasks.sorted(byKeyPath: "title", ascending: ascending)
        }
    }
}