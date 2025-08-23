import Foundation
import RealmSwift

// MARK: - Realm User Model
@objcMembers class RealmUser: Object {
    
    // MARK: - Properties
    
    /// ユーザーID（プライマリキー）- UUID自動生成
    dynamic var id: String = ""
    
    /// ユーザー名
    dynamic var name: String = ""
    
    /// 現在のレベル
    dynamic var level: Int = 1
    
    /// 現在の経験値
    dynamic var experience: Int = 0
    
    /// 累計経験値（レベル計算用）
    dynamic var totalExperience: Int = 0
    
    // MARK: - RPG Stats (5カテゴリ)
    
    /// 💪 筋力ステータス
    dynamic var strength: Int = 0
    
    /// 🧠 集中力ステータス  
    dynamic var focus: Int = 0
    
    /// 🔁 継続力ステータス
    dynamic var continuity: Int = 0
    
    /// 🧩 頭脳ステータス
    dynamic var intelligence: Int = 0
    
    /// 🎉 達成力ステータス
    dynamic var achievement: Int = 0
    
    // MARK: - Avatar & Appearance
    
    /// 現在のアバタータイプ
    dynamic var currentAvatarType: String? = nil
    
    // MARK: - Dates
    
    /// アカウント作成日
    dynamic var createdAt: Date = Date()
    
    /// 最後のタスク完了日（持続力成長判定用）
    dynamic var lastTaskCompletionDate: Date? = nil
    
    // MARK: - Relationships
    
    /// 所持タスクリスト
    let tasks = List<RealmTask>()
    
    /// 解放済みアバターリスト
    let unlockedAvatars = List<RealmAvatar>()
    
    // MARK: - Realm Configuration
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["level", "experience", "createdAt"]
    }
    
    /// Realmオブジェクト作成時に自動でUUIDを生成
    override func awakeFromInsert() {
        super.awakeFromInsert()
        if id.isEmpty {
            id = UUID().uuidString
        }
    }
    
    // MARK: - Computed Properties
    
    /// N³経験値システムでの次レベル必要経験値計算
    var experienceRequiredForNextLevel: Int {
        let nextLevel = level + 1
        return nextLevel * nextLevel * nextLevel
    }
    
    /// 現在レベルでの進捗率（0.0〜1.0）
    var progressToNextLevel: Double {
        let currentLevelExp = level * level * level
        let nextLevelExp = experienceRequiredForNextLevel
        let expInCurrentLevel = experience - currentLevelExp
        let expRequiredForNext = nextLevelExp - currentLevelExp
        
        guard expRequiredForNext > 0 else { return 1.0 }
        return max(0.0, min(1.0, Double(expInCurrentLevel) / Double(expRequiredForNext)))
    }
}

// MARK: - Realm Task Model
@objcMembers class RealmTask: Object {
    
    // MARK: - Properties
    
    /// タスクID（プライマリキー）- UUID自動生成
    dynamic var id: String = ""
    
    /// タスクタイトル
    dynamic var title: String = ""
    
    /// タスクの詳細説明
    dynamic var taskDescription: String? = nil
    
    /// 優先度（1: 低, 2: 中, 3: 高）
    dynamic var priority: Int = 1
    
    /// タスクカテゴリ（5種類の成長分野）
    dynamic var taskCategory: String = TaskCategory.strength.rawValue
    
    // MARK: - Task Registration Fields (4項目)
    
    /// ① ルーティンタスクかどうか
    dynamic var isRoutineTask: Bool = false
    
    /// ② 未経験なタスクかどうか
    dynamic var isUnexperiencedTask: Bool = false
    
    /// ③ 達成までに必要な時間（選択肢: 0.5, 1, 2, 3, 4以上）
    dynamic var requiredHours: Double = 1.0
    
    /// ④ 不安や緊張があるか
    dynamic var hasAnxiety: Bool = false
    
    /// 完了フラグ
    dynamic var isCompleted: Bool = false
    
    // MARK: - Dates
    
    /// 作成日時
    dynamic var createdAt: Date = Date()
    
    /// 完了日時
    dynamic var completedAt: Date? = nil
    
    /// 期限日
    dynamic var dueDate: Date? = nil
    
    // MARK: - Relationships
    
