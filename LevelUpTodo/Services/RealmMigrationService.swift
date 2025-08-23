import Foundation
import RealmSwift
import CoreData

// MARK: - Realm Migration Service
class RealmMigrationService {
    
    // MARK: - Singleton
    static let shared = RealmMigrationService()
    
    // MARK: - Properties
    private let databaseManager = RealmDatabaseManager.shared
    
    // MARK: - Schema Versions
    enum SchemaVersion: UInt64, CaseIterable {
        case initial = 0
        case addedStatusFields = 1
        case addedTaskTypes = 2
        case addedEnduranceTracking = 3
        
        var description: String {
            switch self {
            case .initial:
                return "Initial schema with basic User and Task models"
            case .addedStatusFields:
                return "Added RPG status fields (strength, focus, intelligence, creativity, endurance)"
            case .addedTaskTypes:
                return "Added task type system and status growth tracking"
            case .addedEnduranceTracking:
                return "Added last task completion date for endurance tracking"
            }
        }
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Migration Management
    
    /// すべてのマイグレーション処理を定義
    func performMigration(migration: Migration, oldSchemaVersion: UInt64) {
        print("🔄 Starting Realm migration from version \(oldSchemaVersion)")
        
        // バージョン0→1: ステータスフィールドを追加
        if oldSchemaVersion < SchemaVersion.addedStatusFields.rawValue {
            migrateToVersion1(migration: migration)
        }
        
        // バージョン1→2: タスクタイプシステムを追加
        if oldSchemaVersion < SchemaVersion.addedTaskTypes.rawValue {
            migrateToVersion2(migration: migration)
        }
        
        // バージョン2→3: 継続力追跡機能を追加
        if oldSchemaVersion < SchemaVersion.addedEnduranceTracking.rawValue {
            migrateToVersion3(migration: migration)
        }
        
        print("✅ Realm migration completed successfully")
    }
    
    // MARK: - Individual Migration Methods
    
    /// バージョン0→1: RPGステータスフィールドを追加
    private func migrateToVersion1(migration: Migration) {
        print("📝 Migrating to version 1: Adding RPG status fields")
        
        migration.enumerateObjects(ofType: RealmUser.className()) { oldObject, newObject in
            // 新しいステータスフィールドにデフォルト値を設定
            newObject?["strength"] = 0
            newObject?["focus"] = 0
            newObject?["intelligence"] = 0
            newObject?["creativity"] = 0
            newObject?["endurance"] = 0
            
            print("  ✓ User migrated: \(oldObject?["name"] ?? "Unknown")")
        }
    }
    
    /// バージョン1→2: タスクタイプシステムを追加
    private func migrateToVersion2(migration: Migration) {
        print("📝 Migrating to version 2: Adding task type system")
        
        migration.enumerateObjects(ofType: RealmTask.className()) { oldObject, newObject in
            // デフォルトタスクタイプを設定
            newObject?["taskType"] = TaskType.strength.rawValue
            
            print("  ✓ Task migrated: \(oldObject?["title"] ?? "Unknown")")
        }
    }
    
    /// バージョン2→3: 継続力追跡機能を追加
    private func migrateToVersion3(migration: Migration) {
        print("📝 Migrating to version 3: Adding endurance tracking")
        
        migration.enumerateObjects(ofType: RealmUser.className()) { oldObject, newObject in
            // 最後のタスク完了日を初期化
            newObject?["lastTaskCompletionDate"] = nil
            
            print("  ✓ User endurance tracking enabled: \(oldObject?["name"] ?? "Unknown")")
        }
    }
    
    // MARK: - Core Data to Realm Migration
    
    /// Core DataからRealmへのデータ移行
    func migrateCoreDataToRealm(from context: NSManagedObjectContext) throws {
        print("🔄 Starting Core Data to Realm migration")
        
        // Core Dataからユーザーデータを取得
        let coreDataUsers = try fetchCoreDataUsers(from: context)
        let coreDataTasks = try fetchCoreDataTasks(from: context)
        
        // Realmにデータを移行
        try migrateCoreDataUsers(coreDataUsers)
        try migrateCoreDataTasks(coreDataTasks)
        
        print("✅ Core Data to Realm migration completed")
        print("  📊 Migrated \(coreDataUsers.count) users and \(coreDataTasks.count) tasks")
    }
    
    /// Core DataからUser情報を取得
    private func fetchCoreDataUsers(from context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "User")
        return try context.fetch(request)
    }
    
