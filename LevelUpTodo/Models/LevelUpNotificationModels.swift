import Foundation

// MARK: - Level-Up Statistics Models

struct LevelUpStatistics {
    let daysSinceFirstTask: Int
    let mostCompletedTaskType: TaskCategory
    let currentLevel: Int
    let jobTitle: String
    let previousJobTitle: String?
    let improvementMetric: String
    let consecutiveDays: Int
    let totalTasksCompleted: Int
    let completionRate: Double
    let averageCompletionTime: Double
    let jobCategory: JobCategory
    let isFirstJobAcquisition: Bool
    let isJobEvolution: Bool
    let isConsecutiveStreak: Bool
    let currentAvatarImage: String
    let previousAvatarImage: String?
}

// MARK: - Level-Up Message Template

struct LevelUpMessageTemplate {
    let id: String
    let title: String
    let message: String
    let nextActionPrompt: String
    let iconEmoji: String
    let backgroundColor: String
    let applicableCategories: [JobCategory]
    let minimumLevel: Int
    let maximumLevel: Int?
    
    static let templates: [LevelUpMessageTemplate] = [
        // 初回職業獲得（Lv5）
        LevelUpMessageTemplate(
            id: "first_job_acquisition",
            title: "継続の成果が出ました",
            message: "{daysSinceFirstTask}日間のタスク実行で「{jobTitle}」に到達。\n{mostCompletedTaskType}の継続が実を結びましたね。",
            nextActionPrompt: "次は{nextTargetLevel}レベルまで、同じペースで続けてみますか？",
            iconEmoji: "🎯",
            backgroundColor: "#4CAF50",
            applicableCategories: JobCategory.allCases,
            minimumLevel: 5,
            maximumLevel: 9
        ),
        
        // 職業進化（Lv10以上）
        LevelUpMessageTemplate(
            id: "job_evolution",
            title: "戦略的な取り組みが効いています",
            message: "{improvementMetric}で「{jobTitle}」に昇格しました。\n{mostCompletedTaskType}の優先順位付けが上達していますね。",
            nextActionPrompt: "この調子で難易度の高いタスクにも挑戦してみますか？",
            iconEmoji: "⚔️",
            backgroundColor: "#FF9800",
            applicableCategories: JobCategory.allCases,
            minimumLevel: 10,
            maximumLevel: nil
        ),
        
        // 継続系昇格
        LevelUpMessageTemplate(
            id: "consecutive_streak",
            title: "安定した成長パターンです",
            message: "{consecutiveDays}日連続でタスククリア。「{jobTitle}」に昇格しました。\n{mostCompletedTaskType}が習慣化できていますね。",
            nextActionPrompt: "次は{nextTargetLevel}レベル。新しいカテゴリも追加してみますか？",
            iconEmoji: "📈",
            backgroundColor: "#2196F3",
            applicableCategories: JobCategory.allCases,
            minimumLevel: 5,
            maximumLevel: nil
        ),
        
        // ファイター系（筋力）
        LevelUpMessageTemplate(
            id: "fighter_specific",
            title: "体力系タスクの攻略法が身についています",
            message: "{mostCompletedTaskType}を{consecutiveDays}日達成で「{jobTitle}」に昇格。\n短時間集中の取り組みが効果的でした。",
            nextActionPrompt: "次は持久力も鍛える長期タスクに挑戦しますか？",
            iconEmoji: "💪",
            backgroundColor: "#F44336",
            applicableCategories: [.fighter],
            minimumLevel: 5,
            maximumLevel: nil
        ),
        
        // スカラー系（知力）
        LevelUpMessageTemplate(
            id: "scholar_specific",
            title: "学習効率が大幅に向上しました",
            message: "{mostCompletedTaskType}の完了率が{completionRate}向上で「{jobTitle}」に到達。\n復習と実践の組み合わせが功を奏しています。",
            nextActionPrompt: "この方法で、新しい分野の学習も始めてみますか？",
            iconEmoji: "📚",
            backgroundColor: "#9C27B0",
            applicableCategories: [.scholar],
            minimumLevel: 5,
            maximumLevel: nil
        ),
        
        // エクスプローラー系（持久力）
        LevelUpMessageTemplate(
            id: "explorer_specific",
            title: "長期視点での取り組みが結果に",
            message: "{daysSinceFirstTask}日間のプロジェクト完走で「{jobTitle}」に昇格。\n定期的な振り返りで軌道修正したのが成功要因ですね。",
            nextActionPrompt: "次は複数プロジェクトの並行管理に挑戦しますか？",
            iconEmoji: "🗺️",
            backgroundColor: "#8BC34A",
            applicableCategories: [.explorer],
            minimumLevel: 5,
            maximumLevel: nil
        ),
        
        // マスター系（集中力）
        LevelUpMessageTemplate(
            id: "master_specific",
            title: "集中力の使い方がレベルアップしています",
            message: "{mostCompletedTaskType}の質が向上して「{jobTitle}」に到達。\n集中と休憩のサイクルが定着しました。",
            nextActionPrompt: "この集中法で、より創造的なタスクも試してみますか？",
            iconEmoji: "🔨",
            backgroundColor: "#607D8B",
            applicableCategories: [.master],
            minimumLevel: 5,
            maximumLevel: nil
        ),
        
        // アーティスト系（創造力）
        LevelUpMessageTemplate(
            id: "artist_specific",
            title: "アイデア創出のプロセスが確立されました",
            message: "{mostCompletedTaskType}で{totalTasksCompleted}個の成果を生んで「{jobTitle}」に昇格。\n試行錯誤→改善の流れが身についています。",
            nextActionPrompt: "この創造力で、他の分野にも応用してみますか？",
            iconEmoji: "🎨",
            backgroundColor: "#E91E63",
            applicableCategories: [.artist],
            minimumLevel: 5,
            maximumLevel: nil
        ),
        
        // 挫折後の復帰
        LevelUpMessageTemplate(
            id: "comeback_after_break",
            title: "再開のタイミングが絶妙でした",
            message: "ブランク後、{daysSinceFirstTask}日で前のペースに復帰。\n{improvementMetric}の判断力が向上していますね。",
            nextActionPrompt: "無理せず、今のリズムを大切に続けましょう。",
            iconEmoji: "🌱",
            backgroundColor: "#4CAF50",
            applicableCategories: JobCategory.allCases,
            minimumLevel: 5,
            maximumLevel: nil
        ),
        
        // 最高レベル到達（Lv100）
        LevelUpMessageTemplate(
            id: "maximum_level",
            title: "継続の力で頂点に到達",
            message: "{daysSinceFirstTask}日間の積み重ねで「{jobTitle}」に到達しました。\n{mostCompletedTaskType}での小さな改善が大きな成果を生みました。",
            nextActionPrompt: "この経験を、新しい挑戦にも活かしてみませんか？",
            iconEmoji: "👑",
            backgroundColor: "#FFD700",
            applicableCategories: JobCategory.allCases,
            minimumLevel: 100,
            maximumLevel: 100
        )
    ]
}

// MARK: - Level-Up Notification Configuration

struct LevelUpNotificationConfig {
    let enableConfetti: Bool
    let enableHapticFeedback: Bool
    let showProgressVisualization: Bool
    let autoCloseAfterSeconds: Double?
    
    static let `default` = LevelUpNotificationConfig(
        enableConfetti: true,
        enableHapticFeedback: true,
        showProgressVisualization: true,
        autoCloseAfterSeconds: nil
    )
}

// MARK: - Level-Up Action Options

enum LevelUpAction: String, CaseIterable {
    case setGoal = "set_goal"
    case saveRecord = "save_record"
    case continueJourney = "continue_journey"
    case shareAchievement = "share_achievement"
    
    var displayText: String {
        switch self {
        case .setGoal:
            return "目標を設定"
        case .saveRecord:
            return "記録を保存"
        case .continueJourney:
            return "続行"
        case .shareAchievement:
            return "成果を共有"
        }
    }
    
    var icon: String {
        switch self {
        case .setGoal:
            return "target"
        case .saveRecord:
            return "bookmark"
        case .continueJourney:
            return "arrow.right"
        case .shareAchievement:
            return "square.and.arrow.up"
        }
    }
}