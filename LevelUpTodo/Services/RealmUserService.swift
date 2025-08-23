import Foundation
import RealmSwift

// MARK: - Realm User Service
class RealmUserService {
    
    // MARK: - Singleton
    static let shared = RealmUserService()
    
    // MARK: - Properties
    private let databaseManager = RealmDatabaseManager.shared
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - User CRUD Operations
    
    /// 新しいユーザーを作成（IDはUUID自動生成）
    func createUser(name: String = "冒険者", avatarType: String? = nil) throws -> RealmUser {
        let user = RealmUser()
        user.name = name
        user.currentAvatarType = avatarType ?? "starter_male"
        user.createdAt = Date()
        
        // 初期アバターを設定
        setupInitialAvatars(for: user)
        
        try databaseManager.save(user)
        
        print("✅ User created successfully: \(user.name) (UUID: \(user.id))")
        return user
    }
    
    /// プライマリユーザーを取得（通常は最初のユーザー）
    func getPrimaryUser() -> RealmUser? {
        let users = databaseManager.fetchAll(RealmUser.self)
        return users.first
    }
    
    /// ユーザーを取得または新規作成
    func getOrCreateUser(name: String = "冒険者") -> RealmUser {
        if let existingUser = getPrimaryUser() {
            return existingUser
        }
        
        do {
            return try createUser(name: name)
        } catch {
            fatalError("Failed to create user: \(error)")
        }
    }
    
    /// 指定IDのユーザーを取得
    func getUser(byId id: String) -> RealmUser? {
        return databaseManager.fetch(RealmUser.self, primaryKey: id)
    }
    
    /// 全ユーザーを取得
    func getAllUsers() -> Results<RealmUser> {
        return databaseManager.fetchAll(RealmUser.self)
    }
    
    /// ユーザー情報を更新
    func updateUser(_ user: RealmUser, name: String? = nil, avatarType: String? = nil) throws {
        try databaseManager.safeWrite {
            if let newName = name {
                user.name = newName
            }
            if let newAvatarType = avatarType {
                user.currentAvatarType = newAvatarType
            }
        }
        
        print("✅ User updated successfully: \(user.name)")
    }
    
    /// ユーザーを削除
    func deleteUser(_ user: RealmUser) throws {
        try databaseManager.delete(user)
        print("✅ User deleted successfully")
    }
    
    // MARK: - Experience & Level Management
    
    /// 経験値を追加してレベルアップチェック
    func addExperience(to user: RealmUser, amount: Int) throws {
        let oldLevel = user.level
        
        try databaseManager.safeWrite {
            user.experience += amount
            user.totalExperience += amount
            
            // N³システムでレベル計算
            let newLevel = calculateLevel(from: user.experience)
            user.level = newLevel
        }
        
        // レベルアップチェック
        if user.level > oldLevel {
            try handleLevelUp(user: user, from: oldLevel, to: user.level)
        }
        
        print("💫 Experience added: +\(amount) EXP (Total: \(user.experience))")
    }
    
