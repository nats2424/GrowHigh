# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# LevelUpTodo - Gamified Todo App Development Guide

## Project Overview
LevelUpTodo is an iOS gamification todo app inspired by "Solo Leveling". Users gain experience points by completing tasks and level up their avatar through a job system progression.

## Build and Development Commands

### Building the Project
```bash
# Open in Xcode (primary development environment)
open LevelUpTodo.xcodeproj

# Build from command line (if needed)
xcodebuild -project LevelUpTodo.xcodeproj -scheme LevelUpTodo -configuration Debug

# File watching script for development
./watch_files.sh
```

### Testing
Currently no automated test suite is configured. Testing is done manually through Xcode simulator and device testing.

## Architecture Overview

### Data Layer
- **Primary Database**: Realm (replacing Core Data migration in progress)
  - `RealmDatabaseManager`: Singleton managing Realm configuration and migrations
  - Schema version: 2 (actively being versioned)
  - Models in `LevelUpTodo/Models/RealmModels.swift`
- **Legacy**: Core Data (still present, gradual migration to Realm)
  - Persistence.swift handles Core Data stack
  - .xcdatamodeld files contain Core Data models

### Architecture Patterns
- **DI Container**: `Architecture/DI/DIContainer.swift` manages dependency injection
- **MVVM**: Views use observable objects for state management  
- **Repository Pattern**: Data access abstracted through repository interfaces
- **Use Cases**: Business logic encapsulated in use case classes

### Key Services
- **AppState**: Centralized app state management (`Services/AppState.swift`)
- **ExperienceService**: Handles XP calculations and leveling logic
- **JobSystemService**: Manages character job progression system  
- **RealmDatabaseManager**: Database operations and migrations
- **TutorialManager**: Tutorial system state management
- **LevelUpMessageService/LevelUpStatisticsService**: Level up notifications and stats

### Job System Architecture
The app uses a sophisticated job progression system with:
- Multiple job categories: Warrior, Magic, Guardian, Ranger, Creative
- Character images organized by job type in `assets/character/`
- 5 RPG stats: Strength, Focus, Continuity, Intelligence, Achievement
- Progressive job unlocking based on level requirements

## Code Quality Guidelines

### UI/UX Rules (Critical - Must Follow)
- **Color Restrictions**: 
  - Purple: Use `Color(red: 0.3, green: 0.1, blue: 0.5)` instead of standard purple
  - Blue: Use `Color(red: 0.1, green: 0.3, blue: 0.7)` instead of bright cyan
  - Stats text: Always white on stats screens
- **Terminology**: "Quest" → "Task" (consistently use "Task")
- **UI Elements**: No emojis in UI, no header icons in task creation, minimal design approach

### SwiftUI Error Resolution Strategy
When encountering compilation errors, follow this proven approach:
1. **Phase 1 - Temporary Fix**: Add minimal stub implementations to resolve immediate build errors
2. **Phase 2 - Structural Fixes**: Remove duplicates, fix scopes, resolve API changes  
3. **Phase 3 - Cleanup**: Remove temporary implementations, verify final build

### File Organization Principles
- Views: UI components and SwiftUI views
- Services: Business logic and app services
- Models: Data models (both Core Data and Realm)
- Architecture: DI container, repositories, use cases
- Assets: Character images organized by job hierarchy

## Data Model Key Points

### User Model (Realm)
- 5 RPG stats system: strength, focus, continuity, intelligence, achievement
- Job progression with level requirements
- Experience points with cubic growth formula (N³)
- Gender selection affects available character sprites

### Task System
- Tasks have experience rewards (5-100 XP range)
- Task completion triggers experience gain and potential level ups
- Tutorial system guides new users through task creation

## Migration Notes
- **Database Migration**: Active migration from Core Data to Realm
- **Dual Database Support**: Both systems currently coexist  
- **Schema Versioning**: Realm schema at version 2, includes migration logic

## Communication Guidelines
- **Language**: Always respond in Japanese (日本語) when working with this codebase
- **User Preference**: The development team prefers Japanese communication for all interactions

## UI/UX設計原則

