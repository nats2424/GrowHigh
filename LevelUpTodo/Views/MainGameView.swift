import SwiftUI
import CoreData
import Combine

// MARK: - Tutorial Manager (UI Highlight Type)
class TutorialManager: ObservableObject {
    @Published var currentStep: TutorialStep = .taskTab
    @Published var isActive: Bool = false
    @Published var currentHighlight: TutorialHighlightTarget? = nil
    
    static let shared = TutorialManager()
    
    private init() {
        checkInitialState()
    }
    
    func checkInitialState() {
        let hasSeenTutorial = UserDefaults.standard.bool(forKey: "hasSeenTutorial")
        
        if !hasSeenTutorial {
            startTutorial()
        }
    }
    
    func startTutorial() {
        isActive = true
        currentStep = .taskTab
        updateHighlight()
    }
    
    func nextStep() {
        guard let nextStep = TutorialStep(rawValue: currentStep.rawValue + 1) else {
            completeTutorial()
            return
        }
        
        currentStep = nextStep
        updateHighlight()
        
        if currentStep == .finished {
            completeTutorial()
        }
    }
    
    func skipTutorial() {
        completeTutorial()
    }
    
    func completeTutorial() {
        isActive = false
        currentHighlight = nil
        currentStep = .finished
        UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
    }
    
    // MARK: - Debug Functions
    func resetTutorial() {
        UserDefaults.standard.removeObject(forKey: "hasSeenTutorial")
        isActive = false
        currentHighlight = nil
        currentStep = .taskTab
        print("🔄 Tutorial reset - App will show tutorial on next launch")
    }
    
    func forceStartTutorial() {
        startTutorial()
        print("🚀 Tutorial force started")
    }
    
    private func updateHighlight() {
        switch currentStep {
        case .taskTab:
            currentHighlight = .taskTabButton
        case .addButton:
            currentHighlight = .addButton
        case .titleInput:
            currentHighlight = .titleInputField
        case .completeTask:
            currentHighlight = .completeTaskButton
        case .gainXP:
            currentHighlight = .experienceGainNotification
        case .levelUp:
            currentHighlight = .levelUpDisplay
        case .finished:
            currentHighlight = nil
        }
    }
}


enum TutorialStep: Int, CaseIterable {
    case taskTab = 0
    case addButton = 1  
    case titleInput = 2
    case completeTask = 3
    case gainXP = 4
    case levelUp = 5
    case finished = 6
    
    var isSkippable: Bool {
        return true // 全てスキップ可能
    }
    
    var message: String {
        switch self {
        case .taskTab:
            return "ここからタスク一覧に移動できます。タップしてみましょう。"
        case .addButton:
            return "新しいタスクはここから追加できます。"
        case .titleInput:
            return "タスクのタイトルを入力してみましょう。"
        case .completeTask:
            return "タスクが終わったら、ここをタップして完了にしましょう。"
        case .gainXP:
            return "タスク完了で経験値を獲得できます。"
        case .levelUp:
            return "経験値がたまると、あなたのレベルが上がります！"
        case .finished:
            return "チュートリアル完了！"
        }
    }
}

enum TutorialHighlightTarget {
    case taskTabButton
    case addButton
    case titleInputField
    case completeTaskButton
    case experienceGainNotification
    case levelUpDisplay
}


// MARK: - Temporary Components (仮実装)
struct AnimatedParticleBackgroundView: View {
    var body: some View {
        Color.clear.ignoresSafeArea()
    }
}

struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

// MARK: - User Extension
extension User {
    var userName: String {
        get { return self.name ?? "冒険者" }
        set { self.name = newValue }
    }
}

