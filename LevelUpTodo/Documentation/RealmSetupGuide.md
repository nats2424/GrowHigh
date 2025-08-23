# LevelUpTodo - Realm データ永続化ガイド

## 概要

LevelUpTodoアプリのRealmベースのデータ永続化システムです。RPG風タスク管理アプリのデータを効率的にローカル保存・管理します。

## 🚀 特徴

- **完全なCRUD操作**: ユーザーとタスクの作成・読取・更新・削除
- **RPGシステム対応**: レベル、経験値、5種類のステータス管理
- **タスクタイプシステム**: 4種類のタスクタイプ（筋力・集中力・頭脳・創造力）
- **高度なクエリ**: フィルタリング、検索、統計機能
- **マイグレーション対応**: スキーマバージョン管理とCore Data移行支援
- **エラーハンドリング**: 包括的なエラー処理とデータ検証
- **パフォーマンス最適化**: インデックス、バッチ処理、効率的なクエリ

## 📋 必要要件

- iOS 14.0+
- Xcode 12.0+
- Swift 5.0+
- RealmSwift 10.0+

## 📦 インストール

### 1. CocoaPods使用の場合

```ruby
# Podfile
target 'LevelUpTodo' do
  use_frameworks!
  pod 'RealmSwift', '~> 10.0'
end
```

```bash
pod install
```

### 2. Swift Package Manager使用の場合

Xcode > File > Add Package Dependencies から以下のURLを追加：
```
https://github.com/realm/realm-swift
```

### 3. 手動インストール

