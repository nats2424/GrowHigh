import Foundation
import CoreData
import RealmSwift

/// テストデータ改竄とリセット機能を提供するマネージャー
class TestDataManager {
    static let shared = TestDataManager()
    
    private init() {}
    
    /// 完全なデータリセット（新規ユーザー状態に戻す）
    func resetToNewUserState() {
        print("🧪 テストデータ改竄開始: 新規ユーザー状態にリセット中...")
        
        // 1. UserDefaultsのチュートリアル状態をリセット
        resetUserDefaults()
        
        // 2. Core Dataをリセット
        resetCoreData()
        
        // 3. Realmデータベースをリセット
        resetRealmData()
        
        // 4. アプリ状態をリフレッシュ
        refreshAppState()
        
        print("✅ テストデータ改竄完了: 新規ユーザー状態にリセットしました")
    }
    
    /// UserDefaultsの全てのチュートリアル関連フラグをリセット
    private func resetUserDefaults() {
        let defaults = UserDefaults.standard
        
        // チュートリアル関連フラグ
        defaults.removeObject(forKey: "hasSeenTutorial")
        defaults.removeObject(forKey: "hasCompletedGenderSelection")
        defaults.removeObject(forKey: "hasCompletedTaskTutorial") 
        defaults.removeObject(forKey: "hasCompletedStatsTutorial")
        
        // ユーザー関連データ
        defaults.removeObject(forKey: "selectedGender")
        defaults.removeObject(forKey: "userGender")
        defaults.removeObject(forKey: "userName")
        
        // その他の設定
        defaults.removeObject(forKey: "isFirstLaunch")
        defaults.removeObject(forKey: "lastResetDate")
        
        // 同期
        defaults.synchronize()
        
        print("🗑️ UserDefaults クリア完了")
    }
    
    /// Core Dataの全データを削除
    private func resetCoreData() {
        let context = PersistenceController.shared.container.viewContext
        
        do {
            // Userエンティティの全データを削除
            let userRequest: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()
            let userDeleteRequest = NSBatchDeleteRequest(fetchRequest: userRequest)
            try context.execute(userDeleteRequest)
            
            // TodoItemエンティティの全データを削除
            let todoRequest: NSFetchRequest<NSFetchRequestResult> = TodoItem.fetchRequest()
            let todoDeleteRequest = NSBatchDeleteRequest(fetchRequest: todoRequest)
            try context.execute(todoDeleteRequest)
            
            // Avatarエンティティの全データを削除
            let avatarRequest: NSFetchRequest<NSFetchRequestResult> = Avatar.fetchRequest()
            let avatarDeleteRequest = NSBatchDeleteRequest(fetchRequest: avatarRequest)
            try context.execute(avatarDeleteRequest)
            
            // 変更を保存
            try context.save()
            
            // コンテキストをリフレッシュ
            context.refreshAllObjects()
            
            print("🗑️ Core Data クリア完了")
            
        } catch {
            print("❌ Core Data クリアエラー: \(error)")
        }
    }
    
    /// Realmデータベースの全データを削除
    private func resetRealmData() {
        do {
            let realm = try Realm()
            
            try realm.write {
                // 全てのオブジェクトを削除
                realm.deleteAll()
            }
            
            print("🗑️ Realm データベース クリア完了")
            
        } catch {
            print("❌ Realm データベース クリアエラー: \(error)")
        }
    }
    
    /// アプリケーション状態をリフレッシュ
    private func refreshAppState() {
        // TutorialManagerのリセット
        DispatchQueue.main.async {
            TutorialManager.shared.checkInitialState()
        }
        
        // 通知を送信してUIをリフレッシュ
        NotificationCenter.default.post(name: NSNotification.Name("TestDataReset"), object: nil)
        
        print("🔄 アプリ状態リフレッシュ完了")
    }
    
    /// チュートリアル状態のみリセット（データは保持）
    func resetTutorialStateOnly() {
        let defaults = UserDefaults.standard
        
        // チュートリアル関連フラグのみクリア
        defaults.removeObject(forKey: "hasSeenTutorial")
        defaults.removeObject(forKey: "hasCompletedGenderSelection")
        defaults.removeObject(forKey: "hasCompletedTaskTutorial")
        defaults.removeObject(forKey: "hasCompletedStatsTutorial")
        
        defaults.synchronize()
        
        // TutorialManagerをリセット
        DispatchQueue.main.async {
            TutorialManager.shared.checkInitialState()
        }
        
        print("🎯 チュートリアル状態のみリセット完了")
    }
    