struct MainGameView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var navigationPath = NavigationPath()
    @State private var showingGenderSelection = false
    @State private var showingTaskTutorial = false
    @State private var showingStatsTutorial = false
    @State private var showingAddTodo = false
    
    // チュートリアル関連
    @StateObject private var tutorialManager = TutorialManager.shared
    @State private var showingTutorial = false
    @State private var refreshTrigger = false
    @State private var showingExperienceSnackbar = false
    @State private var earnedExperience = 0
    @State private var showingJobPromotionAlert = false
    @State private var newJobName = ""
    @State private var newJobDescription = ""
    @State private var showingLevelUpModal = false
    @State private var levelUpStatistics: [String: Any]?
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: Double = 1.0
    @State private var sparkleScale: Double = 1.0
    @State private var showingProfileModal = false
    
    var body: some View {
        ZStack {
            // 最上位背景（白化防止）
            Color.black
                .ignoresSafeArea(.all)
            
            NavigationStack(path: $navigationPath) {
                GeometryReader { geometry in
                    ZStack {
                    // プレミアムダークゲーミング背景
                    premiumBackgroundView
                        .ignoresSafeArea(.all)
                    
                    // 動的パーティクルエフェクト
                    AnimatedParticleBackgroundView()
                        .ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 40)
                        
                        // プレミアムプロフィールエリア
                        let _ = refreshTrigger
                        if let user = getUser() {
                            premiumProfileCardView(user: user)
                        }
                        
                        // プレミアムタスクエリア
                        if let user = getUser() {
                            premiumTaskSectionView(user: user)
                        }
                        
                        Spacer().frame(height: 120) // タブナビゲーション分の余白
                    }
                }
                .background(Color.clear)
                .scrollIndicators(.hidden)
                .toolbar(.hidden, for: .navigationBar)
                
                // プレミアムタブナビゲーション（固定位置）
                VStack {
                    Spacer()
                    premiumTabNavigationView
                }
                }
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "TodoList":
                    TodoListView(navigationPath: $navigationPath)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    navigationPath.removeLast()
                                    // ホームに戻った時にデータを更新
                                    refreshData()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.7))
                                }
                            }
                        }
                case "Stats":
                    StatsView(navigationPath: $navigationPath)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    navigationPath.removeLast()
                                    refreshData()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.7))
                                }
                            }
                        }
                default:
                    EmptyView()
                }
            }
        }
        .navigationBarHidden(true)
        .overlay(
            // 経験値獲得スナックバー
            experienceSnackbarView
        )
        .overlay(
            // チュートリアルオーバーレイ
            TutorialOverlayView()
        )
        .onAppear {
            setupInitialUser()
            checkFirstTimeUser()
            checkAndResetRoutineTasks()
            refreshData()
            
            // チュートリアル初回起動判定
            tutorialManager.checkInitialState()
            
            // デバッグ情報出力
            print("🔍 Tutorial Debug Info:")
            print("  - hasSeenTutorial: \(UserDefaults.standard.bool(forKey: "hasSeenTutorial"))")
            print("  - tutorialManager.isActive: \(tutorialManager.isActive)")
            print("  - tutorialManager.currentStep: \(tutorialManager.currentStep)")
            print("  - tutorialManager.currentHighlight: \(String(describing: tutorialManager.currentHighlight))")
            
        }
        .fullScreenCover(isPresented: $showingTaskTutorial) {
            TaskTutorialView(isPresented: $showingTaskTutorial)
        }
        .fullScreenCover(isPresented: $showingStatsTutorial) {
            StatsTutorialView(isPresented: $showingStatsTutorial)
        }
        }
        .sheet(isPresented: $showingAddTodo) {
            AddTodoView()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshHomeData"))) { _ in
            refreshData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserLeveledUp"))) { notification in
            handleLevelUpNotification(notification)
        }
        .alert("職業昇格！", isPresented: $showingJobPromotionAlert) {
            Button("OK") { }
        } message: {
            VStack {
                Text("新しい職業に昇格しました！")
                Text("\(newJobName)")
                    .fontWeight(.bold)
                Text(newJobDescription)
                    .font(.caption)
            }
        }
        .overlay(
            // レベルアップモーダル（簡易版）
            Group {
                if showingLevelUpModal {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingLevelUpModal = false
                        }
                        .overlay(
                            SimpleLevelUpModalView(
                                statisticsDict: levelUpStatistics!,
                                onClose: {
                                    showingLevelUpModal = false
                                }
                            )
                        )
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: showingLevelUpModal)
                }
            }
        )
        .sheet(isPresented: $showingProfileModal) {
            ProfileSettingsModalView()
        }
    }
    
    private func getUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        return try? viewContext.fetch(request).first
    }
    
    // MARK: - Premium Design Components
    
    /// プレミアムダークゲーミング背景
    private var premiumBackgroundView: some View {
        ZStack {
            // メイン背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.sRGB, red: 0.04, green: 0.055, blue: 0.102, opacity: 1.0), // #0a0e1a
                    Color(.sRGB, red: 0.102, green: 0.102, blue: 0.18, opacity: 1.0), // #1a1a2e
                    Color(.sRGB, red: 0.176, green: 0.106, blue: 0.412, opacity: 1.0)  // #2d1b69
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 装飾的なグラデーション層
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.15),
                    Color.clear
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            .ignoresSafeArea()
        }
    }
    
    /// プレミアムプロフィールカード
    private func premiumProfileCardView(user: User) -> some View {
        VStack(spacing: 20) {
            // アバターとレベル情報
            HStack(spacing: 20) {
                // 装飾フレーム付きアバター
                ZStack {
                    // 外側の回転装飾フレーム
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: jobColorScheme(for: user).map { $0.opacity(0.8) },
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(rotationAngle))
                        .shadow(color: jobColorScheme(for: user)[0], radius: 10, x: 0, y: 0)
                    
                    // 内側の装飾リング
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 90, height: 90)
                    
                    // アバター画像
                    Image(avatarImage(for: user.currentAvatarType))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .onTapGesture {
                    showingProfileModal = true
                }
                
                // レベルと職業情報
                VStack(alignment: .leading, spacing: 12) {
                    // レベル表示（大型化）
                    HStack(alignment: .bottom, spacing: 8) {
                        Text("Lv.")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(user.level)")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: jobColorScheme(for: user)[0], radius: 8, x: 0, y: 0)
                    }
                    
                    // 職業名表示
                    if let currentJob = getCurrentJobForLevel(Int(user.level), user: user) {
                        Text(currentJob.name)
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                            .shadow(color: .white.opacity(0.3), radius: 3, x: 0, y: 0)
                    }
                }
                
                Spacer()
            }
            
            // 経験値バー（強化版）
            premiumExperienceBarView(user: user)
            
            // ステータス表示（革新的改良）
            premiumStatusGridView(user: user)
        }
        .padding(24)
        .background(premiumCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .onAppear {
            startRotationAnimation()
        }
    }
    
    /// プレミアム経験値バー
    private func premiumExperienceBarView(user: User) -> some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("経験値")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(jobColorScheme(for: user)[0])
                    Spacer()
                    Text(experienceText(for: user))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // 強化された経験値プログレスバー
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.black.opacity(0.6), .black.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(jobColorScheme(for: user)[0].opacity(0.3), lineWidth: 1)
                        )
                    
                    // 進行部分（キラキラエフェクト付き）
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: jobColorScheme(for: user),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(20, geometry.size.width * user.progressToNextLevel()), height: 12)
                            .shadow(color: jobColorScheme(for: user)[0], radius: 4, x: 0, y: 0)
                        
                        // キラキラエフェクト
                        if user.progressToNextLevel() > 0 {
                            HStack(spacing: 4) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Circle()
                                        .fill(.white.opacity(0.8))
                                        .frame(width: 2, height: 2)
                                        .scaleEffect(sparkleScale)
                                }
                            }
                            .offset(x: max(10, geometry.size.width * user.progressToNextLevel() - 20))
                        }
                    }
                }
            }
        }
        .frame(height: 40)
    }
    
    /// プレミアムステータスグリッド
    private func premiumStatusGridView(user: User) -> some View {
        let statusConfig = getStatusConfig()
        let userStats = [
            ("strength", Int(user.strength)),
            ("intelligence", Int(user.intelligence)),
            ("endurance", Int(user.endurance)),
            ("focus", Int(user.focus)),
            ("creativity", Int(user.creativity))
        ]
        
        let maxValue = userStats.map { $0.1 }.max() ?? 0
        
        return VStack(spacing: 12) {
            ForEach(Array(userStats.enumerated()), id: \.offset) { index, stat in
                let config = statusConfig[stat.0]!
                let isHighest = stat.1 == maxValue
                
                premiumStatusRowView(
                    icon: config.icon,
                    name: config.name,
                    value: stat.1,
                    maxValue: config.maxValue,
                    color: config.color,
                    isHighest: isHighest
                )
            }
        }
    }
    
    /// プレミアムステータス行
    private func premiumStatusRowView(
        icon: String,
        name: String,
        value: Int,
        maxValue: Int,
        color: Color,
        isHighest: Bool
    ) -> some View {
        HStack(spacing: 12) {
            // ステータス名（絵文字削除）
            Text(name)
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(.white)
                .frame(width: 60, alignment: .leading)
            
            // プログレスバー
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.4))
                    .frame(height: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 120 * CGFloat(value) / CGFloat(maxValue), height: 8)
                    .shadow(color: color, radius: isHighest ? 4 : 2)
                    .scaleEffect(isHighest ? pulseScale : 1.0)
            }
            .frame(width: 120)
            
            // 数値
            Text("\(value)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(isHighest ? color : .white)
                .shadow(color: isHighest ? color : .clear, radius: isHighest ? 3 : 0)
                .frame(width: 30, alignment: .trailing)
        }
    }
    
    /// プレミアムタスクセクション
    private func premiumTaskSectionView(user: User) -> some View {
        VStack(spacing: 16) {
            // セクションヘッダー
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(jobColorScheme(for: user)[0])
                    
                    Text("今日のミッション")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // 連続達成表示
                if true { // 仮で常に表示
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("3日連続")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            
            // タスクリストまたは推奨アクション
            premiumTaskListView(user: user)
        }
        .padding(24)
        .background(premiumCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    /// プレミアムタスクリスト
    private func premiumTaskListView(user: User) -> some View {
        let routineTasks = getRoutineTasks(for: user)
        
        if routineTasks.isEmpty {
            return AnyView(premiumEmptyTaskStateView(user: user))
        } else {
            return AnyView(
                VStack(spacing: 12) {
                    ForEach(Array(routineTasks.prefix(4).enumerated()), id: \.offset) { index, task in
                        premiumTaskRowView(task: task, user: user)
                    }
                    
                    if routineTasks.count > 4 {
                        HStack {
                            Text("他 \(routineTasks.count - 4) 件のタスク...")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                        }
                    }
                }
            )
        }
    }
    
    /// プレミアム空状態表示
    private func premiumEmptyTaskStateView(user: User) -> some View {
        VStack(spacing: 16) {
            // 推奨タスク提案
            VStack(spacing: 8) {
                Text("🔥 3日連続達成中！")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
                
                Text("今日は\(getRecommendedTaskType(for: user))向上のタスクがおすすめです")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // アクションボタン
            Button(action: {
                navigationPath.append("TodoList")
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("新しいタスクを追加")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: jobColorScheme(for: user),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: jobColorScheme(for: user)[0].opacity(0.5), radius: 8)
            }
        }
        .frame(minHeight: 100)
    }
    
    /// プレミアムタスク行
    private func premiumTaskRowView(task: TodoItem, user: User) -> some View {
        HStack(spacing: 12) {
            // 完了チェックボックス
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    toggleHomeTaskCompletion(task)
                }
            }) {
                ZStack {
                    Circle()
                        .fill(task.isCompleted ? jobColorScheme(for: user)[0] : .clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(
                                    task.isCompleted ? .clear : .white.opacity(0.5),
                                    lineWidth: 2
                                )
                        )
                    
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // タスク情報
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(task.isCompleted ? .white.opacity(0.6) : .white)
                    .strikethrough(task.isCompleted)
                
                if let taskType = TaskType(rawValue: task.taskType ?? "strength") {
                    HStack(spacing: 4) {
                        Text(getTaskTypeIcon(taskType))
                            .font(.system(size: 10))
                        Text(taskType.displayName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(getTaskTypeColorForHome(for: taskType).opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            // 経験値表示
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
                Text("+\(Int(task.experienceReward))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(task.isCompleted ? 0.2 : 0.4))
                .stroke(
                    task.isCompleted ? .green.opacity(0.3) : .white.opacity(0.1),
                    lineWidth: 1
                )
        )
    }
    
    /// プレミアムタブナビゲーション
    private var premiumTabNavigationView: some View {
        HStack(spacing: 0) {
            premiumTabButton(icon: "house.fill", title: "ホーム", isSelected: true) {
                // 現在のページ
            }
            
            premiumTabButton(icon: "list.bullet", title: "タスク", isSelected: false) {
                navigationPath.append("TodoList")
            }
            
            premiumTabButton(icon: "chart.bar", title: "統計", isSelected: false) {
                navigationPath.append("Stats")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            ZStack {
                // グラスモーフィズム背景
                RoundedRectangle(cornerRadius: 25)
                    .fill(.black.opacity(0.6))
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    /// プレミアムタブボタン
    private func premiumTabButton(
        icon: String,
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.1, green: 0.3, blue: 0.7), Color(red: 0.4, green: 0.2, blue: 0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .shadow(color: Color(red: 0.1, green: 0.3, blue: 0.7).opacity(0.5), radius: 8)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 18 : 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                        .shadow(color: isSelected ? .cyan : .clear, radius: isSelected ? 3 : 0)
                }
                
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PremiumButtonStyle())
    }
    
    // MARK: - Premium Design Helpers
    
    /// プレミアムカード背景
    private var premiumCardBackground: some View {
        ZStack {
            // メインのグラスモーフィズム背景
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.05))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
            
            // 内側のハイライト
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.1), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
    }
    
    /// 職業別カラースキーム
    private func jobColorScheme(for user: User) -> [Color] {
        guard let currentJob = getCurrentJobForLevel(Int(user.level), user: user) else {
            return [Color(red: 0.1, green: 0.3, blue: 0.7), Color(red: 0.4, green: 0.2, blue: 0.6)]
        }
        
        let dominantStat = getDominantStat(user: user)
        switch dominantStat {
        case .strength:
            return [.red, .orange]
        case .intelligence:
            return [.blue, .purple]
        case .endurance:
            return [.green, .mint]
        case .focus:
            return [.yellow, .orange]
        case .creativity:
            return [.pink, .purple]
        }
    }
    
    /// ステータス設定
    private func getStatusConfig() -> [String: (icon: String, name: String, color: Color, maxValue: Int)] {
        return [
            "strength": (icon: "", name: "筋力", color: .red, maxValue: 100),
            "intelligence": (icon: "", name: "知力", color: .blue, maxValue: 100),
            "endurance": (icon: "", name: "持久力", color: .green, maxValue: 100),
            "focus": (icon: "", name: "集中力", color: .yellow, maxValue: 100),
            "creativity": (icon: "", name: "創造力", color: .orange, maxValue: 100)
        ]
    }
    
    /// タスクタイプアイコン
    private func getTaskTypeIcon(_ taskType: TaskType) -> String {
        switch taskType {
        case .strength: return "💪"
        case .focus: return "🎯"
        case .continuity: return "🏃‍♂️"
        case .intelligence: return "🧠"
        }
    }
    
    /// 推奨タスクタイプ
    private func getRecommendedTaskType(for user: User) -> String {
        let stats = [
            (name: "筋力", value: user.strength),
            (name: "知力", value: user.intelligence),
            (name: "持久力", value: user.endurance),
            (name: "集中力", value: user.focus),
            (name: "創造力", value: user.creativity)
        ]
        
        let minStat = stats.min(by: { $0.value < $1.value })
        return minStat?.name ?? "筋力"
    }
    
    /// 回転アニメーション開始
    private func startRotationAnimation() {
        withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            sparkleScale = 1.2
        }
    }
    
    private func refreshData() {
        withAnimation(.easeInOut(duration: 0.3)) {
            refreshTrigger.toggle()
            // Core Dataのcontextを更新
            viewContext.refreshAllObjects()
        }
    }
    
    private func checkAndResetRoutineTasks() {
        let lastResetDateKey = "lastRoutineTaskResetDate"
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 前回のリセット日を取得
        let lastResetDate = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date
        let lastResetDateStart = lastResetDate.map { calendar.startOfDay(for: $0) }
        
        // 今日まだリセットしていない場合にリセット実行
        if lastResetDateStart != today {
            resetRoutineTasks()
            UserDefaults.standard.set(today, forKey: lastResetDateKey)
        }
    }
    
    private func resetRoutineTasks() {
        guard let user = getUser() else { return }
        
        let routineTasks = (user.todos?.allObjects as? [TodoItem])?.filter { $0.isRoutineTask } ?? []
        
        for task in routineTasks {
            if task.isCompleted {
                task.isCompleted = false
                task.completedAt = nil
            }
        }
        
        do {
            try viewContext.save()
            print("✅ Routine tasks reset successfully")
        } catch {
            print("❌ Failed to reset routine tasks: \(error)")
        }
    }
    
    private func setupInitialUser() {
        let userService = UserService(context: viewContext)
        let user = userService.getOrCreateUser()
        
        // 検証用: フラグを一度クリアしてテストできるようにする
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "shouldResetForTesting") {
            UserDefaults.standard.removeObject(forKey: "hasUpdatedForLevelUpTesting")
            UserDefaults.standard.set(false, forKey: "shouldResetForTesting")
        }
        #endif
        
        // ユーザーをレベル9に設定（検証用）
        updateUserToLevel9(user: user)
        
        // 既存タスクのタイトルクリーンアップ（一度だけ実行）
        cleanupTaskTitles()
    }
    
    private func updateUserToLevel9(user: User) {
        // 検証用: アプリが初回起動または端末再起動後の場合のみリセット
        let hasResetThisSession = UserDefaults.standard.bool(forKey: "hasResetUserThisSession")
        
        if hasResetThisSession {
            print("✅ User already reset this session - skipping")
            return
        }
        
        // レベル9（120EXP）に設定して、次のタスク完了でレベル10になるようにする
        let experienceForLevel9 = ExperienceService.shared.totalExperienceRequiredForLevel(9)
        
        // 既にレベル9で120EXPの場合でも、セッションフラグが立っていなければリセットは初回
        if user.level == 9 && user.experience == Int32(experienceForLevel9) {
            print("✅ Setting session flag - User at Level 9 (120EXP)")
            UserDefaults.standard.set(true, forKey: "hasResetUserThisSession")
            return
        }
        
        user.experience = Int32(experienceForLevel9) // 120EXP
        user.level = 9
        
        // ステータスもレベル9相当に調整
        user.strength = 15
        user.focus = 12
        user.intelligence = 18
        user.creativity = 10
        user.endurance = 14
        
        do {
            try viewContext.save()
            // セッションフラグを設定して、このセッション中は再リセットしない
            UserDefaults.standard.set(true, forKey: "hasResetUserThisSession")
            print("✅ User reset to Level 9 with \(experienceForLevel9) EXP for testing level-up modal")
        } catch {
            print("❌ Failed to reset user for testing: \(error)")
        }
    }
    
    private func cleanupTaskTitles() {
        // 既にクリーンアップ済みかチェック
        let hasCleanedUp = UserDefaults.standard.bool(forKey: "hasCleanedUpTaskTitles")
        if hasCleanedUp {
            return
        }
        
        // 全てのタスクを取得
        let request: NSFetchRequest<TodoItem> = TodoItem.fetchRequest()
        
        do {
            let tasks = try viewContext.fetch(request)
            var hasChanges = false
            
            for task in tasks {
                guard let currentTitle = task.title else { continue }
                
                // （）を含む場合のみ処理
                if currentTitle.contains("（") && currentTitle.contains("）") {
                    // 正規表現で（○○）部分を削除
                    let cleanedTitle = currentTitle.replacingOccurrences(
                        of: "\\s*（[^）]*）", 
                        with: "", 
                        options: .regularExpression
                    ).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    
                    if !cleanedTitle.isEmpty && cleanedTitle != currentTitle {
                        task.title = cleanedTitle
                        hasChanges = true
                    }
                }
            }
            
            // 変更があった場合のみ保存
            if hasChanges {
                try viewContext.save()
            }
            
            // クリーンアップ完了フラグを設定
            UserDefaults.standard.set(true, forKey: "hasCleanedUpTaskTitles")
            
        } catch {
            print("❌ Failed to cleanup task titles: \(error)")
        }
    }
    
    private func checkFirstTimeUser() {
        let hasCompletedGenderSelection = UserDefaults.standard.bool(forKey: "hasCompletedGenderSelection")
        let hasCompletedTaskTutorial = UserDefaults.standard.bool(forKey: "hasCompletedTaskTutorial")
        let hasCompletedStatsTutorial = UserDefaults.standard.bool(forKey: "hasCompletedStatsTutorial")
        
        if !hasCompletedGenderSelection {
            showingGenderSelection = true
        } else if !hasCompletedTaskTutorial {
            // 性別選択は完了しているが、タスクチュートリアルが未完了
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingTaskTutorial = true
            }
        } else if !hasCompletedStatsTutorial {
            // タスクチュートリアルは完了しているが、ステータスチュートリアルが未完了
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingStatsTutorial = true
            }
        }
    }
    
    private func avatarImage(for avatarType: String?) -> String {
        guard let user = getUser() else { return "boy1" }
        
        // レベル5未満は基本アバター
        if user.level < 5 {
            return "boy1"
        }
        
        // 動的なジョブシステムを使用してアバターを決定
        if let currentJob = getCurrentJobForLevel(Int(user.level), user: user) {
            return currentJob.avatarImageName
        }
        
        // フォールバック: レガシー対応
        switch avatarType {
        case "starter_male":
            return "boy1"
        case "starter_female":
            return "girl1"
        case "wizard_male":
            return "wizard_male"
        case "wizard_female":
            return "wizard_female"
        case "warrior_male":
            return "warrior_male"
        case "warrior_female":
            return "warrior_female"
        case "guard":
            return "guard"
        case "thief_male":
            return "thief_male"
        case "thief_female":
            return "thief_female"
        case "archmage_male":
            return "archmage_male"
        case "archmage_female":
            return "archmage_female"
        case "knight_male":
            return "knight_male"
        case "knight_female":
            return "knight_female"
        case "warrior":
            return user.level >= 26 ? "knight_male" : "warrior_male"
        case "mage":
            return user.level >= 26 ? "archmage_male" : "wizard_male"
        case "assassin":
            return "thief_female"
        case "paladin":
            return "knight_male"
        case "archmage":
            return "archmage_male"
        default:
            return "boy1"
        }
    }
    
    private func avatarName(for avatarType: String?) -> String {
        switch avatarType {
        // 基本職
        case "starter_male", "starter_female":
            return "新米冒険者"
            
        // 第1転職
        case "wizard_male", "wizard_female":
            return "魔法使い"
        case "warrior_male", "warrior_female":
            return "戦士"
        case "guard":
            return "護衛"
        case "thief_male", "thief_female":
            return "盗賊"
            
        // 第2転職  
        case "archmage_male", "archmage_female":
            return "大魔法使い"
        case "knight_male", "knight_female":
            return "騎士"
            
        // レガシー対応
        case "warrior":
            return "戦士"
        case "mage":
            return "魔法使い"
        case "assassin":
            return "暗殺者"
        case "paladin":
            return "パラディン"
        case "archmage":
            return "大魔法使い"
            
        default:
            return "冒険者"
        }
    }
    
    private func experienceText(for user: User) -> String {
        let currentLevel = Int(user.level)
        let currentExp = Int(user.experience)
        let expForCurrentLevel = ExperienceService.shared.totalExperienceRequiredForLevel(currentLevel)
        let expForNextLevel = ExperienceService.shared.totalExperienceRequiredForLevel(currentLevel + 1)
        let expInCurrentLevel = currentExp - expForCurrentLevel
        let expRequiredForNextLevel = expForNextLevel - expForCurrentLevel
        
        return "\(expInCurrentLevel)/\(expRequiredForNextLevel) EXP"
    }
    
    private var routineTasksList: some View {
        VStack(alignment: .leading, spacing: 8) {
            // refreshTriggerに依存してデータを再取得
            let _ = refreshTrigger
            if let user = getUser() {
                let routineTasks = getRoutineTasks(for: user)
                
                if routineTasks.isEmpty {
                    HStack {
                        Text("ルーティンタスクはありません")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .frame(height: 60)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(routineTasks.prefix(5)), id: \.self) { task in
                            HStack(spacing: 15) {
                                // 完了チェックボックス
                                Button(action: {
                                    toggleHomeTaskCompletion(task)
                                }) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(task.isCompleted ? .green : .gray)
                                }
                                
                                // タスク情報
                                VStack(alignment: .leading, spacing: 4) {
                                    // タスクタイトル
                                    Text(task.title ?? "")
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundColor(task.isCompleted ? .gray : .white)
                                        .strikethrough(task.isCompleted)
                                    
                                    // タスクタイプ
                                    if let taskType = TaskType(rawValue: task.taskType ?? "strength") {
                                        Text(taskType.displayName)
                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                            .foregroundColor(getTaskTypeColorForHome(for: taskType))
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(homeTaskCardBackground(task))
                        }
                        
                        if routineTasks.count > 5 {
                            HStack {
                                Text("他 \(routineTasks.count - 5) 件...")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 300, alignment: .top)
    }
    
    private func getRoutineTasks(for user: User) -> [TodoItem] {
        return (user.todos?.allObjects as? [TodoItem])?.filter { task in
            return task.isRoutineTask
        }.sorted { task1, task2 in
            // 未完了タスクを上に、完了済みタスクを下に
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted && task2.isCompleted
            }
            // 作成日時で降順ソート（新しいものが上）
            guard let date1 = task1.createdAt, let date2 = task2.createdAt else { return false }
            return date1 > date2
        } ?? []
    }

    @ViewBuilder
    private func statusItem(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 60, alignment: .leading)
            Text("\(value)")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 30, alignment: .trailing)
        }
    }
    
    @ViewBuilder
    private func statBar(value: Int, maxValue: Int, color: Color) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
                .frame(height: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
            
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 120 * CGFloat(min(value, maxValue)) / CGFloat(maxValue), height: 8)
                .shadow(color: color, radius: 2)
        }
        .frame(width: 120)
    }
    
    @ViewBuilder
    private func tabBarButton(
        icon: String,
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .cyan : .gray)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? .cyan : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
    
    private func toggleHomeTaskCompletion(_ todo: TodoItem) {
        withAnimation(.easeInOut(duration: 0.3)) {
            let wasCompleted = todo.isCompleted
            todo.isCompleted.toggle()
            
            // 完了時刻の設定
            if todo.isCompleted {
                todo.completedAt = Date()
            } else {
                todo.completedAt = nil
            }
            
            if let user = getUser() {
                // 完了時にユーザーに経験値を付与
                if !wasCompleted && todo.isCompleted {
                    let previousLevel = Int(user.level)
                    
                    // 経験値を追加
                    user.addExperience(Int(todo.experienceReward))
                    
                    // タスクタイプに応じてステータスを成長
                    if let taskTypeString = todo.taskType,
                       let taskType = TaskType(rawValue: taskTypeString) {
                        user.completeTask(taskType: taskType)
                    }
                    
                    // レベルアップによる職業変更チェック
                    let jobPromotionResult = ExperienceService.shared.handleLevelUpJobPromotion(user: user, previousLevel: previousLevel)
                    if jobPromotionResult.jobChanged, let jobName = jobPromotionResult.jobName {
                        // 職業昇格通知を表示
                        newJobName = jobName
                        newJobDescription = "新しい職業に昇格しました！"
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showingJobPromotionAlert = true
                        }
                    }
                    
                    // ルーティンタスク完了時のスナックバー表示
                    if todo.isRoutineTask {
                        earnedExperience = Int(todo.experienceReward)
                        showExperienceSnackbar()
                    }
                }
                // 完了解除時に経験値を減算
                else if wasCompleted && !todo.isCompleted {
                    // 経験値を減算（負の数にならないように制限）
                    let currentExp = Int(user.experience)
                    let newExp = max(0, currentExp - Int(todo.experienceReward))
                    user.experience = Int32(newExp)
                    
                    // レベルを再計算
                    let newLevel = ExperienceService.shared.calculateLevel(from: newExp)
                    user.level = Int32(newLevel)
                    
                    // ステータスを減算（0以下にならないように制限）
                    if let taskTypeString = todo.taskType,
                       let taskType = TaskType(rawValue: taskTypeString) {
                        switch taskType {
                        case .strength:
                            user.strength = max(0, user.strength - 1)
                        case .focus:
                            user.focus = max(0, user.focus - 1)
                        case .intelligence:
                            user.intelligence = max(0, user.intelligence - 1)
                        case .continuity:
                            user.endurance = max(0, user.endurance - 1)
                        }
                    }
                }
            }
            
            do {
                try viewContext.save()
                // データの最新状態を反映
                refreshData()
            } catch {
                print("❌ Failed to save: \(error)")
            }
        }
    }
    
    private func homeTaskCardBackground(_ todo: TodoItem) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.black.opacity(todo.isCompleted ? 0.2 : 0.4))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        todo.isCompleted ? 
                        Color.green.opacity(0.2) : 
                        Color.cyan.opacity(0.3),
                        lineWidth: 1
                    )
            )
    }
    
    private func getTaskTypeColorForHome(for taskType: TaskType) -> Color {
        switch taskType {
        case .strength:
            return .red
        case .focus:
            return .orange
        case .intelligence:
            return Color(red: 0.3, green: 0.1, blue: 0.5)
        case .continuity:
            return .green
        }
    }
    
    @ViewBuilder
    private func rpgStatRow(label: String, value: Int, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 30, alignment: .leading)
            
            Text("\(value)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 40, alignment: .trailing)
        }
    }
    
    // MARK: - Game Icon Button Components
    
    enum ButtonSize {
        case large, medium, small
        
        var iconSize: CGFloat {
            switch self {
            case .large: return 32
            case .medium: return 24
            case .small: return 20
            }
        }
        
        var containerSize: CGFloat {
            switch self {
            case .large: return 90
            case .medium: return 70
            case .small: return 50
            }
        }
        
        var titleFont: Font {
            switch self {
            case .large: return .system(size: 14, weight: .bold, design: .monospaced)
            case .medium: return .system(size: 12, weight: .bold, design: .monospaced)
            case .small: return .system(size: 10, weight: .bold, design: .monospaced)
            }
        }
        
        var subtitleFont: Font {
            switch self {
            case .large: return .system(size: 10, weight: .medium, design: .monospaced)
            case .medium: return .system(size: 9, weight: .medium, design: .monospaced)
            case .small: return .system(size: 8, weight: .medium, design: .monospaced)
            }
        }
    }
    
    @ViewBuilder
    private func gameIconButton(
        icon: String,
        title: String,
        subtitle: String,
        gradientColors: [Color],
        shadowColor: Color,
        size: ButtonSize,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // アイコン部分
                ZStack {
                    // 外側のネオングロー
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    shadowColor.opacity(0.3),
                                    shadowColor.opacity(0.1),
                                    .clear
                                ]),
                                center: .center,
                                startRadius: size.containerSize * 0.3,
                                endRadius: size.containerSize * 0.6
                            )
                        )
                        .frame(width: size.containerSize + 20, height: size.containerSize + 20)
                    
                    // メインの円形背景
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size.containerSize, height: size.containerSize)
                        .shadow(color: shadowColor.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    // 内側のハイライト
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(0.3),
                                    .white.opacity(0.1),
                                    .clear
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: size.containerSize * 0.5
                            )
                        )
                        .frame(width: size.containerSize, height: size.containerSize)
                    
                    // アイコン
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                }
                
                // テキスト部分
                VStack(spacing: 2) {
                    Text(title)
                        .font(size.titleFont)
                        .foregroundColor(.white)
                        .shadow(color: shadowColor.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    Text(subtitle)
                        .font(size.subtitleFont)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: size.containerSize + 20)
            }
        }
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
        .onTapGesture {
            // タップエフェクト
            withAnimation(.easeInOut(duration: 0.1)) {
                // ここで軽いハプティックフィードバックを追加することも可能
            }
        }
    }
    
    private var experienceSnackbarView: some View {
        VStack {
            Spacer()
            
            if showingExperienceSnackbar {
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    Text("+\(earnedExperience) EXP獲得！")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                        )
                        .shadow(color: .yellow.opacity(0.2), radius: 8)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 120) // ボトムナビ分の余白
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingExperienceSnackbar)
    }
    
    private func showExperienceSnackbar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingExperienceSnackbar = true
        }
        
        // 2秒後に自動で非表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingExperienceSnackbar = false
            }
        }
    }
    
    // MARK: - Level-Up Modal Handlers
    
    private func handleLevelUpNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let newLevel = userInfo["newLevel"] as? Int else {
            print("❌ Level up notification missing level info")
            return
        }
        
        guard let user = getUser() else {
            print("❌ Cannot get user for level up notification")
            return
        }
        
        // 現在のアバター（修正されたロジック使用）
        let currentAvatarImage = avatarImage(for: user.currentAvatarType)
        
        // 簡易的なレベルアップ統計辞書を作成
        let statistics: [String: Any] = [
            "daysSinceFirstTask": newLevel * 2,
            "mostCompletedTaskType": "strength",
            "currentLevel": newLevel,
            "jobTitle": "レベル\(newLevel)職業",
            "previousJobTitle": newLevel > 5 ? "レベル\(newLevel-5)職業" : nil as String?,
            "improvementMetric": "順調な成長",
            "consecutiveDays": min(newLevel, 14),
            "totalTasksCompleted": newLevel * 3,
            "completionRate": 85.0,
            "averageCompletionTime": 1.2,
            "jobCategory": "fighter",
            "isFirstJobAcquisition": newLevel == 5,
            "isJobEvolution": newLevel >= 10,
            "isConsecutiveStreak": newLevel >= 7,
            "currentAvatarImage": currentAvatarImage,
            "previousAvatarImage": newLevel > 5 ? "boy1" : nil as String?
        ]
        
        print("✅ Level up notification received: Level \(statistics["currentLevel"] ?? "Unknown")")
        
        // 既存の職業昇格アラートよりもレベルアップモーダルを優先
        showingJobPromotionAlert = false
        
        // レベルアップモーダルを表示
        levelUpStatistics = statistics
        
        // ハプティックフィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // 少しの遅延を加えて、他のアニメーションと競合しないようにする
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingLevelUpModal = true
            }
        }
    }
    
    private func handleLevelUpAction(_ action: LevelUpAction) {
        switch action {
        case .setGoal:
            // 目標設定は今後実装予定
            print("目標設定機能は開発中です")
            
        case .saveRecord:
            // 記録保存処理
            saveAchievementRecord()
            
        case .continueJourney:
            // 継続 - 何もしない（モーダルは既にdismissされる）
            break
            
        case .shareAchievement:
            // 成果共有処理
            shareAchievement()
        }
    }
    
    private func saveAchievementRecord() {
        guard let statistics = levelUpStatistics else { return }
        
        // 成果記録をUserDefaultsに保存
        let currentLevel = statistics["currentLevel"] as? Int ?? 1
        let achievementKey = "achievement_level_\(currentLevel)"
        let achievementData: [String: Any] = [
            "level": currentLevel,
            "jobTitle": statistics["jobTitle"] as? String ?? "冒険者",
            "achievedAt": Date(),
            "daysSinceFirst": statistics["daysSinceFirstTask"] as? Int ?? 1,
            "totalTasks": statistics["totalTasksCompleted"] as? Int ?? 1
        ]
        
        UserDefaults.standard.set(achievementData, forKey: achievementKey)
        
        // 成功のハプティックフィードバック
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
    }
    
    private func shareAchievement() {
        guard let statistics = levelUpStatistics else { return }
        
        let currentLevel = statistics["currentLevel"] as? Int ?? 1
        let jobTitle = statistics["jobTitle"] as? String ?? "冒険者"
        let daysSinceFirstTask = statistics["daysSinceFirstTask"] as? Int ?? 1
        let totalTasksCompleted = statistics["totalTasksCompleted"] as? Int ?? 1
        let mostCompletedTaskType = statistics["mostCompletedTaskType"] as? String ?? "筋力"
        
        let shareText = """
        🎮 レベルアップ達成！
        
        レベル \(currentLevel) 「\(jobTitle)」に到達しました！
        
        📊 達成データ:
        • 継続日数: \(daysSinceFirstTask)日
        • 完了タスク数: \(totalTasksCompleted)個
        • 主な成長分野: \(mostCompletedTaskType)
        
        #レベルアップ #継続力 #成長記録
        """
        
        // ActivityViewControllerを使用した共有
        // 実装は簡略化（実際のアプリでは適切なActivityViewControllerの実装が必要）
        print("共有メッセージ: \(shareText)")
        
        // クリップボードにコピー
        UIPasteboard.general.string = shareText
        
        // フィードバック
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
    }
    
    /// レベルに応じたアバター画像名を取得
    private func getAvatarImageName(for level: Int) -> String {
        guard let user = getUser() else { return "boy1" }
        
        // 動的なジョブシステムを使用
        if let currentJob = getCurrentJobForLevel(level, user: user) {
            return currentJob.avatarImageName
        }
        
        // フォールバック
        switch level {
        case 1...4:
            return "boy1"
        case 5...9:
            return "wizard_male"
        case 10...14:
            return "warrior_male"
        case 15...19:
            return "knight_male"
        case 20...29:
            return "archmage_male"
        default:
            return "archmage_male"
        }
    }
    
    /// ExperienceServiceと同じジョブ決定ロジック
    private func getCurrentJobForLevel(_ level: Int, user: User) -> (name: String, avatarImageName: String)? {
        let dominantStat = getDominantStat(user: user)
        
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
                return getCurrentJobForLevel(closestLevel, user: user)
            }
            return nil
        }
    }
    
    private enum StatType {
        case strength, intelligence, endurance, focus, creativity
    }
    
    private func getDominantStat(user: User) -> StatType {
        let stats = [
            (value: Int(user.strength), type: StatType.strength),
            (value: Int(user.intelligence), type: StatType.intelligence),
            (value: Int(user.endurance), type: StatType.endurance),
            (value: Int(user.focus), type: StatType.focus),
            (value: Int(user.creativity), type: StatType.creativity)
        ]
        
        return stats.max(by: { $0.value < $1.value })?.type ?? .strength
    }
    
}