1. [Realm releases](https://github.com/realm/realm-swift/releases)から最新版をダウンロード
2. `RealmSwift.framework`をプロジェクトに追加

## 🏗 アーキテクチャ

### データモデル

```
RealmUser (ユーザー)
├── id: String (Primary Key)
├── name: String
├── level, experience: Int
├── strength, focus, intelligence, creativity, endurance: Int
├── currentAvatarType: String?
├── createdAt, lastTaskCompletionDate: Date?
├── tasks: List<RealmTask>
└── unlockedAvatars: List<RealmAvatar>

RealmTask (タスク)
├── id: String (Primary Key)
├── title, taskDescription: String
├── experienceReward, priority: Int
├── taskType: String (TaskType enum)
├── isCompleted: Bool
├── createdAt, completedAt, dueDate: Date?
└── user: LinkingObjects<RealmUser>

RealmAvatar (アバター)
├── id: String (Primary Key)
├── avatarType, name, imageURL: String
├── requiredLevel: Int
├── isUnlocked: Bool
└── user: LinkingObjects<RealmUser>
```

### サービス構成

```
RealmDatabaseManager (コア)
├── データベース初期化・設定
├── マイグレーション管理
├── 基本CRUD操作
└── トランザクション管理

RealmUserService (ユーザー管理)
├── ユーザーCRUD操作
├── 経験値・レベル管理
├── ステータス成長処理
└── アバター管理

RealmTaskService (タスク管理)
├── タスクCRUD操作
├── 高度なクエリ・フィルタリング
├── タスク完了処理
└── 統計情報生成

RealmMigrationService (マイグレーション)
├── スキーマバージョン管理
├── Core Dataからの移行
├── データ検証
└── マイグレーション履歴
```

## 🔧 基本的な使用方法

### 1. データベースの初期化

```swift
// アプリ起動時（AppDelegate or SceneDelegate）
import RealmSwift

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Realmは自動的に初期化されます（RealmDatabaseManager.shared）
    return true
}
```

### 2. ユーザー操作

```swift
import RealmSwift

class GameViewController: UIViewController {
    private let userService = RealmUserService.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUser()
    }
    
    private func setupUser() {
        // ユーザー取得または作成
        let user = userService.getOrCreateUser(name: "冒険者")
        
        // 経験値追加
        do {
            try userService.addExperience(to: user, amount: 50)
            print("Level: \(user.level), EXP: \(user.experience)")
        } catch {
            print("Error: \(error)")
        }
        
        // ステータス確認
        let stats = userService.getUserStats(for: user)
        print("Completion Rate: \(stats.completionRate)")
    }
}
```

### 3. タスク操作

```swift
class TaskViewController: UIViewController {
    private let taskService = RealmTaskService.shared
    private let userService = RealmUserService.shared
    
    private func createTask() {
        guard let user = userService.getPrimaryUser() else { return }
        
        do {
            let task = try taskService.createTask(
                for: user,
                title: "プログラミング学習",
                description: "Swift の基礎を学ぶ",
                experienceReward: 30,
                priority: 3,
                taskType: .intelligence,
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
            )
            
            print("Task created: \(task.title)")
        } catch {
            print("Error creating task: \(error)")
        }
    }
    
    private func completeTask(_ task: RealmTask) {
        do {
            try taskService.completeTask(task)
            print("Task completed! EXP gained: \(task.experienceReward)")
        } catch {
            print("Error completing task: \(error)")
        }
    }
    
    private func loadTasks() {
        guard let user = userService.getPrimaryUser() else { return }
        
        // 未完了タスク取得
        let pendingTasks = taskService.getPendingTasks(for: user)
        
        // 高優先度タスク取得
        let highPriorityTasks = taskService.getTasksByPriority(for: user, priority: 3)
        
        // 今日期限のタスク取得
        let todayTasks = taskService.getTodayTasks(for: user)
        
        print("Pending: \(pendingTasks.count), High Priority: \(highPriorityTasks.count), Today: \(todayTasks.count)")
    }
}
```

### 4. SwiftUI統合

```swift
import SwiftUI
import RealmSwift

struct TaskListView: View {
    @StateObject private var taskObserver = TaskObserver()
    private let userService = RealmUserService.shared
    private let taskService = RealmTaskService.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(taskObserver.tasks, id: \.id) { task in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .font(.headline)
                            Text("\(task.experienceReward) EXP")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { completeTask(task) }) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .gray)
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { addTask() }
                }
            }
        }
    }
    
    private func completeTask(_ task: RealmTask) {
        do {
            try taskService.completeTask(task)
        } catch {
            print("Error: \(error)")
        }
    }
    
    private func addTask() {
        guard let user = userService.getPrimaryUser() else { return }
        
        do {
            _ = try taskService.createTask(
                for: user,
                title: "New Task",
                experienceReward: 10,
                priority: 1,
                taskType: .strength
            )
        } catch {
            print("Error: \(error)")
        }
    }
}

// Realm Observer for SwiftUI
class TaskObserver: ObservableObject {
    @Published var tasks: [RealmTask] = []
    private var notificationToken: NotificationToken?
    
    init() {
        setupObserver()
    }
    
    deinit {
        notificationToken?.invalidate()
    }
    
    private func setupObserver() {
        guard let user = RealmUserService.shared.getPrimaryUser() else { return }
        
        let results = RealmTaskService.shared.getPendingTasks(for: user)
        notificationToken = results.observe { [weak self] changes in
            switch changes {
            case .initial(let results):
                self?.tasks = Array(results)
            case .update(let results, _, _, _):
                self?.tasks = Array(results)
            case .error(let error):
                print("Realm observation error: \(error)")
            }
        }
    }
}
```

## 📊 高度な機能

### 1. 統計情報の取得

```swift
// ユーザー統計
let userStats = userService.getUserStats(for: user)
print("Level: \(userStats.level)")
print("Completion Rate: \(userStats.completionRate)")

// タスク統計
let taskStats = taskService.getTaskStatistics(for: user)
print("Total Tasks: \(taskStats.totalTasks)")
print("Most Productive Day: \(taskStats.mostProductiveDay)")
```

### 2. 複雑なクエリ

```swift
// タスク検索
let searchResults = taskService.searchTasks(for: user, query: "プログラミング")

// 複数条件フィルタ
let complexQuery = user.tasks
    .filter("priority >= 2 AND taskType == %@ AND isCompleted == false", TaskType.intelligence.rawValue)
    .sorted(byKeyPath: "dueDate", ascending: true)
```

### 3. バッチ操作

```swift
// 複数タスクを一括作成
let templates = [
    TaskTemplate(title: "Task 1", description: nil, experienceReward: 10, priority: 1, taskType: .strength, dueDate: nil),
    TaskTemplate(title: "Task 2", description: nil, experienceReward: 15, priority: 2, taskType: .intelligence, dueDate: nil)
]

let createdTasks = try taskService.createBatchTasks(for: user, taskTemplates: templates)
```

### 4. データエクスポート

```swift
// JSON形式でユーザーデータをエクスポート
let exportData = userService.exportUserData(user: user)

// CSV形式でタスクデータをエクスポート
let csvData = taskService.exportTasksToCSV(for: user)
```

## 🔄 マイグレーション

### Core DataからRealmへの移行

```swift
// Core Dataコンテキストを用意
guard let context = persistentContainer.viewContext else { return }

// 移行実行
do {
    try RealmMigrationService.shared.migrateCoreDataToRealm(from: context)
    print("Migration completed successfully")
} catch {
    print("Migration failed: \(error)")
}
```

### スキーマバージョン更新

```swift
// RealmDatabaseManager.swiftで現在のバージョンを更新
private let currentSchemaVersion: UInt64 = 2 // 1から2に更新

// RealmMigrationService.swiftで新しいマイグレーション処理を追加
private func migrateToVersion2(migration: Migration) {
    // マイグレーション処理を実装
}
```

## ⚡ パフォーマンス最適化

### 1. インデックスの活用

モデルクラスで適切なインデックスを設定：

```swift
override static func indexedProperties() -> [String] {
    return ["isCompleted", "createdAt", "priority", "taskType"]
}
```

### 2. 効率的なクエリ

```swift
// 良い例：インデックスを活用
let tasks = user.tasks.filter("isCompleted == false")

// 避けるべき：計算プロパティでのフィルタ
// let tasks = user.tasks.filter { !$0.isCompleted }
```

### 3. バッチ処理

```swift
// 複数の更新を1つのトランザクションで実行
try databaseManager.safeWrite {
    for task in tasks {
        task.experienceReward += 5
    }
}
```

## 🧪 テストとデバッグ

### 1. テストデータ生成

```swift
let examples = RealmUsageExamples()
examples.generateSampleData()
```

### 2. データ検証

```swift
let validation = RealmMigrationService.shared.validateDataIntegrity()
print(validation.summary)
```

### 3. データベース統計

```swift
let stats = RealmDatabaseManager.shared.getDatabaseStats()
print("Database size: \(stats["fileSize"] ?? "Unknown")")
```

## ⚠️ 注意事項

### 1. スレッドセーフティ

- Realmオブジェクトは作成されたスレッドでのみ使用可能
- 異なるスレッド間でのオブジェクト共有は禁止
- 必要に応じて`ThreadSafeReference`を使用

### 2. メモリ管理

- 大量のオブジェクトを扱う際は`autoreleasepool`の使用を検討
- 長時間保持するRealmインスタンスは避ける

### 3. トランザクション

- 書き込み操作は必ずwrite transactionで実行
- 大量のデータ更新はバッチ処理を使用

## 🆘 トラブルシューティング

### よくある問題

1. **Migration Error**
   - スキーマバージョンを確認
   - マイグレーション処理が正しく実装されているか確認

2. **Thread Error**
   - Realmオブジェクトを正しいスレッドで使用しているか確認
   - `@StateObject`や`@ObservedObject`の使用を検討

3. **Performance Issues**
   - クエリにインデックスが適用されているか確認
   - バッチ処理の使用を検討

### デバッグ方法

```swift
// Realm Browser でデータベースファイルを確認
print("Database location: \(RealmDatabaseManager.shared.getRealm().configuration.fileURL)")

// ログを有効化
Realm.Configuration.defaultConfiguration.shouldCompactOnLaunch = { totalBytes, usedBytes in
    print("Database size: \(totalBytes), used: \(usedBytes)")
    return false
}
```

## 📚 参考資料

- [Realm Swift Documentation](https://docs.mongodb.com/realm/sdk/swift/)
- [Realm Academy](https://academy.realm.io/)
- [SwiftUI + Realm Integration Guide](https://docs.mongodb.com/realm/sdk/swift/examples/swiftui-tutorial/)

## 🤝 コントリビューション

バグ報告や機能提案は Issue から、コード改善は Pull Request でお願いします。

## 📄 ライセンス

このプロジェクトは MIT License の下で公開されています。