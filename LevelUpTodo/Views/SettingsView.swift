import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var settingsNavigationPath = NavigationPath()
    @State private var showingTutorialResetAlert = false
    
    var body: some View {
        NavigationStack(path: $settingsNavigationPath) {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            // 基本設定
                            SettingsSectionView(
                                title: "基本設定",
                                icon: "gearshape.fill",
                                color: .blue
                            ) {
                                Button(action: {
                                    openNotificationSettings()
                                }) {
                                    SettingsRowView(icon: "bell.fill", title: "通知設定", color: .blue)
                                }
                            }
                            
                            // プロフィール設定
                            SettingsSectionView(
                                title: "プロフィール設定",
                                icon: "person.fill",
                                color: .green
                            ) {
                                Button(action: {
                                    settingsNavigationPath.append("ProfileSettings")
                                }) {
                                    SettingsRowView(icon: "person.circle.fill", title: "ユーザー名の変更", color: .green)
                                }
                                Button(action: {
                                    settingsNavigationPath.append("ThemeSettings")
                                }) {
                                    SettingsRowView(icon: "paintbrush.fill", title: "テーマ設定", color: .green)
                                }
                            }
                            
                            // テストデータ管理 (開発者向け)
                            SettingsSectionView(
                                title: "🧪 テストデータ管理 (開発者向け)",
                                icon: "wrench.and.screwdriver.fill",
                                color: .orange
                            ) {
                                Button(action: {
                                    TestDataManager.shared.resetToNewUserState()
                                }) {
                                    SettingsRowView(icon: "arrow.counterclockwise.circle.fill", title: "新規ユーザー状態にリセット", color: .red)
                                }
                                Button(action: {
                                    TestDataManager.shared.resetTutorialStateOnly()
                                }) {
                                    SettingsRowView(icon: "graduationcap.fill", title: "チュートリアルのみリセット", color: .orange)
                                }
                                Button(action: {
                                    TestDataManager.shared.createTestData()
                                }) {
                                    SettingsRowView(icon: "testtube.2", title: "テストデータ作成", color: .blue)
                                }
                                Button(action: {
                                    TestDataManager.shared.printCurrentDataState()
                                }) {
                                    SettingsRowView(icon: "info.circle.fill", title: "データ状態確認 (コンソール)", color: .gray)
                                }
                            }
                            
                            // レベル・ゲーミフィケーション設定
                            SettingsSectionView(
                                title: "レベル・ゲーミフィケーション設定",
                                icon: "gamecontroller.fill",
                                color: .purple
                            ) {
                                Button(action: {
                                    settingsNavigationPath.append("ExperienceSettings")
                                }) {
                                    SettingsRowView(icon: "star.fill", title: "経験値表示設定", color: .purple)
                                }
                                Button(action: {
                                    settingsNavigationPath.append("LevelUpNotification")
                                }) {
                                    SettingsRowView(icon: "bell.badge.fill", title: "レベルアップ通知", color: .purple)
                                }
                                Button(action: {
                                    settingsNavigationPath.append("AchievementSettings")
                                }) {
                                    SettingsRowView(icon: "trophy.fill", title: "実績・バッジ表示", color: .purple)
                                }
                                Button(action: {
                                    settingsNavigationPath.append("GoalSettings")
                                }) {
                                    SettingsRowView(icon: "target", title: "目標設定", color: .purple)
                                }
                            }
                            
                            // タスク管理設定
                            SettingsSectionView(
                                title: "タスク管理設定",
                                icon: "checklist",
                                color: .orange
                            ) {
                                Button(action: {
                                    settingsNavigationPath.append("CategoryManagement")
                                }) {
                                    SettingsRowView(icon: "folder.fill", title: "カテゴリ管理", color: .orange)
                                }
                                Button(action: {
                                    settingsNavigationPath.append("CompletedTaskSettings")
                                }) {
                                    SettingsRowView(icon: "clock.arrow.circlepath", title: "完了タスクの表示期間", color: .orange)
                                }
                            }
                            
                            // その他
                            SettingsSectionView(
                                title: "その他",
                                icon: "ellipsis.circle.fill",
                                color: .gray
                            ) {
                                Button(action: {
                                    settingsNavigationPath.append("AppInfo")
                                }) {
                                    SettingsRowView(icon: "info.circle.fill", title: "アプリ情報", color: .gray)
                                }
                                Button(action: {
                                    settingsNavigationPath.append("Feedback")
                                }) {
                                    SettingsRowView(icon: "envelope.fill", title: "フィードバック", color: .gray)
                                }
                                Button(action: {
                                    resetTutorial()
                                }) {
                                    SettingsRowView(icon: "arrow.clockwise.circle.fill", title: "チュートリアルリセット", color: .cyan)
                                }
                                Button(action: {
                                    settingsNavigationPath.append("DataReset")
                                }) {
                                    SettingsRowView(icon: "trash.fill", title: "データリセット", color: .red)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 50) // ヘッダー削除分のトップ余白
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("チュートリアルをリセット", isPresented: $showingTutorialResetAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("リセット", role: .destructive) {
                    TutorialManager.shared.resetTutorial()
                }
            } message: {
                Text("次回起動時にチュートリアルが表示されます。よろしいですか？")
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "BasicSettings":
                    BasicSettingsView()
                case "ProfileSettings":
                    ProfileSettingsView()
                case "ThemeSettings":
                    ThemeSettingsView()
                case "ExperienceSettings":
                    ExperienceSettingsView()
                case "LevelUpNotification":
                    LevelUpNotificationView()
                case "AchievementSettings":
                    AchievementSettingsView()
                case "GoalSettings":
                    GoalSettingsView()
                case "CategoryManagement":
                    CategoryManagementView()
                case "CompletedTaskSettings":
                    CompletedTaskSettingsView()
                case "AppInfo":
                    AppInfoView()
                case "Feedback":
                    FeedbackView()
                case "DataReset":
                    DataResetView()
                default:
                    Text("Unknown destination")
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color(.sRGB, red: 0.05, green: 0.05, blue: 0.15, opacity: 1.0),
                Color(.sRGB, red: 0.1, green: 0.0, blue: 0.2, opacity: 1.0),
                Color(.sRGB, red: 0.05, green: 0.05, blue: 0.15, opacity: 1.0),
                Color.black
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private func openNotificationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
    
    private func resetTutorial() {
        showingTutorialResetAlert = true
    }
}
    
// MARK: - Common UI Components
struct SettingsSectionView<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            VStack(spacing: 8) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [color.opacity(0.7), color.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .shadow(color: color.opacity(0.3), radius: 8)
        )
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Sub Views

struct BasicSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                // Custom back button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 16) {
                        notificationSettingsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var notificationSettingsSection: some View {
        VStack(spacing: 16) {
            Text("通知設定")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("現在開発中です")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 40)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.blue.opacity(0.5), lineWidth: 1)
        )
    }
}