// MARK: - Level-Up Modal Content View

struct SimpleLevelUpModalView: View {
    let statisticsDict: [String: Any]
    let onClose: () -> Void
    
    @State private var showContent = false
    
    private var currentLevel: Int {
        return statisticsDict["currentLevel"] as? Int ?? 1
    }
    
    private var jobTitle: String {
        return statisticsDict["jobTitle"] as? String ?? "冒険者"
    }
    
    private var currentAvatarImage: String {
        return statisticsDict["currentAvatarImage"] as? String ?? "boy1"
    }
    
    private var daysSinceFirstTask: Int {
        return statisticsDict["daysSinceFirstTask"] as? Int ?? 1
    }
    
    private var totalTasksCompleted: Int {
        return statisticsDict["totalTasksCompleted"] as? Int ?? 1
    }
    
    private var consecutiveDays: Int {
        return statisticsDict["consecutiveDays"] as? Int ?? 1
    }
    
    var body: some View {
        ZStack {
            // ダークバックグラウンド
            LinearGradient(
                colors: [
                    Color.black,
                    Color.cyan.opacity(0.3),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // メインコンテンツ
            VStack(spacing: 24) {
                // アバター
                Image(currentAvatarImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 0.1, green: 0.3, blue: 0.7), Color(red: 0.4, green: 0.2, blue: 0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                    )
                    .shadow(color: .cyan, radius: 15)
                
                // タイトル
                VStack(spacing: 8) {
                    Text("新たな役職に進化")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .cyan, radius: 5)
                    
                    Text("Level \(currentLevel)")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(.cyan)
                        .shadow(color: .cyan, radius: 10)
                }
                
                // メッセージ
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("\(daysSinceFirstTask)日間のタスク実行で")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        
                        Text(jobTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [.cyan.opacity(0.3), .purple.opacity(0.3)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .stroke(.cyan.opacity(0.6), lineWidth: 2)
                            )
                            .shadow(color: Color(red: 0.1, green: 0.3, blue: 0.7).opacity(0.5), radius: 8)
                        
                        Text("に到達。")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    
                    // 統計情報
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text("継続日数")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(consecutiveDays)日")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.cyan)
                        }
                        
                        VStack(spacing: 4) {
                            Text("完了タスク")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(totalTasksCompleted)個")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.cyan)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.4))
                            .stroke(.cyan.opacity(0.3), lineWidth: 1)
                    )
                    
                    Text("\(currentLevel + 5)Lvまで継続してみましょう")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.6), value: showContent)
                
                // 閉じるボタン
                Button(action: onClose) {
                    Text("閉じる")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .cyan.opacity(0.5), radius: 10)
                }
                .scaleEffect(showContent ? 1.0 : 0.8)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showContent)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showContent = true
                }
            }
        }
    }
}

