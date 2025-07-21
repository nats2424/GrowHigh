import SwiftUI
import CoreData

struct MainGameView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingTodoList = false
    @State private var showingStats = false
    @State private var showingAvatarSelection = false
    @State private var showingGenderSelection = false
    @State private var showingTaskTutorial = false
    @State private var showingStatsTutorial = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.3),
                        Color.blue.opacity(0.2),
                        Color.cyan.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // アバター表示エリア
                    if let user = getUser() {
                        VStack(spacing: 20) {
                            // アバター
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [.purple, .blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 150, height: 150)
                                
                                Image(avatarImage(for: user.currentAvatarType))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            }
                                .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                                .scaleEffect(showingTodoList ? 0.8 : 1.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingTodoList)
                                .onTapGesture {
                                    showingAvatarSelection = true
                                }
                            
                            // ユーザー情報
                            VStack(spacing: 8) {
                                Text(avatarName(for: user.currentAvatarType))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("レベル \(user.level)")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                // 経験値バー
                                ProgressView(value: user.progressToNextLevel(), total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                                    .frame(width: 200)
                                    .background(Color.white.opacity(0.3))
                                    .cornerRadius(10)
                                
                                Text(experienceText(for: user))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    // ボタンエリア
                    VStack(spacing: 20) {
                        // ToDoリスト表示ボタン
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                showingTodoList = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "list.bullet.circle.fill")
                                    .font(.title2)
                                Text("タスクを確認する")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .scaleEffect(showingTodoList ? 0.95 : 1.0)
                        .opacity(showingTodoList ? 0.7 : 1.0)
                        
                        // 統計表示ボタン
                        Button(action: {
                            showingStats = true
                        }) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.title2)
                                Text("統計を見る")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.cyan, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .cyan.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .sheet(isPresented: $showingTodoList) {
            NavigationView {
                TodoListView()
                    .navigationTitle("タスクリスト")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("閉じる") {
                                showingTodoList = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingStats) {
            NavigationView {
                StatsView()
                    .navigationTitle("統計")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("閉じる") {
                                showingStats = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingAvatarSelection) {
            NavigationView {
                AvatarView()
                    .navigationTitle("アバター選択")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("閉じる") {
                                showingAvatarSelection = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            setupInitialUser()
            checkFirstTimeUser()
        }
        .fullScreenCover(isPresented: $showingGenderSelection) {
            GenderSelectionView(isPresented: $showingGenderSelection)
        }
        .fullScreenCover(isPresented: $showingTaskTutorial) {
            TaskTutorialView(isPresented: $showingTaskTutorial)
        }
        .fullScreenCover(isPresented: $showingStatsTutorial) {
            StatsTutorialView(isPresented: $showingStatsTutorial)
        }
    }
    
    private func getUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        return try? viewContext.fetch(request).first
    }
    
    private func setupInitialUser() {
        let userService = UserService(context: viewContext)
        _ = userService.getOrCreateUser()
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
        
        switch avatarType {
        // 基本職 (Lv 1-10)
        case "starter_male":
            return "boy1"
        case "starter_female":
            return "girl1"
            
        // 第1転職 (Lv 11-25)
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
            
        // 第2転職 (Lv 26-50)
        case "archmage_male":
            return "archmage_male"
        case "archmage_female":
            return "archmage_female"
        case "knight_male":
            return "knight_male"
        case "knight_female":
            return "knight_female"
            
        // レガシー対応
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
}

#Preview {
    MainGameView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}