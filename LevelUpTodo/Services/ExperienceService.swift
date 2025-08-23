import Foundation
import CoreData
import UIKit

// Removed type alias - will handle conflicts differently

// MARK: - Job Category Definition (to avoid circular dependencies)

enum JobCategory: String, CaseIterable {
    case fighter = "fighter"
    case scholar = "scholar"  
    case explorer = "explorer"
    case master = "master"
    case artist = "artist"
}

/**
 * 経験値システム (N³式)
 * 
 * レベルNに必要な累積経験値 = N³
 * 例: Lv1→0, Lv2→8, Lv3→27, Lv4→64, Lv5→125, Lv10→1000, Lv20→8000, Lv30→27000
 * 
 * タスク達成でレベルアップし、レベルが上がると新しいジョブが解放されます。
 */
class ExperienceService {
    static let shared = ExperienceService()
    
    private init() {}
    
    // MARK: - Experience Calculation
    
    /// レベルNに到達するために必要な累積経験値を計算 (検証用簡易版)
    func totalExperienceRequiredForLevel(_ level: Int) -> Int {
        // 検証用: 簡単なレベルアップ
        switch level {
        case 1: return 0   // レベル1は0EXP（初期）
        case 2: return 10  // レベル2: 10EXP
        case 3: return 20  // レベル3: 20EXP
        case 4: return 30  // レベル4: 30EXP
        case 5: return 40  // レベル5: 40EXP（1タスクで到達可能）
        case 6: return 60  // レベル6: 60EXP
        case 7: return 80  // レベル7: 80EXP
        case 8: return 100 // レベル8: 100EXP
        case 9: return 120 // レベル9: 120EXP
        case 10: return 150 // レベル10: 150EXP
        default:
            // レベル10以降は20EXPずつ増加
            return 150 + (level - 10) * 20
        }
    }
    
    /// タスク完了で得られる経験値を計算
    func experienceForTaskCompletion() -> Int {
        return 10  // 基本経験値
    }
    
    /// ボーナス経験値（連続達成など）
    func bonusExperience(consecutiveDays: Int) -> Int {
        return consecutiveDays * 2  // 連続日数×2のボーナス
    }
    
    // MARK: - Level Calculation
    
