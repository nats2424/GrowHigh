import Foundation
import CoreData
import RealmSwift

class LevelUpStatisticsService {
    static let shared = LevelUpStatisticsService()
    
    private init() {}
    
    // MARK: - Main Statistics Calculation
    
    /// ユーザーのレベルアップ時に統計情報を計算して返す
    func calculateLevelUpStatistics(for user: User, newLevel: Int, previousLevel: Int) -> LevelUpStatistics {
        let daysSinceFirstTask = calculateDaysSinceFirstTask(for: user)
        let mostCompletedTaskType = getMostCompletedTaskType(for: user)
        let jobTitle = getCurrentJobTitle(for: user)
        let previousJobTitle = getPreviousJobTitle(for: user, previousLevel: previousLevel)
        let improvementMetric = calculateImprovementMetric(for: user, previousLevel: previousLevel)
        let consecutiveDays = calculateConsecutiveDays(for: user)
        let totalTasksCompleted = getTotalTasksCompleted(for: user)
        let completionRate = calculateCompletionRateImprovement(for: user)
        let averageCompletionTime = calculateAverageCompletionTime(for: user)
        let jobCategory = JobSystemService.shared.getDominantJobCategory(for: user)
        
        // レベルアップのタイプを判定
        let isFirstJobAcquisition = newLevel == 5 && previousLevel < 5
        let isJobEvolution = newLevel >= 10 && (newLevel % 5 == 0 || newLevel % 10 == 0)
        let isConsecutiveStreak = consecutiveDays >= 7
        
        return LevelUpStatistics(
            daysSinceFirstTask: daysSinceFirstTask,
            mostCompletedTaskType: mostCompletedTaskType,
            currentLevel: newLevel,
            jobTitle: jobTitle,
            previousJobTitle: previousJobTitle,
            improvementMetric: improvementMetric,
            consecutiveDays: consecutiveDays,
            totalTasksCompleted: totalTasksCompleted,
            completionRate: completionRate,
            averageCompletionTime: averageCompletionTime,
            jobCategory: jobCategory,
            isFirstJobAcquisition: isFirstJobAcquisition,
            isJobEvolution: isJobEvolution,
            isConsecutiveStreak: isConsecutiveStreak
        )
    }
    
    // MARK: - Individual Calculation Methods
    
    /// 最初のタスク完了から現在までの日数を計算
    private func calculateDaysSinceFirstTask(for user: User) -> Int {
        // Core Data版
        let request: NSFetchRequest<TodoItem> = TodoItem.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND isCompleted == %@", user, NSNumber(value: true))
        request.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: true)]
        request.fetchLimit = 1
        
        do {
            let context = PersistenceController.shared.container.viewContext
            let completedTasks = try context.fetch(request)
            
            if let firstTask = completedTasks.first, let completedAt = firstTask.completedAt {
                let calendar = Calendar.current
                let daysBetween = calendar.dateComponents([.day], from: completedAt, to: Date()).day ?? 0
                return max(1, daysBetween + 1) // 最低1日として返す
            }
        } catch {
            print("Error fetching first completed task: \(error)")
        }
        
        return 1 // デフォルト値
    }
    
    /// 最も多く完了したタスクタイプを取得
    private func getMostCompletedTaskType(for user: User) -> TaskCategory {
        let request: NSFetchRequest<TodoItem> = TodoItem.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND isCompleted == %@", user, NSNumber(value: true))
        
        do {
            let context = PersistenceController.shared.container.viewContext
            let completedTasks = try context.fetch(request)
            
            var taskTypeCounts: [String: Int] = [:]
            
            for task in completedTasks {
                let taskType = task.taskType ?? "strength"
                taskTypeCounts[taskType, default: 0] += 1
            }
            
            if let mostCommonType = taskTypeCounts.max(by: { $0.value < $1.value })?.key {
                return TaskCategory(rawValue: mostCommonType) ?? .strength
            }
        } catch {
            print("Error fetching task type statistics: \(error)")
        }
        
        return .strength // デフォルト値
    }
    
    /// 現在の職業名を取得
    private func getCurrentJobTitle(for user: User) -> String {
        if let currentJob = JobSystemService.shared.getCurrentJob(for: user) {
            return currentJob.name
        }
        
        return "冒険者" // デフォルト職業名
    }
    
    /// 前の職業名を取得
    private func getPreviousJobTitle(for user: User, previousLevel: Int) -> String? {
        let tempLevel = user.level
        user.level = Int32(previousLevel)
        
        let previousJob = JobSystemService.shared.getCurrentJob(for: user)
        let previousJobTitle = previousJob?.name
        
        user.level = tempLevel // 元のレベルに戻す
        
        return previousJobTitle
    }
    
    /// 改善指標を計算（前回比など）
    private func calculateImprovementMetric(for user: User, previousLevel: Int) -> String {
        // 前回の同レベル達成時との比較を行う
        let levelDifference = Int(user.level) - previousLevel
        
        if levelDifference == 1 {
            return "順調なペース"
        } else if levelDifference > 1 {
            return "加速的成長"
        } else {
            let daysSinceFirst = calculateDaysSinceFirstTask(for: user)
            return "\(daysSinceFirst)日での達成"
        }
    }
    
    /// 連続達成日数を計算
    private func calculateConsecutiveDays(for user: User) -> Int {
        let request: NSFetchRequest<TodoItem> = TodoItem.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND isCompleted == %@", user, NSNumber(value: true))
        request.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]
        
        do {
            let context = PersistenceController.shared.container.viewContext
            let completedTasks = try context.fetch(request)
            
            var consecutiveDays = 0
            var currentDate = Calendar.current.startOfDay(for: Date())
            
            // 日ごとにタスク完了があるかチェック
            var tasksByDate: [Date: [TodoItem]] = [:]
            for task in completedTasks {
                if let completedAt = task.completedAt {
                    let date = Calendar.current.startOfDay(for: completedAt)
                    tasksByDate[date, default: []].append(task)
                }
            }
            
            // 連続日数をカウント
            while tasksByDate[currentDate] != nil {
                consecutiveDays += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            }
            
            return consecutiveDays
        } catch {
            print("Error calculating consecutive days: \(error)")
            return 0
        }
    }
    
    /// 総完了タスク数を取得
    private func getTotalTasksCompleted(for user: User) -> Int {
        let request: NSFetchRequest<TodoItem> = TodoItem.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND isCompleted == %@", user, NSNumber(value: true))
        
        do {
            let context = PersistenceController.shared.container.viewContext
            return try context.count(for: request)
        } catch {
            print("Error counting completed tasks: \(error)")
            return 0
        }
    }
    
    /// 完了率の向上値を計算
    private func calculateCompletionRateImprovement(for user: User) -> Double {
        let allTasksRequest: NSFetchRequest<TodoItem> = TodoItem.fetchRequest()
        allTasksRequest.predicate = NSPredicate(format: "user == %@", user)
        
        let completedTasksRequest: NSFetchRequest<TodoItem> = TodoItem.fetchRequest()
        completedTasksRequest.predicate = NSPredicate(format: "user == %@ AND isCompleted == %@", user, NSNumber(value: true))
        
        do {
            let context = PersistenceController.shared.container.viewContext
            let totalTasks = try context.count(for: allTasksRequest)
            let completedTasks = try context.count(for: completedTasksRequest)
            
            guard totalTasks > 0 else { return 0.0 }
            
            let completionRate = Double(completedTasks) / Double(totalTasks) * 100.0
            
            // 前回のレベルアップ時との比較は今回は簡略化
            // 実際の実装では過去のスナップショットデータが必要
            return completionRate
        } catch {
            print("Error calculating completion rate: \(error)")
            return 0.0
        }
    }
    
    /// 平均完了時間を計算
    private func calculateAverageCompletionTime(for user: User) -> Double {
        let request: NSFetchRequest<TodoItem> = TodoItem.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND isCompleted == %@ AND completedAt != nil AND createdAt != nil", user, NSNumber(value: true))
        
        do {
            let context = PersistenceController.shared.container.viewContext
            let completedTasks = try context.fetch(request)
            
            var totalCompletionTime: TimeInterval = 0
            var validTasks = 0
            
            for task in completedTasks {
                if let createdAt = task.createdAt, let completedAt = task.completedAt {
                    let completionTime = completedAt.timeIntervalSince(createdAt)
                    if completionTime > 0 && completionTime < 86400 * 30 { // 30日以内の現実的な値のみ
                        totalCompletionTime += completionTime
                        validTasks += 1
                    }
                }
            }
            
            guard validTasks > 0 else { return 0.0 }
            
            return totalCompletionTime / Double(validTasks) / 3600.0 // 時間単位で返す
        } catch {
            print("Error calculating average completion time: \(error)")
            return 0.0
        }
    }
}

