import Foundation
import RealmSwift

// MARK: - Realm Database Manager
class RealmDatabaseManager {
    
    // MARK: - Singleton
    static let shared = RealmDatabaseManager()
    
    // MARK: - Properties
    private var realm: Realm?
    
    // MARK: - Schema Version Configuration
    private let currentSchemaVersion: UInt64 = 2  // バージョンアップ
    private let databaseName = "LevelUpTodo.realm"
    
    // MARK: - Initialization
    private init() {
        setupRealm()
    }
    
    // MARK: - Realm Setup
    
    /// Realmデータベースのセットアップと初期化
    private func setupRealm() {
        do {
            let config = createRealmConfiguration()
            Realm.Configuration.defaultConfiguration = config
            realm = try Realm(configuration: config)
            
            print("✅ Realm Database initialized successfully")
            print("📍 Database location: \(realm?.configuration.fileURL?.absoluteString ?? "Unknown")")
            
        } catch {
            fatalError("❌ Failed to initialize Realm: \(error)")
        }
    }
    
    /// Realm設定の作成
    private func createRealmConfiguration() -> Realm.Configuration {
        let config = Realm.Configuration(
            schemaVersion: currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                self.performMigration(migration: migration, oldSchemaVersion: oldSchemaVersion)
            },
            deleteRealmIfMigrationNeeded: true // 開発中はtrueに設定してスキーマリセット
        )
        
        return config
    }
    
    // MARK: - Migration Handling
    
    /// スキーママイグレーション処理
    private func performMigration(migration: Migration, oldSchemaVersion: UInt64) {
        print("🔄 Starting migration from schema version \(oldSchemaVersion) to \(currentSchemaVersion)")
        
        // バージョン0から1への移行例
        if oldSchemaVersion < 1 {
            // 新しいプロパティの追加などを行う
            migration.enumerateObjects(ofType: RealmUser.className()) { oldObject, newObject in
                // 例: 新しいプロパティのデフォルト値を設定
                newObject?["endurance"] = 0
                newObject?["lastTaskCompletionDate"] = nil
            }
        }
        
        // 今後のバージョン追加時の例:
        // if oldSchemaVersion < 2 {
        //     // バージョン1から2への移行処理
        // }
        
        print("✅ Migration completed successfully")
    }
    
    // MARK: - Realm Instance Access
    
    /// 現在のRealmインスタンスを取得
    func getRealm() -> Realm {
        guard let realm = realm else {
            fatalError("❌ Realm not initialized")
        }
        return realm
    }
    
    // MARK: - Transaction Helper Methods
    
    /// 安全なwrite操作を実行
    func safeWrite(_ block: () throws -> Void) throws {
        let realm = getRealm()
        
        if realm.isInWriteTransaction {
            // 既にwrite transaction内にいる場合は直接実行
            try block()
        } else {
            // 新しいwrite transactionを開始
            try realm.write {
                try block()
            }
        }
    }
    
    /// 非同期でwrite操作を実行
    func asyncWrite(_ block: @escaping () throws -> Void, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.safeWrite(block)
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Generic CRUD Operations
    
    /// オブジェクトを保存または更新
    func save<T: Object>(_ object: T, update: Realm.UpdatePolicy = .modified) throws {
        try safeWrite {
            getRealm().add(object, update: update)
        }
    }
    
    /// オブジェクトのリストを保存または更新
    func save<T: Object>(_ objects: [T], update: Realm.UpdatePolicy = .modified) throws {
        try safeWrite {
            getRealm().add(objects, update: update)
        }
    }
    
    /// プライマリキーでオブジェクトを取得
    func fetch<T: Object>(_ type: T.Type, primaryKey: Any) -> T? {
        return getRealm().object(ofType: type, forPrimaryKey: primaryKey)
    }
    
    /// 全オブジェクトを取得
    func fetchAll<T: Object>(_ type: T.Type) -> Results<T> {
        return getRealm().objects(type)
    }
    
    /// 条件付きでオブジェクトを取得
    func fetch<T: Object>(_ type: T.Type, predicate: NSPredicate) -> Results<T> {
        return getRealm().objects(type).filter(predicate)
    }
    
    /// オブジェクトを削除
    func delete<T: Object>(_ object: T) throws {
        try safeWrite {
            getRealm().delete(object)
        }
    }
    
    /// オブジェクトのリストを削除
    func delete<T: Object>(_ objects: Results<T>) throws {
        try safeWrite {
            getRealm().delete(objects)
        }
    }
    
    /// 指定タイプのオブジェクトを全削除
    func deleteAll<T: Object>(_ type: T.Type) throws {
        try safeWrite {
            let objects = getRealm().objects(type)
            getRealm().delete(objects)
        }
    }
    
    // MARK: - Database Utilities
    
    /// データベースファイルサイズを取得
    func getDatabaseFileSize() -> String {
        guard let fileURL = realm?.configuration.fileURL else {
            return "Unknown"
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useMB, .useKB]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: fileSize)
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        
        return "Unknown"
    }
    
    /// データベース統計情報を取得
    func getDatabaseStats() -> [String: Any] {
        let realm = getRealm()
        
        return [
            "schemaVersion": currentSchemaVersion,
            "fileSize": getDatabaseFileSize(),
            "userCount": realm.objects(RealmUser.self).count,
            "taskCount": realm.objects(RealmTask.self).count,
            "avatarCount": realm.objects(RealmAvatar.self).count,
            "location": realm.configuration.fileURL?.absoluteString ?? "Unknown"
        ]
    }
    
    /// 開発用: データベースをリセット
    func resetDatabase() throws {
        print("⚠️ Resetting database...")
        
        try safeWrite {
            getRealm().deleteAll()
        }
        
        print("✅ Database reset completed")
    }
    
    // MARK: - Error Types
    enum DatabaseError: Error {
        case initializationFailed(String)
        case operationFailed(String)
        case objectNotFound(String)
        
        var localizedDescription: String {
            switch self {
            case .initializationFailed(let message):
                return "Database initialization failed: \(message)"
            case .operationFailed(let message):
                return "Database operation failed: \(message)"
            case .objectNotFound(let message):
                return "Object not found: \(message)"
            }
        }
    }
}