import SwiftUI
import CoreData

struct AddTodoView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var selectedTaskTypes: Set<TaskType> = []
    
    // 新仕様: 4つの入力項目
    @State private var isRoutineTask = false
    @State private var isUnexperiencedTask = false
    @State private var requiredHours: TaskTimeOption = .oneHour
    @State private var hasAnxiety = false
    
    // 計算された経験値（表示用）
    private var calculatedExperienceReward: Int {
        calculateExperienceReward()
    }
    
    // フォーム入力完了チェック
    private var isFormComplete: Bool {
        !title.isEmpty && !selectedTaskTypes.isEmpty
    }
    
    private func calculateExperienceReward() -> Int {
        var baseExp = 10
        
        // ② 未経験なタスクの場合 +5 EXP
        if isUnexperiencedTask {
            baseExp += 5
        }
        
        // ③ 必要時間に応じてEXP追加
        let timeBonus = getTimeBonusExp(hours: requiredHours.rawValue)
        baseExp += timeBonus
        
        // ④ 不安や緊張がある場合 +10 EXP
        if hasAnxiety {
            baseExp += 10
        }
        
        // ① ルーティンタスクの場合は半分
        if isRoutineTask {
            baseExp = Int(Double(baseExp) * 0.5)
        }
        
        return baseExp
    }
    
    private func getTimeBonusExp(hours: Double) -> Int {
        switch hours {
        case 0.5:
            return 5
        case 1.0:
            return 10
        case 2.0:
            return 20
        case 3.0:
            return 30
        case 4.0...:
            return 40
        default:
            return 10
        }
    }	
    
    
    var body: some View {
        NavigationView {
            ZStack {
                premiumBackgroundView
                premiumParticleEffects
                mainContentView
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
    
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
    
    /// 動的パーティクルエフェクト
    private var premiumParticleEffects: some View {
        // 簡易パーティクルエフェクト
        ZStack {
            ForEach(0..<15, id: \.self) { index in
                Circle()
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true),
                        value: index
                    )
            }
        }
        .ignoresSafeArea()
    }
    
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 25) {
                premiumTitleSection
                questCreationCard
                Spacer().frame(height: 20)
                premiumActionButtons
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
    }
    
    /// プレミアムタイトルセクション
    private var premiumTitleSection: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            
            // タイトルとサブタイトル
            VStack(spacing: 8) {
                Text("新しいタスクを作成")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .cyan, radius: 8)
                
                Text("タスクを完了してステータスを向上させましょう")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    /// プレミアムタスク作成カード
    private var questCreationCard: some View {
        VStack(spacing: 0) {
            // セクション1: タスク基本情報
            questBasicInfoSection
            
            // セクション2: ステータス強化設定
            statusEnhancementSection
            
            // セクション3: タスク設定
            questSettingsSection
            
            // 経験値プレビュー（非表示）
            // experiencePreviewSection
        }
        .background(premiumCardBackground)
    }
    
    /// タスク基本情報セクション
    private var questBasicInfoSection: some View {
        VStack(spacing: 16) {
            premiumSectionHeader(
                title: "タスク基本情報", 
                icon: "", 
                color: .cyan
            )
            
            VStack(alignment: .leading, spacing: 12) {
                Text("タスク名")
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                
                TextField("例：30分間の読書", text: $title)
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(.white)
                    .padding(16)
                    .background(premiumTextFieldBackground)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .padding(24)
    }
    
    /// ステータス強化設定セクション
    private var statusEnhancementSection: some View {
        VStack(spacing: 16) {
            premiumSectionHeader(
                title: "ステータス強化設定", 
                icon: "", 
                color: .orange
            )
            
            VStack(spacing: 16) {
                // ステータス選択
                VStack(alignment: .leading, spacing: 12) {
                    Text("強化するステータス")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach([TaskType.strength, TaskType.intelligence, TaskType.focus, TaskType.continuity], id: \.self) { taskType in
                            premiumStatusButton(taskType)
                        }
                    }
                }
                
                // 所要時間
                VStack(alignment: .leading, spacing: 12) {
                    Text("所要時間")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TaskTimeOption.allCases, id: \.self) { timeOption in
                                premiumDifficultyButton(timeOption)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding(24)
        .background(
            Rectangle()
                .fill(.white.opacity(0.02))
        )
    }
    
    /// タスク設定セクション
    private var questSettingsSection: some View {
        VStack(spacing: 16) {
            premiumSectionHeader(
                title: "タスク設定", 
                icon: "", 
                color: .purple
            )
            
            VStack(spacing: 16) {
                // チェックボックス設定
                VStack(spacing: 12) {
                    premiumToggleRow(
                        title: "ルーティンタスク", 
                        subtitle: "毎日繰り返すタスク",
                        isOn: $isRoutineTask,
                        icon: ""
                    )
                    
                    premiumToggleRow(
                        title: "チャレンジタスク", 
                        subtitle: "初めて挑戦するタスク",
                        isOn: $isUnexperiencedTask,
                        icon: ""
                    )
                    
                    premiumToggleRow(
                        title: "不安要素あり", 
                        subtitle: "緊張や困難が予想される",
                        isOn: $hasAnxiety,
                        icon: ""
                    )
                }
            }
        }
        .padding(24)
        .background(
            Rectangle()
                .fill(.white.opacity(0.02))
        )
    }
    
    /// 経験値プレビューセクション
    private var experiencePreviewSection: some View {
        VStack(spacing: 16) {
            premiumSectionHeader(
                title: "獲得予定経験値", 
                icon: "", 
                color: .yellow
            )
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("計算結果")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("基本計算式に基づいて自動算出")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("+\(calculatedExperienceReward)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow, radius: 4)
                    
                    Text("EXP")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.yellow.opacity(0.1))
                        .stroke(.yellow.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(24)
        .background(
            Rectangle()
                .fill(.white.opacity(0.02))
        )
    }
    
    /// プレミアムアクションボタン
    private var premiumActionButtons: some View {
        HStack(spacing: 16) {
            // キャンセルボタン
            Button(action: { dismiss() }) {
                Text("キャンセル")
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(premiumCancelButtonBackground)
            }
            
            // 作成ボタン
            Button(action: { addTodo() }) {
                HStack(spacing: 8) {
                    Text("タスク作成")
                        .font(.system(size: 16, weight: .bold, design: .default))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(premiumCreateButtonBackground)
                .shadow(color: isFormComplete ? .cyan.opacity(0.5) : .clear, radius: 15)
            }
            .disabled(!isFormComplete)
            .opacity(isFormComplete ? 1.0 : 0.6)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Premium Component Helpers
    
    /// プレミアムセクションヘッダー
    private func premiumSectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .default))
                .foregroundColor(color)
            
            Spacer()
        }
    }
    
    /// プレミアムステータスボタン
    private func premiumStatusButton(_ taskType: TaskType) -> some View {
        Button(action: {
            if selectedTaskTypes.contains(taskType) {
                selectedTaskTypes.remove(taskType)
            } else {
                selectedTaskTypes.insert(taskType)
            }
        }) {
            VStack(spacing: 8) {
                Text(getTaskTypeEmoji(taskType))
                    .font(.system(size: 24))
                
                Text(taskType.displayName)
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .foregroundColor(selectedTaskTypes.contains(taskType) ? .white : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(premiumStatusButtonBackground(taskType))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// プレミアム難易度ボタン
    private func premiumDifficultyButton(_ timeOption: TaskTimeOption) -> some View {
        Button(action: {
            requiredHours = timeOption
        }) {
            VStack(spacing: 4) {
                Text(getDifficultyIcon(timeOption))
                    .font(.system(size: 16))
                
                Text(timeOption.displayText)
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundColor(requiredHours == timeOption ? .white : .white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(premiumDifficultyButtonBackground(timeOption))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// プレミアムトグル行
    private func premiumToggleRow(title: String, subtitle: String, isOn: Binding<Bool>, icon: String) -> some View {
        Button(action: {
            isOn.wrappedValue.toggle()
        }) {
            HStack(spacing: 16) {
                // アイコン
                Text(icon)
                    .font(.system(size: 20))
                    .frame(width: 30)
                
                // テキスト情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // トグルアイコン
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isOn.wrappedValue ? .cyan : .gray.opacity(0.3))
                        .frame(width: 50, height: 28)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)
                        .offset(x: isOn.wrappedValue ? 11 : -11)
                        .animation(.easeInOut(duration: 0.2), value: isOn.wrappedValue)
                }
            }
            .padding(16)
            .background(premiumToggleBackground(isOn.wrappedValue))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Premium Background Styles
    
    /// プレミアムカード背景
    private var premiumCardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.white.opacity(0.05))
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.cyan.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
    }
    
    /// プレミアムテキストフィールド背景
    private var premiumTextFieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.cyan.opacity(0.5), lineWidth: 1)
            )
    }
    
    /// プレミアムステータスボタン背景
    private func premiumStatusButtonBackground(_ taskType: TaskType) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                selectedTaskTypes.contains(taskType) ?
                LinearGradient(
                    colors: getTaskTypeGradientColors(taskType),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [.black.opacity(0.4), .black.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        getTaskTypeColor(for: taskType).opacity(0.4),
                        lineWidth: selectedTaskTypes.contains(taskType) ? 2 : 1
                    )
            )
            .shadow(
                color: selectedTaskTypes.contains(taskType) ? getTaskTypeColor(for: taskType).opacity(0.3) : .clear,
                radius: selectedTaskTypes.contains(taskType) ? 8 : 0
            )
    }
    
    /// プレミアム難易度ボタン背景
    private func premiumDifficultyButtonBackground(_ timeOption: TaskTimeOption) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                requiredHours == timeOption ?
                LinearGradient(
                    colors: [.orange, .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [.black.opacity(0.4), .black.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        .orange.opacity(requiredHours == timeOption ? 0.6 : 0.2),
                        lineWidth: 1
                    )
            )
    }
    
    /// プレミアムトグル背景
    private func premiumToggleBackground(_ isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                isSelected ?
                LinearGradient(
                    colors: [.cyan.opacity(0.2), .purple.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [.black.opacity(0.3), .black.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? .cyan.opacity(0.4) : .gray.opacity(0.2),
                        lineWidth: 1
                    )
            )
    }
    
    /// プレミアムキャンセルボタン背景
    private var premiumCancelButtonBackground: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(.black.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(.gray.opacity(0.4), lineWidth: 1)
            )
    }
    
    /// プレミアム作成ボタン背景
    private var premiumCreateButtonBackground: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(
                isFormComplete ?
                LinearGradient(
                    colors: [.cyan, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [.gray.opacity(0.5), .gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
    
    // MARK: - Helper Functions
    
    /// タスクタイプの絵文字を取得
    private func getTaskTypeEmoji(_ taskType: TaskType) -> String {
        switch taskType {
        case .strength: return "💪"
        case .intelligence: return "🧠"
        case .focus: return "🎯"
        case .continuity: return "🏃‍♂️"
        }
    }
    
    /// 難易度アイコンを取得
    private func getDifficultyIcon(_ timeOption: TaskTimeOption) -> String {
        switch timeOption {
        case .halfHour: return ""
        case .oneHour: return ""
        case .twoHours: return ""
        case .threeHours: return ""
        case .fourPlusHours: return ""
        }
    }
    
    /// タスクタイプのグラデーションカラーを取得
    private func getTaskTypeGradientColors(_ taskType: TaskType) -> [Color] {
        switch taskType {
        case .strength: return [.red, .orange]
        case .intelligence: return [.purple, .pink]
        case .focus: return [.blue, .cyan]
        case .continuity: return [.green, .mint]
        }
    }
    
    // MARK: - Actions
    
    private func addTodo() {
        withAnimation {
            // 選択された各TaskTypeに対してタスクを作成
            for taskType in selectedTaskTypes {
                let newTodo = TodoItem(context: viewContext)
                newTodo.title = title
                newTodo.experienceReward = Int32(calculatedExperienceReward)
                newTodo.priority = 1
                newTodo.taskType = taskType.rawValue
                newTodo.isCompleted = false
                newTodo.isRoutineTask = isRoutineTask
                newTodo.createdAt = Date()
                
                // ユーザーと関連付け
                if let user = getUser() {
                    newTodo.user = user
                }
            }
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                print("❌ Failed to save: \(nsError)")
            }
        }
    }
    
    private func getUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        return try? viewContext.fetch(request).first
    }
    
    private func getTaskTypeColor(for taskType: TaskType) -> Color {
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
}

#Preview {
    AddTodoView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .preferredColorScheme(.dark)
}