struct ProfileSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var newUsername = ""
    @State private var showingAlert = false
    @State private var refreshTrigger = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                // Custom back button
                HStack {
                    Button(action: {
                        // 複数の戻る方法を試行
                        print("🔄 Back button tapped")
                        
                        // 方法1: presentationMode
                        presentationMode.wrappedValue.dismiss()
                        
                        // 方法2: dismiss環境変数 (iOS 15+)
                        if #available(iOS 15.0, *) {
                            dismiss()
                        }
                        
                        // 方法3: NotificationCenterで戻る通知を送信
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(name: NSNotification.Name("DismissProfileSettings"), object: nil)
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 16) {
                        usernameChangeSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("ユーザー名を変更しました", isPresented: $showingAlert) {
            Button("OK") { }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserLeveledUp"))) { _ in
            refreshTrigger.toggle()
        }
        .onAppear {
            refreshTrigger.toggle() // 画面表示時に強制更新
        }
    }
    
    private var usernameChangeSection: some View {
        VStack(spacing: 16) {
            Text("プロフィール設定")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let _ = refreshTrigger // Force refresh when this changes
            if let user = getUser() {
                VStack(spacing: 16) {
                    // アバター表示
                    HStack {
                        Text("現在のアバター:")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                        Image(getCurrentAvatarImage(for: user))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.green, lineWidth: 2)
                            )
                    }
                    
                    // 役職表示
                    HStack {
                        Text("現在の役職:")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(getCurrentJobName(for: user))
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    
                    // レベル表示
                    HStack {
                        Text("レベル:")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("Lv. \(user.level)")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                    
                    // 区切り線
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    
                    // ユーザー名変更
                    VStack(spacing: 12) {
                        HStack {
                            Text("現在のユーザー名:")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(.gray)
                            Spacer()
                            Text(user.name ?? "未設定")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        TextField("新しいユーザー名", text: $newUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onAppear {
                                newUsername = user.name ?? ""
                            }
                        
                        Button("変更") {
                            updateUsername(user: user)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.green.opacity(0.5), lineWidth: 1)
        )
    }
    
    private func getUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        return try? viewContext.fetch(request).first
    }
    
    private func updateUsername(user: User) {
        user.name = newUsername.isEmpty ? "冒険者" : newUsername
        try? viewContext.save()
        showingAlert = true
    }
    
    private func avatarImage(for avatarType: String?) -> String {
        return avatarType ?? "boy1"
    }
    
    private func avatarName(for avatarType: String?) -> String {
        switch avatarType {
        case "starter_male", "starter_female":
            return "新米冒険者"
        case "wizard_male", "wizard_female":
            return "魔法使い"
        case "warrior_male", "warrior_female":
            return "戦士"
        case "guard":
            return "護衛"
        case "thief_male", "thief_female":
            return "盗賊"
        case "archmage_male", "archmage_female":
            return "大魔法使い"
        case "knight_male", "knight_female":
            return "騎士"
        default:
            return "冒険者"
        }
    }
    
    private func getCurrentJobName(for user: User) -> String {
        // ExperienceServiceと同じロジックを使用
        if let currentJob = getCurrentJobForUser(user) {
            return currentJob.name
        }
        
        // フォールバック: レベルが5未満の場合
        if user.level < 5 {
            return "見習い冒険者"
        }
        
        // フォールバック: currentJob?.nameがある場合
        if let jobName = user.currentJob?.name {
            return jobName
        }
        
        // 最終フォールバック
        return avatarName(for: user.currentAvatarType)
    }
    
    private func getCurrentAvatarImage(for user: User) -> String {
        // ExperienceServiceと同じロジックを使用
        if let currentJob = getCurrentJobForUser(user) {
            return currentJob.avatarImageName
        }
        
        // フォールバック: user.currentAvatarTypeを使用
        return user.currentAvatarType ?? "boy1"
    }
    
    // ExperienceServiceと同じジョブ判定ロジック
    private func getCurrentJobForUser(_ user: User) -> (name: String, avatarImageName: String)? {
        let level = Int(user.level)
        let dominantStat = getDominantStatForUser(user)
        
        switch (dominantStat, level) {
        // ファイター系 (筋力特化)
        case (.strength, 5): return (name: "見習い戦士", avatarImageName: "warrior_male")
        case (.strength, 10): return (name: "戦士", avatarImageName: "warrior_male")
        case (.strength, 15): return (name: "剣士", avatarImageName: "warrior_female")
        case (.strength, 20): return (name: "騎士", avatarImageName: "knight_male")
        case (.strength, 30): return (name: "パラディン", avatarImageName: "knight_male")
        case (.strength, 50): return (name: "聖騎士", avatarImageName: "knight_female")
        case (.strength, 70): return (name: "武神", avatarImageName: "knight_male")
        case (.strength, 90): return (name: "伝説の戦士", avatarImageName: "knight_female")
        case (.strength, 100): return (name: "不敗の英雄", avatarImageName: "knight_male")
            
        // スカラー系 (知力特化)
        case (.intelligence, 5): return (name: "学徒", avatarImageName: "wizard_male")
        case (.intelligence, 10): return (name: "研究者", avatarImageName: "wizard_male")
        case (.intelligence, 15): return (name: "学者", avatarImageName: "wizard_female")
        case (.intelligence, 20): return (name: "博士", avatarImageName: "wizard_female")
        case (.intelligence, 30): return (name: "賢者", avatarImageName: "archmage_male")
        case (.intelligence, 50): return (name: "大賢者", avatarImageName: "archmage_male")
        case (.intelligence, 70): return (name: "魔導師", avatarImageName: "archmage_female")
        case (.intelligence, 90): return (name: "大魔導師", avatarImageName: "archmage_female")
        case (.intelligence, 100): return (name: "真理の探求者", avatarImageName: "archmage_male")
            
        // エクスプローラー系 (持久力特化)
        case (.endurance, 5): return (name: "冒険者", avatarImageName: "boy1")
        case (.endurance, 10): return (name: "探検家", avatarImageName: "thief_male")
        case (.endurance, 15): return (name: "レンジャー", avatarImageName: "thief_male")
        case (.endurance, 20): return (name: "ガイド", avatarImageName: "thief_female")
        case (.endurance, 30): return (name: "パスファインダー", avatarImageName: "thief_female")
        case (.endurance, 50): return (name: "マスターガイド", avatarImageName: "thief_male")
        case (.endurance, 70): return (name: "地平の開拓者", avatarImageName: "thief_female")
        case (.endurance, 90): return (name: "世界の歩き手", avatarImageName: "thief_male")
        case (.endurance, 100): return (name: "無限の旅人", avatarImageName: "thief_female")
            
        // マスター系 (集中力特化)
        case (.focus, 5): return (name: "職人見習い", avatarImageName: "guard")
        case (.focus, 10): return (name: "職人", avatarImageName: "guard")
        case (.focus, 15): return (name: "熟練工", avatarImageName: "knight_male")
        case (.focus, 20): return (name: "マスター", avatarImageName: "knight_male")
        case (.focus, 30): return (name: "名工", avatarImageName: "knight_female")
        case (.focus, 50): return (name: "宗匠", avatarImageName: "knight_female")
        case (.focus, 70): return (name: "達人", avatarImageName: "archmage_male")
        case (.focus, 90): return (name: "人間国宝", avatarImageName: "archmage_male")
        case (.focus, 100): return (name: "伝説の匠", avatarImageName: "archmage_female")
            
        // アーティスト系 (創造力特化)
        case (.creativity, 5): return (name: "創作者", avatarImageName: "girl1")
        case (.creativity, 10): return (name: "アーティスト", avatarImageName: "wizard_female")
        case (.creativity, 15): return (name: "クリエイター", avatarImageName: "wizard_female")
        case (.creativity, 20): return (name: "イノベーター", avatarImageName: "archmage_female")
        case (.creativity, 30): return (name: "ビジョナリー", avatarImageName: "archmage_female")
        case (.creativity, 50): return (name: "マエストロ", avatarImageName: "archmage_male")
        case (.creativity, 70): return (name: "天才", avatarImageName: "archmage_male")
        case (.creativity, 90): return (name: "革命家", avatarImageName: "archmage_female")
        case (.creativity, 100): return (name: "時代の創造主", avatarImageName: "archmage_female")
            
        default:
            // 指定レベルでない場合は一つ下のレベルを再帰的に検索
            let validLevels = [5, 10, 15, 20, 30, 50, 70, 90, 100]
            let closestLevel = validLevels.filter { $0 <= level }.last ?? 5
            if closestLevel != level {
                var tempUser = user
                tempUser.level = Int32(closestLevel)
                return getCurrentJobForUser(tempUser)
            }
            return nil
        }
    }
    
    private enum UserStatType {
        case strength, intelligence, endurance, focus, creativity
    }
    
    private func getDominantStatForUser(_ user: User) -> UserStatType {
        let stats = [
            (value: Int(user.strength), type: UserStatType.strength),
            (value: Int(user.intelligence), type: UserStatType.intelligence),
            (value: Int(user.endurance), type: UserStatType.endurance),
            (value: Int(user.focus), type: UserStatType.focus),
            (value: Int(user.creativity), type: UserStatType.creativity)
        ]
        
        return stats.max(by: { $0.value < $1.value })?.type ?? .strength
    }
}

struct JobHistoryView: View {
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                NavigationHeaderView(title: "役職履歴")
                
                ScrollView {
                    VStack(spacing: 16) {
                        Text("役職履歴閲覧")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("現在開発中です")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Theme Settings
struct ThemeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("userInterfaceStyle") private var userInterfaceStyle: Int = 0 // 0: System, 1: Light, 2: Dark
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                // Custom back button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 16) {
                        themeSelectionSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var themeSelectionSection: some View {
        VStack(spacing: 16) {
            Text("テーマ設定")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                themeOptionButton(title: "システム設定に従う", icon: "iphone", index: 0)
                themeOptionButton(title: "ライトモード", icon: "sun.max", index: 1)
                themeOptionButton(title: "ダークモード", icon: "moon", index: 2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
        )
    }
    
    private func themeOptionButton(title: String, icon: String, index: Int) -> some View {
        Button(action: {
            userInterfaceStyle = index
            updateUserInterfaceStyle(index)
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(userInterfaceStyle == index ? .cyan : .gray)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(userInterfaceStyle == index ? .white : .gray)
                
                Spacer()
                
                if userInterfaceStyle == index {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.cyan)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(userInterfaceStyle == index ? Color.cyan.opacity(0.1) : Color.clear)
                    .stroke(userInterfaceStyle == index ? Color.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
    }
    
    private func updateUserInterfaceStyle(_ style: Int) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        switch style {
        case 0:
            window.overrideUserInterfaceStyle = .unspecified
        case 1:
            window.overrideUserInterfaceStyle = .light
        case 2:
            window.overrideUserInterfaceStyle = .dark
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
}

// MARK: - Experience Settings
struct ExperienceSettingsView: View {
    @AppStorage("showExperienceGain") private var showExperienceGain = true
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                NavigationHeaderView(title: "経験値表示設定")
                
                ScrollView {
                    VStack(spacing: 16) {
                        experienceDisplaySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var experienceDisplaySection: some View {
        VStack(spacing: 16) {
            Text("経験値表示設定")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Toggle("経験値獲得時の表示", isOn: $showExperienceGain)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.purple.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Level Up Notification
struct LevelUpNotificationView: View {
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                NavigationHeaderView(title: "レベルアップ通知")
                
                ScrollView {
                    VStack(spacing: 16) {
                        Text("現在開発中です")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Achievement Settings
struct AchievementSettingsView: View {
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                NavigationHeaderView(title: "実績・バッジ表示")
                
                ScrollView {
                    VStack(spacing: 16) {
                        Text("現在開発中です")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Category Management
struct CategoryManagementView: View {
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                NavigationHeaderView(title: "カテゴリ管理")
                
                ScrollView {
                    VStack(spacing: 16) {
                        Text("現在開発中です")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Completed Task Settings
struct CompletedTaskSettingsView: View {
    @AppStorage("completedTaskDisplayDays") private var displayDays = 1
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                NavigationHeaderView(title: "完了タスクの表示期間")
                
                ScrollView {
                    VStack(spacing: 16) {
                        displayPeriodSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var displayPeriodSection: some View {
        VStack(spacing: 16) {
            Text("完了済みタスクの表示期間")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("表示期間:")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("表示期間", selection: $displayDays) {
                    Text("1日").tag(1)
                    Text("3日").tag(3)
                    Text("7日").tag(7)
                    Text("30日").tag(30)
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
        )
    }
}

struct GoalSettingsView: View {
    @AppStorage("dailyTaskGoal") private var dailyTaskGoal = 3
    @AppStorage("weeklyTaskGoal") private var weeklyTaskGoal = 15
    @AppStorage("monthlyTaskGoal") private var monthlyTaskGoal = 60
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                NavigationHeaderView(title: "目標設定")
                
                ScrollView {
                    VStack(spacing: 16) {
                        dailyGoalSection
                        weeklyGoalSection
                        monthlyGoalSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var dailyGoalSection: some View {
        VStack(spacing: 16) {
            Text("1日の目標タスク数設定")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("1日の目標タスク数:")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                Stepper("\(dailyTaskGoal)個", value: $dailyTaskGoal, in: 1...20)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.purple.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var weeklyGoalSection: some View {
        VStack(spacing: 16) {
            Text("週の目標タスク数設定")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("週の目標タスク数:")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                Stepper("\(weeklyTaskGoal)個", value: $weeklyTaskGoal, in: 1...100)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.purple.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var monthlyGoalSection: some View {
        VStack(spacing: 16) {
            Text("月の目標タスク数設定")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("月の目標タスク数:")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                Stepper("\(monthlyTaskGoal)個", value: $monthlyTaskGoal, in: 1...500)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.purple.opacity(0.5), lineWidth: 1)
        )
    }
}

struct AppInfoView: View {
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                NavigationHeaderView(title: "アプリ情報")
                
                ScrollView {
                    VStack(spacing: 16) {
                        appVersionSection
                        termsSection
                        privacySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var appVersionSection: some View {
        VStack(spacing: 12) {
            Text("バージョン情報")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("バージョン:")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text("1.0.0")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var termsSection: some View {
        VStack(spacing: 12) {
            Text("利用規約")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("現在作成中です")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var privacySection: some View {
        VStack(spacing: 12) {
            Text("プライバシーポリシー")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("現在作成中です")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
}

struct FeedbackView: View {
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                NavigationHeaderView(title: "フィードバック")
                
                ScrollView {
                    VStack(spacing: 16) {
                        contactSection
                        reviewSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var contactSection: some View {
        VStack(spacing: 12) {
            Text("お問い合わせ")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("ご質問やご要望がございましたら、\nお気軽にお問い合わせください。")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.vertical, 20)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var reviewSection: some View {
        VStack(spacing: 12) {
            Text("レビュー依頼")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("アプリを気に入っていただけましたら、\nApp Storeでレビューをお願いします！")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.vertical, 20)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
}

struct DataResetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false
    @State private var confirmationText = ""
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                NavigationHeaderView(title: "データリセット")
                
                ScrollView {
                    VStack(spacing: 16) {
                        warningSection
                        confirmationSection
                        resetButtonSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("データリセット完了", isPresented: $showingAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("全てのデータが削除されました。")
        }
    }
    
    private var warningSection: some View {
        VStack(spacing: 12) {
            Text("⚠️ 警告")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("この操作により、以下のデータが完全に削除されます：\n\n• 全てのタスク\n• ユーザープロフィール\n• レベルと経験値\n• 全ての設定\n\nこの操作は取り消すことができません。")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
                .stroke(Color.red.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var confirmationSection: some View {
        VStack(spacing: 12) {
            Text("確認")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("データリセットを実行するには、\n下のテキストフィールドに\n\"RESET\"と入力してください。")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            TextField("RESET と入力", text: $confirmationText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.allCharacters)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var resetButtonSection: some View {
        Button("全データを削除") {
            resetAllData()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(confirmationText == "RESET" ? Color.red : Color.gray)
        .foregroundColor(.white)
        .cornerRadius(12)
        .font(.system(size: 16, weight: .bold, design: .monospaced))
        .disabled(confirmationText != "RESET")
    }
    
    private func resetAllData() {
        // Delete all TodoItems
        let todoRequest: NSFetchRequest<NSFetchRequestResult> = TodoItem.fetchRequest()
        let todoDeleteRequest = NSBatchDeleteRequest(fetchRequest: todoRequest)
        
        // Delete all Users
        let userRequest: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()
        let userDeleteRequest = NSBatchDeleteRequest(fetchRequest: userRequest)
        
        do {
            try viewContext.execute(todoDeleteRequest)
            try viewContext.execute(userDeleteRequest)
            try viewContext.save()
            showingAlert = true
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
}

// MARK: - Helper Functions
private var backgroundGradient: some View {
    LinearGradient(
        gradient: Gradient(colors: [
            Color.black,
            Color(.sRGB, red: 0.05, green: 0.05, blue: 0.15, opacity: 1.0),
            Color(.sRGB, red: 0.1, green: 0.0, blue: 0.2, opacity: 1.0),
            Color(.sRGB, red: 0.05, green: 0.05, blue: 0.15, opacity: 1.0),
            Color.black
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    .ignoresSafeArea()
}


// カスタム戻るボタン付きヘッダー
struct NavigationHeaderView: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.cyan)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
}
    

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}