import SwiftUI
import CoreData

/// デバッグメニューとテスト機能を提供するサービス
class DebugMenuService {
    static let shared = DebugMenuService()
    
    private init() {}
    
    /// MainGameViewに表示するデバッグボタンを作成
    func createDebugButton() -> some View {
        #if DEBUG
        return Button(action: {
            showDebugMenu()
        }) {
            HStack {
                Image(systemName: "ladybug.fill")
                    .foregroundColor(.red)
                Text("🧪 DEBUG")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding(8)
            .background(Color.black.opacity(0.7))
            .cornerRadius(8)
        }
        .position(x: UIScreen.main.bounds.width - 80, y: 50)
        #else
        return EmptyView()
        #endif
    }
    
    /// デバッグメニューを表示
    private func showDebugMenu() {
        let alert = UIAlertController(
            title: "🧪 Debug Menu",
            message: "テストデータ操作を選択してください",
            preferredStyle: .actionSheet
        )
        
        // 新規ユーザー状態にリセット
        alert.addAction(UIAlertAction(title: "🔄 新規ユーザー状態にリセット", style: .destructive) { _ in
            TestDataManager.shared.resetToNewUserState()
            self.showSuccessAlert("新規ユーザー状態にリセットしました")
        })
        
        // チュートリアルのみリセット
        alert.addAction(UIAlertAction(title: "🎯 チュートリアルのみリセット", style: .default) { _ in
            TestDataManager.shared.resetTutorialStateOnly()
            self.showSuccessAlert("チュートリアル状態をリセットしました")
        })
        
        // テストデータ作成
        alert.addAction(UIAlertAction(title: "🧪 テストデータ作成", style: .default) { _ in
            TestDataManager.shared.createTestData()
            self.showSuccessAlert("テストデータを作成しました")
        })
        
        // データ状態確認
        alert.addAction(UIAlertAction(title: "📊 データ状態確認", style: .default) { _ in
            TestDataManager.shared.printCurrentDataState()
            self.showSuccessAlert("データ状態をコンソールに出力しました")
        })
        
        // レベル強制アップ
        alert.addAction(UIAlertAction(title: "⬆️ レベル強制アップ", style: .default) { _ in
            self.forceAddExperience(amount: 500)
            self.showSuccessAlert("経験値500を追加しました")
        })
        
        // キャンセル
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        // 表示
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    /// 成功メッセージを表示
    private func showSuccessAlert(_ message: String) {
        let alert = UIAlertController(title: "✅ 完了", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    /// 経験値を強制的に追加（テスト用）
    private func forceAddExperience(amount: Int) {
        let context = PersistenceController.shared.container.viewContext
        
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        
        do {
            if let user = try context.fetch(request).first {
                user.addExperience(Int32(amount))
                try context.save()
                
                // 通知を送信してUIを更新
                NotificationCenter.default.post(name: NSNotification.Name("UserExperienceUpdated"), object: nil)
            }
        } catch {
            print("❌ 経験値追加エラー: \(error)")
        }
    }
    
    /// 隠しジェスチャーでデバッグメニューを有効化
    func createHiddenDebugGesture() -> some Gesture {
        // 画面左上角を3回タップでデバッグメニュー表示
        return TapGesture(count: 3)
            .onEnded {
                #if DEBUG
                self.showDebugMenu()
                #endif
            }
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// デバッグボタンを画面右上に配置
    func addDebugButton() -> some View {
        #if DEBUG
        return self.overlay(
            DebugMenuService.shared.createDebugButton(),
            alignment: .topTrailing
        )
        #else
        return self
        #endif
    }
    
    /// 隠しデバッグジェスチャーを追加
    func addHiddenDebugGesture() -> some View {
        #if DEBUG
        return self.gesture(
            DebugMenuService.shared.createHiddenDebugGesture()
        )
        #else
        return self
        #endif
    }
}