### 色彩設計
- **紫色**: 視認性が悪いため使用禁止。代替色: `Color(red: 0.3, green: 0.1, blue: 0.5)` (暗い紫)
- **青色（シアン）**: 明るすぎるため使用禁止。代替色: `Color(red: 0.1, green: 0.3, blue: 0.7)` (暗い青)
- **統計画面のテキスト**: すべて白色で統一
- **Intelligence（知力）タスクタイプ**: `Color(red: 0.3, green: 0.1, blue: 0.5)`

### タスク追加画面のルール
- **ヘッダーアイコン**: 表示しない
- **用語統一**: 「クエスト」→「タスク」に統一
- **絵文字**: 一切使用しない（タイトル、ステータス選択、時間選択等）
- **難易度**: 「難易度設定」→「所要時間」に変更
- **経験値プレビュー**: 表示しない
- **ボタンテキスト**: 「冒険を開始」→「タスク作成」

### ステータス表示
- **タスク追加時**: ステータス強化設定は非表示
- **統計画面**: ステータステキストは白色統一

### 一般的なUI原則
- **絵文字**: 全般的に使用を控える
- **シンプルさ**: 必要最小限の情報のみ表示
- **一貫性**: 色彩、用語、レイアウトの統一

## 過去の修正履歴
- 2024-12-XX: 紫色・青色の視認性改善（更に暗い色に変更）
- 2024-12-XX: タスク追加画面の完全改修
  - ヘッダーアイコン削除
  - クエスト→タスク用語統一
  - 全絵文字削除
  - 難易度設定→所要時間変更
  - 経験値プレビュー削除
  - 冒険を開始→タスク作成変更
- 2024-12-XX: 統計画面テキスト白色統一
- 2025-08-19: MainGameView.swift コンパイルエラー修正
  - 13+個のコンパイルエラーを段階的修正方式で解決
  - 仮実装→本実装のアプローチを確立
  - 重複定義問題の解決パターンを確立
  - SwiftUI API変更対応（navigationBarTitleDisplayMode）
  - Core Data extension パターンを確立

## コード品質管理方針

### コンパイルエラー修正の基本方針
**修正優先順位**:
1. **Missing types/components** (最優先) - 型やコンポーネントが見つからないエラー
2. **API/Navigation issues** (高優先) - SwiftUI API変更やナビゲーション関連
3. **Scope and access errors** - プライベート関数のスコープエラー
4. **Duplicate definitions** - 重複定義の削除
5. **Structural issues** - 括弧の対応、構造的な問題

### 実装アプローチ
**段階的修正方式**:
- **Phase 1**: 仮実装で即座にビルドエラーを解決
  - 最小限のダミー実装を先頭に追加
  - 後から本格実装に置き換え
- **Phase 2**: 構造的問題の修正
  - 重複定義の削除
  - スコープエラーの解決
- **Phase 3**: 最終検証
  - ビルド成功確認
  - 重複実装のクリーンアップ

### SwiftUIファイル構成ルール
**MainGameView.swift 構造管理**:
- **臨時実装**: ファイル先頭に `// MARK: - Temporary Components` セクション
- **本体構造**: MainGameView struct → helper functions → 他のstructs
- **重複回避**: 同名のstruct/enumは1つのファイル内に1つのみ
- **スコープ管理**: private関数は適切な構造体内に配置

### 依存関係とAPIの扱い
**SwiftUI API変更対応**:
- `navigationTitleDisplayMode` → `navigationBarTitleDisplayMode`
- 新しいNavigation APIへの対応時は既存パターンを参考に

**エクステンション管理**:
- Core Data extensionはファイル先頭に配置
- 一時的なextensionも明確にマーク

### ファイル分離の将来方針
**推奨アーキテクチャ**:
- Views/ - UI コンポーネント
- Models/ - データモデル  
- Services/ - ビジネスロジック
- Utilities/ - 汎用ヘルパー
- Extensions/ - 拡張機能

### デバッグとトラブルシューティング
**効率的なエラー解決手順**:
1. Xcodeビルドで具体的エラー特定
2. TaskツールでComparativeコード検索
3. 段階的修正（仮実装→本実装）
4. 各段階でビルド検証
5. 最終的に重複削除とクリーンアップ

## 注意事項
このファイルは今後の開発で同様の手戻りを防ぐために作成されました。
新機能追加や修正時は、このガイドラインに従ってください。