    /// テストデータの作成（開発用）
    func createTestData() {
        print("🧪 テストデータ作成中...")
        
        let context = PersistenceController.shared.container.viewContext
        
        // テストユーザーを作成
        let testUser = User(context: context)
        testUser.name = "テストユーザー"
        testUser.level = 5
        testUser.experience = 42
        testUser.totalExperience = 142
        testUser.experienceToNextLevel = 8
        testUser.strength = 10
        testUser.intelligence = 8
        testUser.focus = 6
        testUser.endurance = 7
        testUser.creativity = 5
        testUser.currentAvatarType = "warrior_male"
        testUser.createdAt = Date()
        
        // テストタスクを作成
        for i in 1...3 {
            let task = TodoItem(context: context)
            task.title = "テストタスク \(i)"
            task.isCompleted = i == 1 // 最初のタスクは完了済み
            task.experienceReward = Int32.random(in: 10...30)
            task.priority = Int32.random(in: 1...3)
            task.taskType = ["strength", "intelligence", "focus"].randomElement() ?? "strength"
            task.createdAt = Date()
            task.user = testUser
            
            if task.isCompleted {
                task.completedAt = Date()
            }
        }
        
        do {
            try context.save()
            print("✅ テストデータ作成完了")
        } catch {
            print("❌ テストデータ作成エラー: \(error)")
        }
    }
    
    /// デバッグ用: 現在のデータ状態を表示
    func printCurrentDataState() {
        print("📊 現在のデータ状態:")
        
        // UserDefaults状態
        let defaults = UserDefaults.standard
        let tutorialFlags = [
            "hasSeenTutorial": defaults.bool(forKey: "hasSeenTutorial"),
            "hasCompletedGenderSelection": defaults.bool(forKey: "hasCompletedGenderSelection"),
            "hasCompletedTaskTutorial": defaults.bool(forKey: "hasCompletedTaskTutorial"),
            "hasCompletedStatsTutorial": defaults.bool(forKey: "hasCompletedStatsTutorial")
        ]
        
        print("UserDefaults: \(tutorialFlags)")
        
        // Core Data状態
        let context = PersistenceController.shared.container.viewContext
        do {
            let userCount = try context.count(for: User.fetchRequest())
            let todoCount = try context.count(for: TodoItem.fetchRequest())
            print("Core Data: Users=\(userCount), Todos=\(todoCount)")
        } catch {
            print("Core Data確認エラー: \(error)")
        }
        
        // Realm状態
        do {
            let realm = try Realm()
            let realmUserCount = realm.objects(RealmUser.self).count
            let realmTaskCount = realm.objects(RealmTask.self).count
            print("Realm: Users=\(realmUserCount), Tasks=\(realmTaskCount)")
        } catch {
            print("Realm確認エラー: \(error)")
        }
    }
}

// MARK: - 設定画面用のテストデータコントロール

extension TestDataManager {
    /// 設定画面から呼び出されるリセットメニュー
    func showResetOptions() -> [TestDataResetOption] {
        return [
            TestDataResetOption(
                title: "🔄 新規ユーザー状態にリセット", 
                description: "全てのデータとチュートリアル状態をリセットします", 
                action: { self.resetToNewUserState() }
            ),
            TestDataResetOption(
                title: "🎯 チュートリアルのみリセット", 
                description: "チュートリアル状態のみリセット（データは保持）", 
                action: { self.resetTutorialStateOnly() }
            ),
            TestDataResetOption(
                title: "🧪 テストデータ作成", 
                description: "開発用のテストデータを作成します", 
                action: { self.createTestData() }
            ),
            TestDataResetOption(
                title: "📊 データ状態確認", 
                description: "現在のデータベース状態をコンソールに出力", 
                action: { self.printCurrentDataState() }
            )
        ]
    }
}

// MARK: - Supporting Types

struct TestDataResetOption {
    let title: String
    let description: String
    let action: () -> Void
}