    /// 所有者ユーザー（逆リンク）
    let user = LinkingObjects(fromType: RealmUser.self, property: "tasks")
    
    // MARK: - Realm Configuration
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["isCompleted", "createdAt", "completedAt", "priority", "taskCategory"]
    }
    
    /// Realmオブジェクト作成時に自動でUUIDを生成
    override func awakeFromInsert() {
        super.awakeFromInsert()
        if id.isEmpty {
            id = UUID().uuidString
        }
    }
    
    // MARK: - Computed Properties
    
    /// タスクカテゴリのEnum値
    var taskCategoryEnum: TaskCategory? {
        return TaskCategory(rawValue: taskCategory)
    }
    
    /// 経験値を4つの入力項目から自動計算（読み取り専用）
    var experienceReward: Int {
        var baseExp = 10
        
        // ② 未経験なタスクの場合 +5 EXP
        if isUnexperiencedTask {
            baseExp += 5
        }
        
        // ③ 必要時間に応じてEXP追加
        switch requiredHours {
        case 0.5:
            baseExp += 5
        case 1.0:
            baseExp += 10
        case 2.0:
            baseExp += 20
        case 3.0:
            baseExp += 30
        case 4.0...:
            baseExp += 40
        default:
            baseExp += 10
        }
        
        // ④ 不安や緊張がある場合 +10 EXP
        if hasAnxiety {
            baseExp += 10
        }
        
        // ① ルーティンタスクの場合は半分
        if isRoutineTask {
            baseExp = Int(Double(baseExp) * 0.5)
        }
        
        return baseExp
    }
    
    /// 優先度の文字列表現
    var priorityText: String {
        switch priority {
        case 3: return "高"
        case 2: return "中"
        default: return "低"
        }
    }
    
    /// 期限切れかどうか
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return Date() > dueDate
    }
}

// MARK: - Realm Avatar Model
@objcMembers class RealmAvatar: Object {
    
    // MARK: - Properties
    
    /// アバターID（プライマリキー）- UUID自動生成
    dynamic var id: String = ""
    
    /// アバタータイプ（識別子）
    dynamic var avatarType: String = ""
    
    /// アバター名
    dynamic var name: String = ""
    
    /// 画像URL（ローカルアセット名）
    dynamic var imageURL: String? = nil
    
    /// 解放必要レベル
    dynamic var requiredLevel: Int = 1
    
    /// 解放済みフラグ
    dynamic var isUnlocked: Bool = false
    
    // MARK: - Relationships
    
    /// 所有者ユーザー（逆リンク）
    let user = LinkingObjects(fromType: RealmUser.self, property: "unlockedAvatars")
    
    // MARK: - Realm Configuration
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["avatarType", "requiredLevel", "isUnlocked"]
    }
    
    /// Realmオブジェクト作成時に自動でUUIDを生成
    override func awakeFromInsert() {
        super.awakeFromInsert()
        if id.isEmpty {
            id = UUID().uuidString
        }
    }
}

// MARK: - Task Category Enum (5カテゴリ)
enum TaskCategory: String, CaseIterable {
    case strength = "strength"        // 💪 筋力
    case focus = "focus"              // 🧠 集中力  
    case continuity = "continuity"    // 🔁 継続力
    case intelligence = "intelligence" // 🧩 頭脳
    case achievement = "achievement"   // 🎉 達成力
    
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
        case .achievement:
            return "達成力"
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
        case .achievement:
            return "🎉"
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
        case .achievement:
            return "orange"
        }
    }
}

// MARK: - Task Time Options
enum TaskTimeOption: Double, CaseIterable {
    case halfHour = 0.5      // 0.5時間
    case oneHour = 1.0       // 1時間
    case twoHours = 2.0      // 2時間
    case threeHours = 3.0    // 3時間
    case fourPlusHours = 4.0 // 4時間以上
    
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

// MARK: - Achievement Type
enum AchievementType: String {
    case firstTask = "first_task"
    case tenTasks = "ten_tasks"
    case weekStreak = "week_streak"
    case monthStreak = "month_streak"
    
    var experienceBonus: Int {
        switch self {
        case .firstTask: return 25
        case .tenTasks: return 50
        case .weekStreak: return 30
        case .monthStreak: return 100
        }
    }
}