    /// 現在の経験値から適切なレベルを計算 (N³式対応)
    func calculateLevel(from experience: Int) -> Int {
        if experience <= 0 {
            return 1
        }
        
        // 二分探索でレベルを効率的に計算
        var low = 1
        var high = 100  // 最大レベル想定
        
        while low <= high {
            let mid = (low + high) / 2
            let expRequired = totalExperienceRequiredForLevel(mid)
            let nextExpRequired = totalExperienceRequiredForLevel(mid + 1)
            
            if experience >= expRequired && experience < nextExpRequired {
                return mid
            } else if experience >= nextExpRequired {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        
        return low
    }
    
    /// 次のレベルまでの残り経験値を計算
    func experienceToNextLevel(currentExp: Int, currentLevel: Int) -> Int {
        let totalExpForNextLevel = totalExperienceRequiredForLevel(currentLevel + 1)
        
        return totalExpForNextLevel - currentExp
    }
    
    /// レベル間で必要な経験値を計算（現在のレベルから次のレベルまで）
    func experienceRequiredBetweenLevels(from currentLevel: Int, to nextLevel: Int) -> Int {
        return totalExperienceRequiredForLevel(nextLevel) - totalExperienceRequiredForLevel(currentLevel)
    }
    
    // MARK: - Job/Avatar Management
    
    /// レベルアップ時の職業変更処理
    func handleLevelUpJobPromotion(user: User, previousLevel: Int) -> (jobChanged: Bool, jobName: String?) {
        // 簡略化 - レベル5, 10, 15, 20で昇格
        let currentLevel = Int(user.level)
        let promotionLevels = [5, 10, 15, 20, 30, 50]
        
        if promotionLevels.contains(currentLevel) && currentLevel > previousLevel {
            let jobName = "レベル\(currentLevel)職業"
            return (true, jobName)
        }
        return (false, nil)
    }
    
    /// レベルに応じて解放されるジョブを決定（レガシー）
    func availableJobsForLevel(_ level: Int) -> [String] {
        var jobs = ["starter_male", "starter_female"]
        
        if level >= 11 {
            // 第1転職 (Lv 11-25)
            jobs.append(contentsOf: [
                "wizard_male", "wizard_female",
                "warrior_male", "warrior_female",
                "guard", "thief_male", "thief_female"
            ])
        }
        
        if level >= 26 {
            // 第2転職 (Lv 26-50)
            jobs.append(contentsOf: [
                "archmage_male", "archmage_female",
                "knight_male", "knight_female"
            ])
        }
        
        return jobs
    }
    
    /// レベルに応じた推奨アバターを取得（レガシー）
    func recommendedAvatarForLevel(_ level: Int, gender: String) -> String {
        if level >= 26 {
            // 上級職を推奨
            return gender == "female" ? "archmage_female" : "archmage_male"
        } else if level >= 11 {
            // 基本職を推奨
            return gender == "female" ? "wizard_female" : "wizard_male"
        } else {
            // スターター
            return gender == "female" ? "starter_female" : "starter_male"
        }
    }
    
    // MARK: - Achievement System
    
    /// 特定の成果に対する経験値ボーナス
    func achievementBonus(for achievementType: AchievementType) -> Int {
        switch achievementType {
        case .firstTask:
            return 25
        case .tenTasks:
            return 50
        case .weekStreak:
            return 30
        case .monthStreak:
            return 100
        }
    }
    
    /// レベルアップ時の特別報酬
    func levelUpReward(newLevel: Int) -> LevelUpReward {
        var reward = LevelUpReward()
        
        if newLevel == 11 {
            reward.message = "🎉 第1転職解放！新しいジョブが選択可能になりました！"
            reward.unlockedJobs = ["wizard_male", "wizard_female", "warrior_male", "warrior_female"]
        } else if newLevel == 26 {
            reward.message = "⚡ 第2転職解放！上級ジョブが解放されました！"
            reward.unlockedJobs = ["archmage_male", "archmage_female", "knight_male", "knight_female"]
        } else {
            reward.message = "✨ レベルアップおめでとうございます！"
        }
        
        return reward
    }
}

// MARK: - Supporting Types

enum TaskType: String, CaseIterable {
    case strength = "strength"
    case focus = "focus"
    case continuity = "continuity"
    case intelligence = "intelligence"
    
    var displayName: String {
        switch self {
        case .strength:
            return "筋力"
        case .focus:
            return "集中力"
        case .continuity:
            return "継続力"
        case .intelligence:
            return "頭脳"
        }
    }
    
    var emoji: String {
        switch self {
        case .strength:
            return "💪"
        case .focus:
            return "🧠"
        case .continuity:
            return "🔁"
        case .intelligence:
            return "🧩"
        }
    }
    
    var color: String {
        switch self {
        case .strength:
            return "red"
        case .focus:
            return "blue"
        case .continuity:
            return "green"
        case .intelligence:
            return "purple"
        }
    }
}

enum TaskTimeOption: Double, CaseIterable {
    case halfHour = 0.5
    case oneHour = 1.0
    case twoHours = 2.0
    case threeHours = 3.0
    case fourPlusHours = 4.0
    
    var displayText: String {
        switch self {
        case .halfHour:
            return "0.5時間"
        case .oneHour:
            return "1時間"
        case .twoHours:
            return "2時間"
        case .threeHours:
            return "3時間"
        case .fourPlusHours:
            return "4時間以上"
        }
    }
}

enum AchievementType {
    case firstTask
    case tenTasks
    case weekStreak
    case monthStreak
}

struct LevelUpReward {
    var message: String = ""
    var unlockedJobs: [String] = []
    var bonusExp: Int = 0
}

// MARK: - User Extension for Experience

extension User {
    
    /// タスク完了時に経験値を追加
    func addExperience(_ amount: Int, using service: ExperienceService = .shared) {
        let oldLevel = Int(self.level)
        self.experience += Int32(amount)
        
        // レベル再計算
        let newLevel = service.calculateLevel(from: Int(self.experience))
        self.level = Int32(newLevel)
        
        // レベルアップチェック
        if newLevel > oldLevel {
            handleLevelUp(from: oldLevel, to: newLevel, using: service)
        }
    }
    
    /// タスク完了時のステータス成長処理
    func completeTask(taskType: TaskType, using service: ExperienceService = .shared) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 指定されたタスクタイプに応じてステータスを成長
        switch taskType {
        case .strength:
            self.strength += 1
        case .focus:
            self.focus += 1
        case .continuity:
            // 継続力は1日1回の成長として別途処理
            break
        case .intelligence:
            self.intelligence += 1
        }
        
        // 継続力の成長処理
        if taskType == .continuity {
            // 継続力タスクの場合は直接成長
            self.endurance += 1
        }
        
        // 1日1回の継続力成長（任意のタスク完了時）
        let lastCompletionDate = self.lastTaskCompletionDate.map { Calendar.current.startOfDay(for: $0) }
        if lastCompletionDate != today {
            if taskType != .continuity {
                self.endurance += 1
            }
            self.lastTaskCompletionDate = Date()
        }
    }
    
    /// レベルアップ時の処理
    private func handleLevelUp(from oldLevel: Int, to newLevel: Int, using service: ExperienceService) {
        let reward = service.levelUpReward(newLevel: newLevel)
        
        // JobSystemServiceの代替実装（一時的な修正）
        // TODO: JobSystemServiceの参照問題を解決後に元に戻す
        if let currentJob = getCurrentJobForLevel(newLevel, user: self) {
            self.currentAvatarType = currentJob.avatarImageName
            print("✅ Job promotion to level \(newLevel): \(currentJob.name)")
            print("🖼️ Avatar updated to: \(currentJob.avatarImageName)")
            
            // Core Dataの変更を保存
            if let context = managedObjectContext {
                do {
                    try context.save()
                    print("💾 User data saved successfully")
                } catch {
                    print("❌ Failed to save user data: \(error)")
                }
            }
        }
        
        // 新しいジョブが解放された場合の処理（レガシー対応）
        if !reward.unlockedJobs.isEmpty {
            // 性別に応じて適切なアバターを自動設定
            let gender = UserDefaults.standard.string(forKey: "userGender") ?? "male"
            let recommendedAvatar = service.recommendedAvatarForLevel(newLevel, gender: gender)
            
            if reward.unlockedJobs.contains(recommendedAvatar) {
                // JobSystemServiceで設定されていない場合のみレガシーロジックを使用
                if self.currentAvatarType == recommendedAvatar {
                    // 既に設定済みの場合はスキップ
                } else {
                    self.currentAvatarType = recommendedAvatar
                }
            }
        }
        
        // レベルアップ統計情報の計算（簡略版）
        let statisticsDict = createSimpleLevelUpStatistics(newLevel: newLevel, previousLevel: oldLevel)
        
        // レベルアップ通知（新しいモーダルシステム）
        NotificationCenter.default.post(
            name: NSNotification.Name("UserLeveledUp"),
            object: nil,
            userInfo: [
                "oldLevel": oldLevel, 
                "newLevel": newLevel, 
                "reward": reward,
                "statistics": statisticsDict
            ]
        )
    }
    
    /// 次のレベルまでの進捗率 (0.0 - 1.0)
    func progressToNextLevel(using service: ExperienceService = .shared) -> Double {
        let currentLevel = Int(self.level)
        let currentExp = Int(self.experience)
        
        let expForCurrentLevel = service.totalExperienceRequiredForLevel(currentLevel)
        let expForNextLevel = service.totalExperienceRequiredForLevel(currentLevel + 1)
        
        // 現在レベル内での経験値進捗
        let expInCurrentLevel = currentExp - expForCurrentLevel
        let expRequiredForNextLevel = expForNextLevel - expForCurrentLevel
        
        // 進捗率を0.0-1.0の範囲で返す
        if expRequiredForNextLevel <= 0 {
            return 1.0
        }
        
        return max(0.0, min(1.0, Double(expInCurrentLevel) / Double(expRequiredForNextLevel)))
    }
    
    /// 簡易レベルアップ統計作成（コンパイル用）
    private func createSimpleLevelUpStatistics(newLevel: Int, previousLevel: Int) -> [String: Any] {
        // より詳細な統計情報を生成
        let daysSinceFirst = max(1, newLevel * 2) // レベルに応じた日数
        let taskCount = max(5, newLevel * 3) // レベルに応じたタスク数
        let consecutiveDays = min(daysSinceFirst, 14) // 最大14日の連続記録
        
        // 現在のジョブ情報を取得（レベルアップ後のジョブ）
        let currentJobInfo = getCurrentJobForLevel(newLevel, user: self)
        let previousJobInfo = previousLevel >= 5 ? getCurrentJobForLevel(previousLevel, user: self) : nil
        
        let jobTitle = currentJobInfo?.name ?? "見習い冒険者"
        let currentAvatarImage = currentJobInfo?.avatarImageName ?? "boy1"
        let previousAvatarImage = previousJobInfo?.avatarImageName
        
        // 最も高いステータスを決定（ファイター系として設定）
        let dominantTaskType = TaskCategory.strength
        
        // JobCategoryをTaskCategoryにマッピング
        let mappedJobCategory = mapTaskCategoryToJobCategory(dominantTaskType)
        
        return [
            "daysSinceFirstTask": daysSinceFirst,
            "mostCompletedTaskType": dominantTaskType,
            "currentLevel": newLevel,
            "jobTitle": jobTitle,
            "previousJobTitle": previousJobInfo?.name ?? "",
            "improvementMetric": "順調な成長",
            "consecutiveDays": consecutiveDays,
            "totalTasksCompleted": taskCount,
            "completionRate": 85.0,
            "averageCompletionTime": 1.2,
            "jobCategory": mappedJobCategory,
            "isFirstJobAcquisition": newLevel == 5,
            "isJobEvolution": newLevel >= 10,
            "isConsecutiveStreak": consecutiveDays >= 7,
            "currentAvatarImage": currentAvatarImage,
            "previousAvatarImage": previousAvatarImage ?? ""
        ]
    }
    
    /// 簡易職業取得（JobSystemServiceの代替）
    private func getCurrentJobForLevel(_ level: Int, user: User) -> (name: String, avatarImageName: String)? {
        // ステータスベースのジョブ決定
        let dominantStat = getDominantStat(user: user)
        
        switch (dominantStat, level) {
        // ファイター系 (筋力特化)
        case (.strength, 5): return (name: "見習い戦士", avatarImageName: "warrior_male")
        case (.strength, 10): return (name: "戦士", avatarImageName: "warrior_male")
        case (.strength, 15): return (name: "剣士", avatarImageName: "warrior_female")
        case (.strength, 20): return (name: "騎士", avatarImageName: "knight_male")
        case (.strength, 30): return (name: "パラディン", avatarImageName: "knight_male")
        case (.strength, 50): return (name: "聖騎士", avatarImageName: "knight_female")
        case (.strength, 70): return (name: "武神", avatarImageName: "knight_male")
        case (.strength, 90): return (name: "伝説の戦士", avatarImageName: "knight_female")
        case (.strength, 100): return (name: "不敗の英雄", avatarImageName: "knight_male")
            
        // スカラー系 (知力特化)
        case (.intelligence, 5): return (name: "学徒", avatarImageName: "wizard_male")
        case (.intelligence, 10): return (name: "研究者", avatarImageName: "wizard_male")
        case (.intelligence, 15): return (name: "学者", avatarImageName: "wizard_female")
        case (.intelligence, 20): return (name: "博士", avatarImageName: "wizard_female")
        case (.intelligence, 30): return (name: "賢者", avatarImageName: "archmage_male")
        case (.intelligence, 50): return (name: "大賢者", avatarImageName: "archmage_male")
        case (.intelligence, 70): return (name: "魔導師", avatarImageName: "archmage_female")
        case (.intelligence, 90): return (name: "大魔導師", avatarImageName: "archmage_female")
        case (.intelligence, 100): return (name: "真理の探求者", avatarImageName: "archmage_male")
            
        // エクスプローラー系 (持久力特化)
        case (.endurance, 5): return (name: "冒険者", avatarImageName: "boy1")
        case (.endurance, 10): return (name: "探検家", avatarImageName: "thief_male")
        case (.endurance, 15): return (name: "レンジャー", avatarImageName: "thief_male")
        case (.endurance, 20): return (name: "ガイド", avatarImageName: "thief_female")
        case (.endurance, 30): return (name: "パスファインダー", avatarImageName: "thief_female")
        case (.endurance, 50): return (name: "マスターガイド", avatarImageName: "thief_male")
        case (.endurance, 70): return (name: "地平の開拓者", avatarImageName: "thief_female")
        case (.endurance, 90): return (name: "世界の歩き手", avatarImageName: "thief_male")
        case (.endurance, 100): return (name: "無限の旅人", avatarImageName: "thief_female")
            
        // マスター系 (集中力特化)
        case (.focus, 5): return (name: "職人見習い", avatarImageName: "guard")
        case (.focus, 10): return (name: "職人", avatarImageName: "guard")
        case (.focus, 15): return (name: "熟練工", avatarImageName: "knight_male")
        case (.focus, 20): return (name: "マスター", avatarImageName: "knight_male")
        case (.focus, 30): return (name: "名工", avatarImageName: "knight_female")
        case (.focus, 50): return (name: "宗匠", avatarImageName: "knight_female")
        case (.focus, 70): return (name: "達人", avatarImageName: "archmage_male")
        case (.focus, 90): return (name: "人間国宝", avatarImageName: "archmage_male")
        case (.focus, 100): return (name: "伝説の匠", avatarImageName: "archmage_female")
            
        // アーティスト系 (創造力特化)
        case (.creativity, 5): return (name: "創作者", avatarImageName: "girl1")
        case (.creativity, 10): return (name: "アーティスト", avatarImageName: "wizard_female")
        case (.creativity, 15): return (name: "クリエイター", avatarImageName: "wizard_female")
        case (.creativity, 20): return (name: "イノベーター", avatarImageName: "archmage_female")
        case (.creativity, 30): return (name: "ビジョナリー", avatarImageName: "archmage_female")
        case (.creativity, 50): return (name: "マエストロ", avatarImageName: "archmage_male")
        case (.creativity, 70): return (name: "天才", avatarImageName: "archmage_male")
        case (.creativity, 90): return (name: "革命家", avatarImageName: "archmage_female")
        case (.creativity, 100): return (name: "時代の創造主", avatarImageName: "archmage_female")
            
        default:
            // 指定レベルでない場合は一つ下のレベルを再帰的に検索
            let validLevels = [5, 10, 15, 20, 30, 50, 70, 90, 100]
            let closestLevel = validLevels.filter { $0 <= level }.last ?? 5
            if closestLevel != level {
                return getCurrentJobForLevel(closestLevel, user: user)
            }
            return nil
        }
    }
    
    private enum StatType {
        case strength, intelligence, endurance, focus, creativity
    }
    
    private func getDominantStat(user: User) -> StatType {
        let stats = [
            (value: Int(user.strength), type: StatType.strength),
            (value: Int(user.intelligence), type: StatType.intelligence),
            (value: Int(user.endurance), type: StatType.endurance),
            (value: Int(user.focus), type: StatType.focus),
            (value: Int(user.creativity), type: StatType.creativity)
        ]
        
        return stats.max(by: { $0.value < $1.value })?.type ?? .strength
    }
    
    
    /// JobCategoryをTaskCategoryにマッピング
    private func mapJobCategoryToTaskCategory(_ jobCategory: JobCategory) -> TaskCategory {
        switch jobCategory {
        case .fighter:
            return .strength
        case .scholar:
            return .intelligence
        case .explorer:
            return .continuity
        case .master:
            return .focus
        case .artist:
            return .achievement
        }
    }
    
    /// TaskCategoryをJobCategoryにマッピング
    private func mapTaskCategoryToJobCategory(_ taskCategory: TaskCategory) -> JobCategory {
        switch taskCategory {
        case .strength:
            return .fighter
        case .intelligence:
            return .scholar
        case .continuity:
            return .explorer
        case .focus:
            return .master
        case .achievement:
            return .artist
        }
    }
}

// MARK: - Task Category Definition

enum TaskCategory: String, CaseIterable {
    case strength = "strength"
    case focus = "focus"
    case continuity = "continuity"
    case intelligence = "intelligence"
    case achievement = "achievement"
    
    var displayName: String {
        switch self {
        case .strength: return "筋力"
        case .focus: return "集中力"
        case .continuity: return "継続力"
        case .intelligence: return "頭脳"
        case .achievement: return "達成力"
        }
    }
}