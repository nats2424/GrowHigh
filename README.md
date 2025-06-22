# LevelUpTodo - 俺だけレベルアップToDoアプリ

「俺だけレベルアップな件」をモチーフにしたゲーミフィケーションToDoアプリです。タスクを完了することで経験値を獲得し、アバターをレベルアップさせることができます。

## 機能

### 📝 ToDoリスト機能
- タスクの追加・編集・削除
- 優先度設定（高・中・低）
- 経験値報酬の設定（5-100 EXP）
- タスク完了による自動経験値獲得

### 🎮 レベリングシステム
- タスク完了時の経験値獲得
- レベルアップ時の通知
- レベル毎に必要経験値が増加する仕組み
- 総経験値と現在経験値の管理

### 👤 アバターシステム
- 6種類のアバタータイプ
  - デフォルトハンター（Lv.1）
  - 戦士（Lv.5）
  - 魔法使い（Lv.10）
  - 暗殺者（Lv.15）
  - パラディン（Lv.20）
  - 大魔法使い（Lv.30）
- レベル到達によるアバター解放
- アバター変更機能

### 📊 統計機能
- 基本統計（レベル、総経験値、完了/未完了タスク数）
- 今日の実績（完了タスク数、獲得経験値）
- 週間進捗チャート
- 最近完了したタスクの履歴

### 🔔 通知機能
- レベルアップ時のアラート表示
- タスク完了時の経験値獲得通知
- 毎日のリマインダー通知（朝9時）

## 技術仕様

- **プラットフォーム**: iOS 17.0+
- **フレームワーク**: SwiftUI
- **データベース**: Core Data
- **アーキテクチャ**: MVVM

## プロジェクト構造

```
LevelUpTodo/
├── LevelUpTodoApp.swift          # アプリエントリーポイント
├── ContentView.swift             # メインタブビュー
├── Persistence.swift             # Core Data設定
├── Views/
│   ├── TodoListView.swift        # ToDoリスト画面
│   ├── TodoRowView.swift         # ToDo項目表示
│   ├── AddTodoView.swift         # ToDo追加画面
│   ├── UserProgressView.swift    # ユーザー進捗表示
│   ├── AvatarView.swift          # アバター選択画面
│   └── StatsView.swift           # 統計画面
├── Services/
│   ├── UserService.swift         # ユーザー管理ロジック
│   └── NotificationService.swift # 通知管理
├── Resources/
│   └── Assets.xcassets           # アセット
└── LevelUpTodo.xcdatamodeld/     # Core Dataモデル
```

## データモデル

### User
- name: String - ユーザー名
- level: Int32 - 現在のレベル
- experience: Int32 - 現在の経験値
- experienceToNextLevel: Int32 - 次のレベルまでの必要経験値
- totalExperience: Int32 - 総獲得経験値
- currentAvatarType: String - 現在のアバタータイプ
- createdAt: Date - 作成日時

### TodoItem
- title: String - タスクタイトル
- isCompleted: Bool - 完了フラグ
- experienceReward: Int32 - 経験値報酬
- priority: Int32 - 優先度（1-3）
- createdAt: Date - 作成日時
- completedAt: Date? - 完了日時

### Avatar
- avatarType: String - アバタータイプ
- name: String - アバター名
- requiredLevel: Int32 - 解放必要レベル
- isUnlocked: Bool - 解放フラグ
- imageURL: String - 画像URL

## 使用方法

1. Xcodeでプロジェクトを開く
2. シミュレーターまたは実機でビルド・実行
3. 初回起動時に自動的にユーザーとアバターが作成される
4. タスクを追加してゲームを開始

## 今後の拡張可能性

- アチーブメントシステム
- より多様なアバターとカスタマイズ
- ソーシャル機能（フレンドとの競争）
- イベントやクエストシステム
- アバターアニメーション
- 音響効果とBGM