    /// Core DataからTask情報を取得
    private func fetchCoreDataTasks(from context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "TodoItem")
        return try context.fetch(request)
    }
    
    /// Core DataのUserをRealmに移行
    private func migrateCoreDataUsers(_ coreDataUsers: [NSManagedObject]) throws {
        for coreDataUser in coreDataUsers {
            let realmUser = RealmUser()
            
            // 基本情報の移行（IDはUUID自動生成される）
            realmUser.name = coreDataUser.value(forKey: "name") as? String ?? "冒険者"
            realmUser.level = coreDataUser.value(forKey: "level") as? Int ?? 1
            realmUser.experience = coreDataUser.value(forKey: "experience") as? Int ?? 0
            realmUser.totalExperience = coreDataUser.value(forKey: "totalExperience") as? Int ?? 0
            
            // RPGステータスの移行（存在しない場合はデフォルト値）
            realmUser.strength = coreDataUser.value(forKey: "strength") as? Int ?? 0
            realmUser.focus = coreDataUser.value(forKey: "focus") as? Int ?? 0
            realmUser.intelligence = coreDataUser.value(forKey: "intelligence") as? Int ?? 0
            realmUser.creativity = coreDataUser.value(forKey: "creativity") as? Int ?? 0
            realmUser.endurance = coreDataUser.value(forKey: "endurance") as? Int ?? 0
            
            // アバター情報の移行
            realmUser.currentAvatarType = coreDataUser.value(forKey: "currentAvatarType") as? String
            
            // 日付情報の移行
            realmUser.createdAt = coreDataUser.value(forKey: "createdAt") as? Date ?? Date()
            realmUser.lastTaskCompletionDate = coreDataUser.value(forKey: "lastTaskCompletionDate") as? Date
            
            // アバター情報を設定（初期アバターのみ）
            setupMigratedUserAvatars(for: realmUser)
            
            try databaseManager.save(realmUser)
            print("  ✓ User migrated: \(realmUser.name)")
        }
    }
    
    /// Core DataのTaskをRealmに移行
    private func migrateCoreDataTasks(_ coreDataTasks: [NSManagedObject]) throws {
        // 移行されたRealmユーザーを取得
        let realmUsers = databaseManager.fetchAll(RealmUser.self)
        guard let primaryUser = realmUsers.first else {
            throw MigrationError.noRealmUserFound
        }
        
        for coreDataTask in coreDataTasks {
            let realmTask = RealmTask()
            
            // 基本情報の移行（IDはUUID自動生成される）
            realmTask.title = coreDataTask.value(forKey: "title") as? String ?? "無題のタスク"
            realmTask.taskDescription = nil // Core Dataにdescriptionフィールドがない場合
            realmTask.experienceReward = coreDataTask.value(forKey: "experienceReward") as? Int ?? 10
            realmTask.priority = coreDataTask.value(forKey: "priority") as? Int ?? 1
            
            // タスクタイプの移行（存在しない場合はstrength）
            if let taskTypeString = coreDataTask.value(forKey: "taskType") as? String,
               TaskType(rawValue: taskTypeString) != nil {
                realmTask.taskType = taskTypeString
            } else {
                realmTask.taskType = TaskType.strength.rawValue
            }
            
            // 完了状況の移行
            realmTask.isCompleted = coreDataTask.value(forKey: "isCompleted") as? Bool ?? false
            
            // 日付情報の移行
            realmTask.createdAt = coreDataTask.value(forKey: "createdAt") as? Date ?? Date()
            realmTask.completedAt = coreDataTask.value(forKey: "completedAt") as? Date
            
            // ユーザーにタスクを関連付け
            try databaseManager.safeWrite {
                primaryUser.tasks.append(realmTask)
            }
            
            print("  ✓ Task migrated: \(realmTask.title)")
        }
    }
    
    /// 移行されたユーザーに初期アバターを設定
    private func setupMigratedUserAvatars(for user: RealmUser) {
        let initialAvatars = [
            createMigrationAvatar(type: "starter_male", name: "新米冒険者（男）", level: 1, unlocked: true),
            createMigrationAvatar(type: "starter_female", name: "新米冒険者（女）", level: 1, unlocked: true),
            createMigrationAvatar(type: "wizard_male", name: "魔法使い（男）", level: 11, unlocked: user.level >= 11),
            createMigrationAvatar(type: "wizard_female", name: "魔法使い（女）", level: 11, unlocked: user.level >= 11),
            createMigrationAvatar(type: "warrior_male", name: "戦士（男）", level: 11, unlocked: user.level >= 11),
            createMigrationAvatar(type: "warrior_female", name: "戦士（女）", level: 11, unlocked: user.level >= 11),
            createMigrationAvatar(type: "archmage_male", name: "大魔法使い（男）", level: 26, unlocked: user.level >= 26),
            createMigrationAvatar(type: "archmage_female", name: "大魔法使い（女）", level: 26, unlocked: user.level >= 26),
            createMigrationAvatar(type: "knight_male", name: "騎士（男）", level: 26, unlocked: user.level >= 26),
            createMigrationAvatar(type: "knight_female", name: "騎士（女）", level: 26, unlocked: user.level >= 26)
        ]
        
        user.unlockedAvatars.append(objectsIn: initialAvatars)
    }
    
    /// マイグレーション用アバターオブジェクトを作成
    private func createMigrationAvatar(type: String, name: String, level: Int, unlocked: Bool) -> RealmAvatar {
        let avatar = RealmAvatar()
        avatar.avatarType = type
        avatar.name = name
        avatar.imageURL = type
        avatar.requiredLevel = level
        avatar.isUnlocked = unlocked
        return avatar
    }
    
    // MARK: - Validation & Diagnostics
    
    /// データ整合性をチェック
    func validateDataIntegrity() -> ValidationResult {
        let realm = databaseManager.getRealm()
        var errors: [String] = []
        var warnings: [String] = []
        
        // ユーザーデータの検証
        let users = realm.objects(RealmUser.self)
        for user in users {
            if user.name.isEmpty {
                errors.append("User with empty name found: \(user.id)")
            }
            
            if user.level < 1 {
                errors.append("Invalid level for user \(user.name): \(user.level)")
            }
            
            if user.experience < 0 {
                errors.append("Negative experience for user \(user.name): \(user.experience)")
            }
            
            if user.tasks.isEmpty {
                warnings.append("User \(user.name) has no tasks")
            }
        }
        
        // タスクデータの検証
        let tasks = realm.objects(RealmTask.self)
        for task in tasks {
            if task.title.isEmpty {
                errors.append("Task with empty title found: \(task.id)")
            }
            
            if task.experienceReward < 0 {
                errors.append("Negative experience reward for task \(task.title): \(task.experienceReward)")
            }
            
            if task.priority < 1 || task.priority > 3 {
                errors.append("Invalid priority for task \(task.title): \(task.priority)")
            }
            
            if TaskType(rawValue: task.taskType) == nil {
                errors.append("Invalid task type for task \(task.title): \(task.taskType)")
            }
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            totalUsers: users.count,
            totalTasks: tasks.count,
            totalAvatars: realm.objects(RealmAvatar.self).count
        )
    }
    
    /// マイグレーション履歴を記録
    func recordMigrationHistory(from oldVersion: UInt64, to newVersion: UInt64) {
        let history = MigrationHistory(
            fromVersion: oldVersion,
            toVersion: newVersion,
            migratedAt: Date(),
            success: true
        )
        
        // UserDefaultsに履歴を保存
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(history) {
            let key = "migration_history_\(oldVersion)_to_\(newVersion)"
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    /// 保存されたマイグレーション履歴を取得
    func getMigrationHistory() -> [MigrationHistory] {
        var histories: [MigrationHistory] = []
        
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            if key.hasPrefix("migration_history_") {
                if let data = UserDefaults.standard.data(forKey: key) {
                    let decoder = JSONDecoder()
                    if let history = try? decoder.decode(MigrationHistory.self, from: data) {
                        histories.append(history)
                    }
                }
            }
        }
        
        return histories.sorted { $0.migratedAt > $1.migratedAt }
    }
}

