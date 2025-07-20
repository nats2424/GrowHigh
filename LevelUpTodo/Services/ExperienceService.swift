import Foundation
import CoreData

class ExperienceService {
    static let shared = ExperienceService()
    
    private init() {}
    
    // MARK: - Experience Calculation
    
    /// レベルアップに必要な経験値を計算
    func experienceRequiredForLevel(_ level: Int) -> Int {
        return level * 100  // レベル1=100EXP, レベル2=200EXP...
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
    
    /// 現在の経験値から適切なレベルを計算
    func calculateLevel(from experience: Int) -> Int {
        var level = 1
        var totalExpRequired = 0
        
        while totalExpRequired < experience {
            totalExpRequired += experienceRequiredForLevel(level)
            if totalExpRequired <= experience {
                level += 1
            }
        }
        
        return max(1, level - 1)
    }
    
    /// 次のレベルまでの残り経験値を計算
    func experienceToNextLevel(currentExp: Int, currentLevel: Int) -> Int {
        let totalExpForCurrentLevel = totalExperienceRequiredForLevel(currentLevel)
        let totalExpForNextLevel = totalExperienceRequiredForLevel(currentLevel + 1)
        
        return totalExpForNextLevel - currentExp
    }
    
    /// 指定レベルまでの累積経験値を計算
    func totalExperienceRequiredForLevel(_ level: Int) -> Int {
        var total = 0
        for i in 1..<level {
            total += experienceRequiredForLevel(i)
        }
        return total
    }
    
    // MARK: - Job/Avatar Management
    
    /// レベルに応じて解放されるジョブを決定
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
    
    /// レベルに応じた推奨アバターを取得
    func recommendedAvatarForLevel(_ level: Int, gender: String) -> String {
        let availableJobs = availableJobsForLevel(level)
        
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
    
    /// レベルアップ時の処理
    private func handleLevelUp(from oldLevel: Int, to newLevel: Int, using service: ExperienceService) {
        let reward = service.levelUpReward(newLevel: newLevel)
        
        // 新しいジョブが解放された場合の処理
        if !reward.unlockedJobs.isEmpty {
            // 性別に応じて適切なアバターを自動設定
            let gender = UserDefaults.standard.string(forKey: "userGender") ?? "male"
            let recommendedAvatar = service.recommendedAvatarForLevel(newLevel, gender: gender)
            
            if reward.unlockedJobs.contains(recommendedAvatar) {
                self.currentAvatarType = recommendedAvatar
            }
        }
        
        // レベルアップ通知（実装時にNotificationServiceに委譲）
        NotificationCenter.default.post(
            name: NSNotification.Name("UserLeveledUp"),
            object: nil,
            userInfo: ["oldLevel": oldLevel, "newLevel": newLevel, "reward": reward]
        )
    }
    
    /// 次のレベルまでの進捗率 (0.0 - 1.0)
    func progressToNextLevel(using service: ExperienceService = .shared) -> Double {
        let currentLevel = Int(self.level)
        let currentExp = Int(self.experience)
        
        let expForCurrentLevel = service.totalExperienceRequiredForLevel(currentLevel)
        let expForNextLevel = service.totalExperienceRequiredForLevel(currentLevel + 1)
        let expInCurrentLevel = currentExp - expForCurrentLevel
        let expRequiredForNextLevel = expForNextLevel - expForCurrentLevel
        
        return Double(expInCurrentLevel) / Double(expRequiredForNextLevel)
    }
}