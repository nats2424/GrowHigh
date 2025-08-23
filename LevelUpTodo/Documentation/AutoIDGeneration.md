# UUID自動生成システム

## 概要

Realmデータモデルでは、プライマリキーとして使用されるIDが自動的にUUIDで生成されます。ユーザーが手動でIDを指定する必要はありません。

## 🔧 実装方式

### 1. UUID自動生成の仕組み

各Realmオブジェクトで`awakeFromInsert()`メソッドをオーバーライドし、オブジェクト作成時に自動的にUUIDを生成します。

```swift
/// Realmオブジェクト作成時に自動でUUIDを生成
override func awakeFromInsert() {
    super.awakeFromInsert()
    if id.isEmpty {
        id = UUID().uuidString
    }
}
```

### 2. UUID生成パターン

#### 全オブジェクト共通
```
パターン: UUID Version 4 (ランダム)
例: A1B2C3D4-E5F6-7890-ABCD-EF1234567890
```

- **ユーザーID**: `A1B2C3D4-E5F6-7890-ABCD-EF1234567890`
- **タスクID**: `B2C3D4E5-F6G7-8901-BCDE-F12345678901`  
- **アバターID**: `C3D4E5F6-G7H8-9012-CDEF-123456789012`

## 📝 使用例

### ユーザー作成時

```swift
// IDを指定する必要なし - UUID自動生成される
let user = try userService.createUser(name: "冒険者")
print("Generated UUID: \(user.id)") // A1B2C3D4-E5F6-7890-ABCD-EF1234567890
```

### タスク作成時

```swift
// IDを指定する必要なし - UUID自動生成される
let task = try taskService.createTask(
    for: user,
    title: "プログラミング学習",
    experienceReward: 30
)
print("Generated UUID: \(task.id)") // B2C3D4E5-F6G7-8901-BCDE-F12345678901
```

### アバター作成時

```swift
// アバター作成時も自動でUUIDが生成される
let avatar = RealmAvatar()
avatar.avatarType = "wizard_male"
avatar.name = "魔法使い"
// UUIDは自動生成される: C3D4E5F6-G7H8-9012-CDEF-123456789012
```

## 🎯 UUID生成の特徴

### 1. グローバルユニーク性保証
- RFC 4122準拠のUUID Version 4
- 全世界で絶対に重複しない（理論上）
- 複数デバイス・サーバー間での安全性

### 2. 標準化・互換性
- 国際標準規格でシステム間連携が容易
- 外部API・データベースとの互換性
- 多くのプラットフォームでサポート

### 3. セキュリティ
- 推測不可能なランダム性
- 情報漏洩リスクの軽減
- 外部からのID推測攻撃を防止

## ⚙️ カスタマイズ

必要に応じてID生成ロジックをカスタマイズできます：

```swift
/// カスタムID生成例
private func generateCustomUserID() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMddHHmmss"
    let timestamp = dateFormatter.string(from: Date())
    let uuid = UUID().uuidString.prefix(8)
    return "user_\(timestamp)_\(uuid)"
}
```

## 🔍 トラブルシューティング

### ID重複の回避

万が一ID重複が発生した場合の対処：

```swift
private func generateSafeUserID() -> String {
    var attempts = 0
    let maxAttempts = 10
    
    while attempts < maxAttempts {
        let candidateID = generateUniqueUserID()
        
        // 既存IDとの重複チェック
        if RealmDatabaseManager.shared.fetch(RealmUser.self, primaryKey: candidateID) == nil {
            return candidateID
        }
        
        attempts += 1
        Thread.sleep(forTimeInterval: 0.001) // 1msの遅延
    }
    
    // フォールバック: UUIDを使用
    return "user_\(UUID().uuidString)"
}
```

### デバッグ用ログ

ID生成時のログ出力：

```swift
override func awakeFromInsert() {
    super.awakeFromInsert()
    if id.isEmpty {
        id = generateUniqueUserID()
        print("🆔 Auto-generated User ID: \(id)")
    }
}
```

## 📋 注意事項

1. **IDの手動設定禁止**: 自動生成システムを利用するため、手動でIDを設定しないでください
2. **プライマリキーの不変性**: 一度生成されたIDは変更できません
3. **マイグレーション対応**: 既存データからの移行時は適切な変換処理が必要

## 🔗 関連ファイル

- `RealmModels.swift` - ID自動生成ロジックの実装
- `RealmUserService.swift` - ユーザー作成時の自動ID利用
- `RealmTaskService.swift` - タスク作成時の自動ID利用
- `RealmMigrationService.swift` - データ移行時のID変換処理

この自動ID生成システムにより、開発者はIDの管理を意識することなく、アプリケーションのロジックに集中できます。