// MARK: - Supporting Types

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
    let totalUsers: Int
    let totalTasks: Int
    let totalAvatars: Int
    
    var summary: String {
        var summary = """
        📊 Data Validation Summary:
        - Status: \(isValid ? "✅ Valid" : "❌ Invalid")
        - Users: \(totalUsers)
        - Tasks: \(totalTasks)
        - Avatars: \(totalAvatars)
        """
        
        if !errors.isEmpty {
            summary += "\n\n❌ Errors (\(errors.count)):\n"
            summary += errors.enumerated().map { "  \($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        }
        
        if !warnings.isEmpty {
            summary += "\n\n⚠️ Warnings (\(warnings.count)):\n"
            summary += warnings.enumerated().map { "  \($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        }
        
        return summary
    }
}

struct MigrationHistory: Codable {
    let fromVersion: UInt64
    let toVersion: UInt64
    let migratedAt: Date
    let success: Bool
}

// MARK: - Error Types
enum MigrationError: Error, LocalizedError {
    case coreDataContextNotAvailable
    case noRealmUserFound
    case migrationFailed(String)
    case validationFailed([String])
    
    var errorDescription: String? {
        switch self {
        case .coreDataContextNotAvailable:
            return "Core Data context is not available for migration"
        case .noRealmUserFound:
            return "No Realm user found for task migration"
        case .migrationFailed(let reason):
            return "Migration failed: \(reason)"
        case .validationFailed(let errors):
            return "Data validation failed with \(errors.count) errors"
        }
    }
}