// MARK: - Level-Up Action Enum

enum LevelUpAction: String, CaseIterable {
    case setGoal = "set_goal"
    case saveRecord = "save_record"
    case continueJourney = "continue_journey"
    case shareAchievement = "share_achievement"
    
    var displayText: String {
        switch self {
        case .setGoal: return "目標を設定"
        case .saveRecord: return "記録を保存"
        case .continueJourney: return "続行"
        case .shareAchievement: return "成果を共有"
        }
    }
}


struct ProfileSettingsModalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var userName = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.sRGB, red: 0.04, green: 0.055, blue: 0.102, opacity: 1.0),
                        Color(.sRGB, red: 0.102, green: 0.102, blue: 0.18, opacity: 1.0),
                        Color(.sRGB, red: 0.176, green: 0.106, blue: 0.412, opacity: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    if let user = getUser() {
                        VStack(spacing: 20) {
                            Spacer().frame(height: 20)
                            
                            // キャラクターアバター
                            let jobInfo = getCurrentJobForLevel(Int(user.level), user: user)
                            
                            ZStack {
                                if let avatarImageName = jobInfo?.avatarImageName {
                                    AsyncImage(url: Bundle.main.url(forResource: avatarImageName, withExtension: "png")) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                } else {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.cyan, .blue]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.2), lineWidth: 3)
                            )
                            .shadow(color: .cyan.opacity(0.3), radius: 10)
                            
                            // ユーザー名編集エリア（鉛筆ボタンなし）
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ユーザー名")
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                TextField("ユーザー名を入力", text: $userName)
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.black.opacity(0.4))
                                            .stroke(.cyan.opacity(0.3), lineWidth: 1)
                                    )
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.horizontal, 20)
                            
                            // 職業表示エリア（テキストのみ）
                            VStack(alignment: .leading, spacing: 12) {
                                Text("職業")
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                Text(getCurrentJobName(for: user))
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.black.opacity(0.2))
                                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer()
                            
                            // 保存ボタンのみ
                            Button("保存") {
                                saveProfile(user: user)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.cyan, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
        .onAppear {
            if let user = getUser() {
                userName = user.userName ?? ""
            }
        }
        .alert("プロフィールを更新しました", isPresented: $showingAlert) {
            Button("OK") {
                dismiss()
            }
        }
    }
    
    private func getUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        return try? viewContext.fetch(request).first
    }
    
    private func saveProfile(user: User) {
        user.name = userName
        
        do {
            try viewContext.save()
            showingAlert = true
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
    
    private func getCurrentJobName(for user: User) -> String {
        let level = Int(user.level)
        let dominantStat = getDominantStatForProfile(user: user)
        
        switch (dominantStat, level) {
        case (.strength, 1...5): return "見習い戦士"
        case (.strength, 6...10): return "戦士"
        case (.strength, 11...20): return "上級戦士"
        case (.strength, 21...): return "戦士長"
            
        case (.intelligence, 1...5): return "見習い魔法使い"
        case (.intelligence, 6...10): return "魔法使い"
        case (.intelligence, 11...20): return "上級魔法使い"
        case (.intelligence, 21...): return "大魔法使い"
            
        case (.focus, 1...5): return "見習い盗賊"
        case (.focus, 6...10): return "盗賊"
        case (.focus, 11...20): return "上級盗賊"
        case (.focus, 21...): return "盗賊団長"
            
        case (.continuity, 1...5): return "見習い僧侶"
        case (.continuity, 6...10): return "僧侶"
        case (.continuity, 11...20): return "上級僧侶"
        case (.continuity, 21...): return "大僧正"
            
        default: return "冒険者"
        }
    }
    
    private enum ProfileStatType {
        case strength, intelligence, focus, continuity
    }
    
    private func getDominantStatForProfile(user: User) -> ProfileStatType {
        let stats: [(type: ProfileStatType, value: Int32)] = [
            (.strength, user.strength),
            (.intelligence, user.intelligence),
            (.focus, user.focus),
            (.continuity, user.endurance)
        ]
        
        return stats.max(by: { $0.value < $1.value })?.type ?? .strength
    }
    
    private func getCurrentJobForLevel(_ level: Int, user: User) -> (name: String, avatarImageName: String)? {
        let dominantStat = getDominantStatForProfile(user: user)
        
        switch (dominantStat, level) {
        // ファイター系 (筋力特化)
        case (.strength, 5): return (name: "見習い戦士", avatarImageName: "warrior_male")
        case (.strength, 10): return (name: "戦士", avatarImageName: "warrior_male")
        case (.strength, 15): return (name: "剣士", avatarImageName: "warrior_female")
        case (.strength, 20): return (name: "騎士", avatarImageName: "knight_male")
        case (.strength, 30): return (name: "パラディン", avatarImageName: "knight_male")
        case (.strength, 50): return (name: "聖騎士", avatarImageName: "knight_female")
        
        // メイジ系 (知力特化)
        case (.intelligence, 5): return (name: "見習い魔法使い", avatarImageName: "mage_male")
        case (.intelligence, 10): return (name: "魔法使い", avatarImageName: "mage_male")
        case (.intelligence, 15): return (name: "上級魔法使い", avatarImageName: "mage_female")
        case (.intelligence, 20): return (name: "賢者", avatarImageName: "sage_male")
        case (.intelligence, 30): return (name: "大賢者", avatarImageName: "sage_male")
        case (.intelligence, 50): return (name: "魔導師", avatarImageName: "sage_female")
        
        // シーフ系 (集中力特化)
        case (.focus, 5): return (name: "見習い盗賊", avatarImageName: "thief_male")
        case (.focus, 10): return (name: "盗賊", avatarImageName: "thief_male")
        case (.focus, 15): return (name: "上級盗賊", avatarImageName: "thief_female")
        case (.focus, 20): return (name: "アサシン", avatarImageName: "assassin_male")
        case (.focus, 30): return (name: "影の達人", avatarImageName: "assassin_male")
        case (.focus, 50): return (name: "暗殺王", avatarImageName: "assassin_female")
        
        // 持久力系は創造性と統合
        case (.continuity, _):
            switch level {
            case 5: return (name: "見習い僧侶", avatarImageName: "priest_male")
            case 10: return (name: "僧侶", avatarImageName: "priest_male")
            case 15: return (name: "上級僧侶", avatarImageName: "priest_female")
            case 20: return (name: "司祭", avatarImageName: "bishop_male")
            case 30: return (name: "大司祭", avatarImageName: "bishop_male")
            case 50: return (name: "教皇", avatarImageName: "bishop_female")
            default: return (name: "冒険者", avatarImageName: "boy1")
            }
        
        default:
            return (name: "冒険者", avatarImageName: "boy1")
        }
    }
}

struct ThemeSettingsView: View {
    @Binding var navigationPath: NavigationPath
    @State private var selectedTheme = "ダーク"
    
    let themes = ["ダーク", "ライト", "システム"]
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.sRGB, red: 0.04, green: 0.055, blue: 0.102, opacity: 1.0),
                    Color(.sRGB, red: 0.102, green: 0.102, blue: 0.18, opacity: 1.0),
                    Color(.sRGB, red: 0.176, green: 0.106, blue: 0.412, opacity: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // ヘッダー
                Text("テーマ設定")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                // テーマ選択
                VStack(spacing: 12) {
                    ForEach(themes, id: \.self) { theme in
                        Button(action: {
                            selectedTheme = theme
                        }) {
                            HStack {
                                Text(theme)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Spacer()
                                
                                if selectedTheme == theme {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.cyan)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.3))
                                    .stroke(selectedTheme == theme ? .cyan : .gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // ボタンエリア
                HStack(spacing: 16) {
                    // 戻るボタン（navigationPath.removeLast()使用）
                    Button("戻る") {
                        navigationPath.removeLast()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    // 保存ボタン
                    Button("保存") {
                        // 保存処理後に前の画面に戻る
                        saveTheme()
                        navigationPath.removeLast()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.cyan, .blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
    }
    
    private func saveTheme() {
        // テーマ保存処理（実装例）
        UserDefaults.standard.set(selectedTheme, forKey: "selectedTheme")
        print("テーマを保存しました: \(selectedTheme)")
    }
}

struct ExperienceSettingsView: View {
    var body: some View {
        Text("経験値表示設定（開発中）")
            .foregroundColor(.white)
    }
}

struct LevelUpNotificationView: View {
    var body: some View {
        Text("レベルアップ通知（開発中）")
            .foregroundColor(.white)
    }
}

struct AchievementSettingsView: View {
    var body: some View {
        Text("実績・バッジ表示（開発中）")
            .foregroundColor(.white)
    }
}

struct GoalSettingsView: View {
    var body: some View {
        Text("目標設定（開発中）")
            .foregroundColor(.white)
    }
}

struct CategoryManagementView: View {
    var body: some View {
        Text("カテゴリ管理（開発中）")
            .foregroundColor(.white)
    }
}

struct CompletedTaskSettingsView: View {
    var body: some View {
        Text("完了タスクの表示期間（開発中）")
            .foregroundColor(.white)
    }
}

struct AppInfoView: View {
    var body: some View {
        Text("アプリ情報（開発中）")
            .foregroundColor(.white)
    }
}

struct FeedbackView: View {
    var body: some View {
        Text("フィードバック（開発中）")
            .foregroundColor(.white)
    }
}

struct DataResetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingResetAlert = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("データリセット")
                    .font(.title)
                    .foregroundColor(.white)
                
                Button("レベル9にリセット（レベル10テスト用）") {
                    showingResetAlert = true
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .alert("レベルリセット", isPresented: $showingResetAlert) {
            Button("リセットする") {
                resetUserForTesting()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("ユーザーレベルをレベル9（120EXP）にリセットします。次のタスク完了でレベル10になり、モーダルが表示されます。")
        }
    }
    
    private func resetUserForTesting() {
        let request: NSFetchRequest<User> = User.fetchRequest()
        
        do {
            let users = try viewContext.fetch(request)
            if let user = users.first {
                // レベル9（120EXP）に設定
                user.experience = 120
                user.level = 9
                user.strength = 15
                user.focus = 12
                user.intelligence = 18
                user.creativity = 10
                user.endurance = 14
                
                // フラグをクリア
                UserDefaults.standard.removeObject(forKey: "hasUpdatedForLevelUpTesting")
                
                try viewContext.save()
                
                // Core Dataの変更を反映
                viewContext.refreshAllObjects()
                
                print("✅ User reset to Level 9 (120EXP) for testing - next task will reach Level 10!")
            }
        } catch {
            print("❌ Failed to reset user: \(error)")
        }
    }
}



// MARK: - Tutorial Overlay View (UI Highlight Type)
struct TutorialOverlayView: View {
    @StateObject private var tutorialManager = TutorialManager.shared
    @State private var showContent = false
    @State private var glowAnimation = false
    
    var body: some View {
        if tutorialManager.isActive, let currentHighlight = tutorialManager.currentHighlight {
            GeometryReader { geometry in
                ZStack {
                    // 半透明黒背景 + ハイライト切り抜き
                    highlightOverlay(for: currentHighlight, in: geometry)
                    
                    // 右上スキップボタン
                    VStack {
                        HStack {
                            Spacer()
                            skipButton
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                        Spacer()
                    }
                    
                    // メッセージ表示
                    messageView(for: currentHighlight, in: geometry)
                }
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5), value: showContent)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showContent = true
                    startGlowAnimation()
                }
            }
        }
    }
    
    private var skipButton: some View {
        Button(action: {
            tutorialManager.skipTutorial()
        }) {
            Text("スキップ")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
    
    private func highlightOverlay(for target: TutorialHighlightTarget, in geometry: GeometryProxy) -> some View {
        let targetFrame = getTargetFrame(for: target, in: geometry)
        
        return ZStack {
            // すべてを暗くする背景
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            // ターゲット要素を明るく表示する部分
            RoundedRectangle(cornerRadius: min(targetFrame.width, targetFrame.height) / 6)
                .fill(Color.clear)
                .frame(
                    width: targetFrame.width + 16,
                    height: targetFrame.height + 16
                )
                .position(x: targetFrame.midX, y: targetFrame.midY)
                .overlay(
                    // 光るボーダーエフェクト
                    RoundedRectangle(cornerRadius: min(targetFrame.width, targetFrame.height) / 6)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(
                            width: targetFrame.width + 16,
                            height: targetFrame.height + 16
                        )
                        .position(x: targetFrame.midX, y: targetFrame.midY)
                        .scaleEffect(glowAnimation ? 1.05 : 1.0)
                        .opacity(glowAnimation ? 0.7 : 1.0)
                        .shadow(color: .cyan, radius: glowAnimation ? 15 : 8)
                )
                .blendMode(.lighten)
        }
    }
    
    private func messageView(for target: TutorialHighlightTarget, in geometry: GeometryProxy) -> some View {
        let targetFrame = getTargetFrame(for: target, in: geometry)
        let messagePosition = getMessagePosition(for: targetFrame, in: geometry)
        
        return VStack(spacing: 15) {
            Text(tutorialManager.currentStep.message)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            // 次へボタン（必要に応じて）
            if tutorialManager.currentStep != .taskTab {
                Button("次へ") {
                    tutorialManager.nextStep()
                }
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.cyan.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 30)
        .position(messagePosition)
    }
    
    private func getTargetFrame(for target: TutorialHighlightTarget, in geometry: GeometryProxy) -> CGRect {
        // 各UI要素の推定位置（実際の座標は後で調整）
        switch target {
        case .taskTabButton:
            // ボトムバーのタスクタブ位置（中央のタブ）
            return CGRect(
                x: geometry.size.width / 2 - 30,
                y: geometry.size.height - 100,
                width: 60,
                height: 60
            )
        case .addButton:
            // フローティング追加ボタン位置
            return CGRect(
                x: geometry.size.width - 96,
                y: geometry.size.height - 200,
                width: 56,
                height: 56
            )
        case .titleInputField:
            // タイトル入力欄位置
            return CGRect(
                x: 40,
                y: geometry.size.height * 0.4,
                width: geometry.size.width - 80,
                height: 44
            )
        case .completeTaskButton:
            // タスクのチェックボックス位置
            return CGRect(
                x: 30,
                y: geometry.size.height * 0.35,
                width: 30,
                height: 30
            )
        case .experienceGainNotification:
            // 経験値獲得通知位置
            return CGRect(
                x: 40,
                y: geometry.size.height - 200,
                width: geometry.size.width - 80,
                height: 60
            )
        case .levelUpDisplay:
            // レベル表示位置
            return CGRect(
                x: 40,
                y: 100,
                width: 100,
                height: 40
            )
        }
    }
    
    private func getMessagePosition(for targetFrame: CGRect, in geometry: GeometryProxy) -> CGPoint {
        let messageHeight: CGFloat = 120
        
        // ターゲットの位置に応じてメッセージ位置を調整
        if targetFrame.midY < geometry.size.height / 2 {
            // ターゲットが上半分にある場合、メッセージを下に表示
            return CGPoint(
                x: geometry.size.width / 2,
                y: min(targetFrame.maxY + 80, geometry.size.height - messageHeight / 2 - 50)
            )
        } else {
            // ターゲットが下半分にある場合、メッセージを上に表示
            return CGPoint(
                x: geometry.size.width / 2,
                y: max(targetFrame.minY - 80, messageHeight / 2 + 50)
            )
        }
    }
    
    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            glowAnimation = true
        }
    }
}

#Preview {
    MainGameView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