// MARK: - Extensions for Legacy Support

extension LevelUpStatisticsService {
    
    /// Realm版のユーザーデータにも対応
    func calculateLevelUpStatistics(for realmUser: RealmUser, newLevel: Int, previousLevel: Int) -> LevelUpStatistics {
        let daysSinceFirstTask = calculateDaysSinceFirstTask(for: realmUser)
        let mostCompletedTaskType = getMostCompletedTaskType(for: realmUser)
        let jobTitle = "冒険者" // Realm版では簡略化
        let improvementMetric = "\(daysSinceFirstTask)日での達成"
        let consecutiveDays = 0 // Realm版では簡略化
        let totalTasksCompleted = realmUser.tasks.filter("isCompleted == true").count
        
        return LevelUpStatistics(
            daysSinceFirstTask: daysSinceFirstTask,
            mostCompletedTaskType: mostCompletedTaskType,
            currentLevel: newLevel,
            jobTitle: jobTitle,
            previousJobTitle: nil,
            improvementMetric: improvementMetric,
            consecutiveDays: consecutiveDays,
            totalTasksCompleted: totalTasksCompleted,
            completionRate: 0.0,
            averageCompletionTime: 0.0,
            jobCategory: .fighter,
            isFirstJobAcquisition: newLevel == 5,
            isJobEvolution: newLevel >= 10,
            isConsecutiveStreak: false
        )
    }
    
    private func calculateDaysSinceFirstTask(for realmUser: RealmUser) -> Int {
        let completedTasks = realmUser.tasks.filter("isCompleted == true").sorted(byKeyPath: "completedAt")
        
        if let firstTask = completedTasks.first, let completedAt = firstTask.completedAt {
            let calendar = Calendar.current
            let daysBetween = calendar.dateComponents([.day], from: completedAt, to: Date()).day ?? 0
            return max(1, daysBetween + 1)
        }
        
        return 1
    }
    
    private func getMostCompletedTaskType(for realmUser: RealmUser) -> TaskCategory {
        let completedTasks = realmUser.tasks.filter("isCompleted == true")
        var taskTypeCounts: [String: Int] = [:]
        
        for task in completedTasks {
            taskTypeCounts[task.taskCategory, default: 0] += 1
        }
        
        if let mostCommonType = taskTypeCounts.max(by: { $0.value < $1.value })?.key {
            return TaskCategory(rawValue: mostCommonType) ?? .strength
        }
        
        return .strength
    }
}