    /// 経験値からレベルを計算（N³システム）
    private func calculateLevel(from experience: Int) -> Int {
        if experience <= 0 { return 1 }
        
        // 二分探索でレベルを効率的に計算
        var low = 1
        var high = 100 // 最大レベル想定
        
        while low <= high {
            let mid = (low + high) / 2
            let expRequired = mid * mid * mid
            let nextExpRequired = (mid + 1) * (mid + 1) * (mid + 1)
            
            if experience >= expRequired && experience < nextExpRequired {
                return mid
            } else if experience >= nextExpRequired {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        
        return max(1, low)
    }
    
    /// レベルアップ処理
    private func handleLevelUp(user: RealmUser, from oldLevel: Int, to newLevel: Int) throws {
        print("🎉 Level Up! \(oldLevel) → \(newLevel)")
        
        // アバター解放チェック
        try unlockAvatarsForLevel(user: user, level: newLevel)
        
        // 通知送信
        NotificationCenter.default.post(
            name: NSNotification.Name("UserLeveledUp"),
            object: nil,
            userInfo: [
                "userId": user.id,
                "oldLevel": oldLevel,
                "newLevel": newLevel
            ]
        )
    }
    
    // MARK: - Status Growth Management
    
    /// タスク完了時のステータス成長処理（新仕様）
    func completeTask(user: RealmUser, taskCategory: TaskCategory, experienceReward: Int) throws {
        try databaseManager.safeWrite {
            // 指定されたタスクカテゴリに応じてステータス成長（+1）
            switch taskCategory {
            case .strength:
                user.strength += 1
            case .focus:
                user.focus += 1
            case .continuity:
                user.continuity += 1
            case .intelligence:
                user.intelligence += 1
            case .achievement:
                user.achievement += 1
            }
        }
        
        // 経験値追加
        try addExperience(to: user, amount: experienceReward)
        
        print("📈 Status growth: \(taskCategory.displayName) +1")
    }
    
    /// ステータスをリセット（新仕様5カテゴリ）
    func resetStats(user: RealmUser) throws {
        try databaseManager.safeWrite {
            user.strength = 0
            user.focus = 0
            user.continuity = 0
            user.intelligence = 0
            user.achievement = 0
            user.lastTaskCompletionDate = nil
        }
        
        print("🔄 User stats reset")
    }
    
    // MARK: - Avatar Management
    
    /// 初期アバターの設定
    private func setupInitialAvatars(for user: RealmUser) {
        let initialAvatars = [
            createAvatar(type: "starter_male", name: "新米冒険者（男）", requiredLevel: 1, unlocked: true),
            createAvatar(type: "starter_female", name: "新米冒険者（女）", requiredLevel: 1, unlocked: true),
            createAvatar(type: "wizard_male", name: "魔法使い（男）", requiredLevel: 11, unlocked: false),
            createAvatar(type: "wizard_female", name: "魔法使い（女）", requiredLevel: 11, unlocked: false),
            createAvatar(type: "warrior_male", name: "戦士（男）", requiredLevel: 11, unlocked: false),
            createAvatar(type: "warrior_female", name: "戦士（女）", requiredLevel: 11, unlocked: false),
            createAvatar(type: "archmage_male", name: "大魔法使い（男）", requiredLevel: 26, unlocked: false),
            createAvatar(type: "archmage_female", name: "大魔法使い（女）", requiredLevel: 26, unlocked: false),
            createAvatar(type: "knight_male", name: "騎士（男）", requiredLevel: 26, unlocked: false),
            createAvatar(type: "knight_female", name: "騎士（女）", requiredLevel: 26, unlocked: false)
        ]
        
        user.unlockedAvatars.append(objectsIn: initialAvatars)
    }
    
    /// アバターオブジェクトを作成（IDはUUID自動生成）
    private func createAvatar(type: String, name: String, requiredLevel: Int, unlocked: Bool) -> RealmAvatar {
        let avatar = RealmAvatar()
        avatar.avatarType = type
        avatar.name = name
        avatar.imageURL = type
        avatar.requiredLevel = requiredLevel
        avatar.isUnlocked = unlocked
        return avatar
    }
    
    /// レベルに応じてアバターを解放
    private func unlockAvatarsForLevel(user: RealmUser, level: Int) throws {
        try databaseManager.safeWrite {
            let avatarsToUnlock = user.unlockedAvatars.filter { $0.requiredLevel <= level && !$0.isUnlocked }
            
            for avatar in avatarsToUnlock {
                avatar.isUnlocked = true
                print("🔓 Avatar unlocked: \(avatar.name)")
            }
        }
    }
    
    /// 解放済みアバターを取得
    func getUnlockedAvatars(for user: RealmUser) -> [RealmAvatar] {
        return Array(user.unlockedAvatars.filter { $0.isUnlocked })
    }
    
    /// アバターを変更
    func changeAvatar(user: RealmUser, to avatarType: String) throws {
        // アバターが解放済みかチェック
        let avatar = user.unlockedAvatars.first { $0.avatarType == avatarType && $0.isUnlocked }
        
        guard avatar != nil else {
            throw DatabaseError.operationFailed("Avatar not unlocked: \(avatarType)")
        }
        
        try databaseManager.safeWrite {
            user.currentAvatarType = avatarType
        }
        
        print("👤 Avatar changed to: \(avatarType)")
    }
    
    // MARK: - Statistics & Analytics
    
    /// ユーザー統計情報を取得（新仕様5カテゴリ）
    func getUserStats(for user: RealmUser) -> UserStats {
        let completedTasks = user.tasks.filter { $0.isCompleted }
        let totalTasks = user.tasks.count
        
        return UserStats(
            level: user.level,
            experience: user.experience,
            totalExperience: user.totalExperience,
            strength: user.strength,
            focus: user.focus,
            continuity: user.continuity,
            intelligence: user.intelligence,
            achievement: user.achievement,
            totalTasks: totalTasks,
            completedTasks: completedTasks.count,
            completionRate: totalTasks > 0 ? Double(completedTasks.count) / Double(totalTasks) : 0.0,
            experienceToNextLevel: user.experienceRequiredForNextLevel - user.experience,
            progressToNextLevel: user.progressToNextLevel,
            daysActive: calculateDaysActive(since: user.createdAt),
            unlockedAvatars: getUnlockedAvatars(for: user).count
        )
    }
    
    /// アクティブ日数を計算
    private func calculateDaysActive(since creationDate: Date) -> Int {
        let calendar = Calendar.current
        let daysBetween = calendar.dateComponents([.day], from: creationDate, to: Date()).day ?? 0
        return max(0, daysBetween)
    }
    
    // MARK: - Data Export & Backup
    
    /// ユーザーデータをJSONで出力
    func exportUserData(user: RealmUser) -> [String: Any] {
        return [
            "user": [
                "id": user.id,
                "name": user.name,
                "level": user.level,
                "experience": user.experience,
                "totalExperience": user.totalExperience,
                "strength": user.strength,
                "focus": user.focus,
                "intelligence": user.intelligence,
                "creativity": user.creativity,
                "endurance": user.endurance,
                "currentAvatarType": user.currentAvatarType ?? "",
                "createdAt": user.createdAt.timeIntervalSince1970,
                "lastTaskCompletionDate": user.lastTaskCompletionDate?.timeIntervalSince1970
            ],
            "tasks": user.tasks.map { task in
                [
                    "id": task.id,
                    "title": task.title,
                    "taskDescription": task.taskDescription ?? "",
                    "experienceReward": task.experienceReward,
                    "priority": task.priority,
                    "taskType": task.taskType,
                    "isCompleted": task.isCompleted,
                    "createdAt": task.createdAt.timeIntervalSince1970,
                    "completedAt": task.completedAt?.timeIntervalSince1970,
                    "dueDate": task.dueDate?.timeIntervalSince1970
                ]
            },
            "avatars": user.unlockedAvatars.map { avatar in
                [
                    "id": avatar.id,
                    "avatarType": avatar.avatarType,
                    "name": avatar.name,
                    "requiredLevel": avatar.requiredLevel,
                    "isUnlocked": avatar.isUnlocked
                ]
            }
        ]
    }
}

// MARK: - Supporting Types

struct UserStats {
    let level: Int
    let experience: Int
    let totalExperience: Int
    let strength: Int      // 💪 筋力
    let focus: Int         // 🧠 集中力
    let continuity: Int    // 🔁 継続力
    let intelligence: Int  // 🧩 頭脳
    let achievement: Int   // 🎉 達成力
    let totalTasks: Int
    let completedTasks: Int
    let completionRate: Double
    let experienceToNextLevel: Int
    let progressToNextLevel: Double
    let daysActive: Int
    let unlockedAvatars: Int
}

// MARK: - Error Types
enum DatabaseError: Error {
    case userNotFound
    case operationFailed(String)
    case avatarNotUnlocked
    
    var localizedDescription: String {
        switch self {
        case .userNotFound:
            return "User not found"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        case .avatarNotUnlocked:
            return "Avatar not unlocked"
        }
    }
}