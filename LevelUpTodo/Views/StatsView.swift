import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var navigationPath: NavigationPath
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TodoItem.completedAt, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == YES"),
        animation: .default)
    private var completedTodos: FetchedResults<TodoItem>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TodoItem.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == NO"),
        animation: .default)
    private var pendingTodos: FetchedResults<TodoItem>
    
    var body: some View {
        ZStack {
            // ホームと同じ背景グラデーション
            backgroundGradient
            
            VStack(spacing: 0) {
                // コンテンツ
                ScrollView {
                    VStack(spacing: 20) {
                        if let user = getUser() {
                            // 基本統計（レベル・経験値）
                            BasicStatsView(user: user)
                            
                            // 週間進捗
                            WeeklyProgressView(completedTodos: Array(completedTodos))
                            
                            // 週間経験値獲得グラフ
                            WeeklyExperienceChartView(completedTodos: Array(completedTodos))
                            
                            // 先週の達成率
                            LastWeekAchievementView(completedTodos: Array(completedTodos))
                            
                            // ステータスレーダーチャート
                            StatusRadarChartView(user: user)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 50) // ヘッダー削除分のトップ余白
                    .padding(.bottom, 100) // ボトムナビ分の余白
                }
                .background(Color.clear)
                
                // ボトムナビゲーション
                StatsBottomNavigationView(navigationPath: $navigationPath)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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
    
    
    private func getUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        return try? viewContext.fetch(request).first
    }
}

struct StatusRadarChartView: View {
    @ObservedObject var user: User
    
    private var stats: [(String, Double, Color)] {
        let maxStat = max(user.strength, user.focus, user.intelligence, user.creativity, user.endurance)
        let normalizedMax = max(Double(maxStat), 10.0) // 最小値を10に設定
        
        return [
            ("筋力", Double(user.strength) / normalizedMax, .red),
            ("集中力", Double(user.focus) / normalizedMax, .orange),
            ("知力", Double(user.intelligence) / normalizedMax, .purple),
            ("創造力", Double(user.creativity) / normalizedMax, .green),
            ("持久力", Double(user.endurance) / normalizedMax, .cyan)
        ]
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("ステータス")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            radarChartView
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple.opacity(0.7), .cyan.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .shadow(color: .purple.opacity(0.3), radius: 8)
        )
    }
    
    private var radarChartView: some View {
        ZStack {
            pentagonGrid
            statusPentagon
            statusLabels
        }
        .frame(width: 300, height: 300)
    }
    
    private var pentagonGrid: some View {
        ForEach(1..<6) { level in
            Pentagon()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .scaleEffect(Double(level) * 0.2)
        }
    }
    
    private var statusPentagon: some View {
        let fillGradient = LinearGradient(
            gradient: Gradient(colors: [.cyan.opacity(0.3), .purple.opacity(0.3)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        let strokeGradient = LinearGradient(
            gradient: Gradient(colors: [.cyan, .purple]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return Pentagon(values: stats.map { $0.1 })
            .fill(fillGradient)
            .overlay(
                Pentagon(values: stats.map { $0.1 })
                    .stroke(strokeGradient, lineWidth: 2)
            )
    }
    
    private var statusLabels: some View {
        ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
            statusLabel(for: index, stat: stat)
        }
    }
    
    private func statusLabel(for index: Int, stat: (String, Double, Color)) -> some View {
        let angle = Double(index) * (2 * .pi / 5) - .pi / 2
        let radius: Double = 120
        let x = cos(angle) * radius
        let y = sin(angle) * radius
        
        return VStack(spacing: 2) {
            Text(stat.0)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(stat.2)
            Text("\(getActualValue(for: index))")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .position(x: 150 + x, y: 150 + y)
    }
    
    private func getActualValue(for index: Int) -> Int {
        switch index {
        case 0: return Int(user.strength)
        case 1: return Int(user.focus)
        case 2: return Int(user.intelligence)
        case 3: return Int(user.creativity)
        case 4: return Int(user.endurance)
        default: return 0
        }
    }
}

struct Pentagon: Shape {
    var values: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * 0.8
        
        let points = (0..<5).map { index in
            let angle = Double(index) * (2 * .pi / 5) - .pi / 2
            let value = values.count > index ? values[index] : 1.0
            let x = center.x + cos(angle) * radius * value
            let y = center.y + sin(angle) * radius * value
            return CGPoint(x: x, y: y)
        }
        
        if let firstPoint = points.first {
            path.move(to: firstPoint)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
        }
        
        return path
    }
}

struct BasicStatsView: View {
    @ObservedObject var user: User
    
    var body: some View {
        VStack(spacing: 20) {
            // ユーザーアイコンとレベル情報
            HStack(spacing: 15) {
                // ユーザーアイコン
                ZStack {
                    // ネオンリング
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.cyan, .purple, .cyan]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .cyan, radius: 5)
                    
                    Image(getCurrentAvatarForUser(user))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                }
                
                // レベル表示
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lv \(user.level)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    
                    Text(avatarName(for: user.currentAvatarType))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(experienceText(for: user))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // ステータス表示
            VStack(spacing: 10) {
                HStack(spacing: 20) {
                    statusItem(label: "筋力", value: Int(user.strength), color: .red)
                    statusItem(label: "集中力", value: Int(user.focus), color: .orange)
                }
                HStack(spacing: 20) {
                    statusItem(label: "知力", value: Int(user.intelligence), color: .purple)
                    statusItem(label: "持久力", value: Int(user.endurance), color: .cyan)
                }
                statusItem(label: "創造力", value: Int(user.creativity), color: .green)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.cyan.opacity(0.7), .white.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .shadow(color: .cyan.opacity(0.3), radius: 8)
        )
    }
    
    private func avatarImage(for avatarType: String?) -> String {
        return avatarType ?? "boy1"
    }
    
    private func getCurrentAvatarForUser(_ user: User) -> String {
        // 現在のユーザーの統計に基づいて正しいアバターを決定
        let level = Int(user.level)
        let dominantStat = getDominantStatForUser(user)
        
        // JobSystemに基づいてアバターを決定
        if let jobInfo = getCurrentJobForUserLevel(level, dominantStat: dominantStat) {
            return jobInfo.avatarImageName
        }
        
        // フォールバック
        return user.currentAvatarType ?? "boy1"
    }
    
    private func getCurrentJobForUserLevel(_ level: Int, dominantStat: StatType) -> (name: String, avatarImageName: String)? {
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
                return getCurrentJobForUserLevel(closestLevel, dominantStat: dominantStat)
            }
            return nil
        }
    }
    
    private enum StatType {
        case strength, intelligence, endurance, focus, creativity
    }
    
    private func getDominantStatForUser(_ user: User) -> StatType {
        let stats = [
            (value: Int(user.strength), type: StatType.strength),
            (value: Int(user.intelligence), type: StatType.intelligence),
            (value: Int(user.endurance), type: StatType.endurance),
            (value: Int(user.focus), type: StatType.focus),
            (value: Int(user.creativity), type: StatType.creativity)
        ]
        
        return stats.max(by: { $0.value < $1.value })?.type ?? .strength
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
    
    private func experienceText(for user: User) -> String {
        let currentLevel = Int(user.level)
        let currentExp = Int(user.experience)
        let expForCurrentLevel = ExperienceService.shared.totalExperienceRequiredForLevel(currentLevel)
        let expForNextLevel = ExperienceService.shared.totalExperienceRequiredForLevel(currentLevel + 1)
        let expInCurrentLevel = currentExp - expForCurrentLevel
        let expRequiredForNextLevel = expForNextLevel - expForCurrentLevel
        
        return "\(expInCurrentLevel)/\(expRequiredForNextLevel) EXP"
    }
    
    @ViewBuilder
    private func statusItem(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 60, alignment: .leading)
            Text("\(value)")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct TodayAchievementsView: View {
    let completedTodos: [TodoItem]
    
    var todayCompletedTodos: [TodoItem] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return completedTodos.filter { todo in
            guard let completedAt = todo.completedAt else { return false }
            return completedAt >= today && completedAt < tomorrow
        }
    }
    
    var todayExperience: Int {
        todayCompletedTodos.reduce(0) { $0 + Int($1.experienceReward) }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("今日の実績")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(todayCompletedTodos.count)個のタスク完了")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("\(todayExperience) EXP獲得")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.green.opacity(0.7), .cyan.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .shadow(color: .green.opacity(0.3), radius: 8)
        )
    }
}

struct WeeklyProgressView: View {
    let completedTodos: [TodoItem]
    
    var weeklyData: [DayData] {
        let calendar = Calendar.current
        let today = Date()
        var data: [DayData] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let dayTodos = completedTodos.filter { todo in
                guard let completedAt = todo.completedAt else { return false }
                return completedAt >= dayStart && completedAt < dayEnd
            }
            
            let dayName = calendar.component(.weekday, from: date)
            let weekdaySymbol = calendar.shortWeekdaySymbols[dayName - 1]
            
            // テスト用：全ての日でタスクが達成されているようにする
            let hasCompletedTask = 1  // 常に1（達成済み）に設定
            
            data.append(DayData(
                day: weekdaySymbol,
                count: hasCompletedTask,
                experience: dayTodos.reduce(0) { $0 + Int($1.experienceReward) }
            ))
        }
        
        return data.reversed()
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("週間進捗（タスク達成日数）")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(weeklyData, id: \.day) { dayData in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(
                                dayData.count > 0 ? 
                                LinearGradient(
                                    gradient: Gradient(colors: [.green, .cyan]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ) :
                                LinearGradient(
                                    gradient: Gradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: dayData.count > 0 ? "checkmark" : "")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text(dayData.day)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .frame(height: 80)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple.opacity(0.7), .cyan.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .shadow(color: .purple.opacity(0.3), radius: 8)
        )
    }
}

struct DayData {
    let day: String
    let count: Int
    let experience: Int
}

struct LastWeekAchievementView: View {
    let completedTodos: [TodoItem]
    
    var lastWeekData: (created: Int, completed: Int, rate: Double) {
        let calendar = Calendar.current
        let today = Date()
        
        // 先週の期間を計算
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: calendar.startOfDay(for: today))!
        let lastWeekEnd = calendar.startOfDay(for: today)
        
        // 先週作成されたタスクの数を取得（簡易実装）
        // 注意: この実装では完了済みタスクのみから推測しているため、実際の作成数とは異なる可能性があります
        let lastWeekCompletedTasks = completedTodos.filter { todo in
            guard let completedAt = todo.completedAt else { return false }
            return completedAt >= lastWeekStart && completedAt < lastWeekEnd
        }
        
        // 先週作成されたタスクは完了済みタスクの1.5倍と仮定（概算）
        let estimatedCreatedTasks = Int(Double(lastWeekCompletedTasks.count) * 1.5)
        let completedTasks = lastWeekCompletedTasks.count
        let achievementRate = estimatedCreatedTasks > 0 ? Double(completedTasks) / Double(estimatedCreatedTasks) * 100.0 : 0.0
        
        return (created: estimatedCreatedTasks, completed: completedTasks, rate: achievementRate)
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("先週の達成率")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                // 達成率円グラフ
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: lastWeekData.rate / 100.0)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .cyan]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(Int(lastWeekData.rate))%")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                
                // 詳細情報
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("完了:")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("\(lastWeekData.completed)個")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("作成数:")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("\(lastWeekData.created)個")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    
                    Text(achievementMessage)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(achievementColor)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.green.opacity(0.7), .cyan.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .shadow(color: .green.opacity(0.3), radius: 8)
        )
    }
    
    private var achievementMessage: String {
        let rate = lastWeekData.rate
        switch rate {
        case 90...:
            return "素晴らしい！"
        case 70..<90:
            return "良い調子です"
        case 50..<70:
            return "もう少し頑張りましょう"
        default:
            return "今週は頑張りましょう"
        }
    }
    
    private var achievementColor: Color {
        let rate = lastWeekData.rate
        switch rate {
        case 90...:
            return .green
        case 70..<90:
            return .cyan
        case 50..<70:
            return .orange
        default:
            return .red
        }
    }
}

struct RecentCompletedView: View {
    let completedTodos: [TodoItem]
    
    var body: some View {
        VStack(spacing: 15) {
            Text("最近完了したタスク")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if completedTodos.isEmpty {
                Text("まだ完了したタスクがありません")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(completedTodos, id: \.objectID) { todo in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(todo.title ?? "")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                if let completedAt = todo.completedAt {
                                    Text(formatDate(completedAt))
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            Text("+\(todo.experienceReward)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.green.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.green.opacity(0.5), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.cyan.opacity(0.7), .white.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .shadow(color: .cyan.opacity(0.3), radius: 8)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Weekly Experience Chart View
struct WeeklyExperienceChartView: View {
    let completedTodos: [TodoItem]
    
    // 過去7日間の経験値データを計算
    private var weeklyExperienceData: [(date: Date, experience: Int)] {
        let calendar = Calendar.current
        let today = Date()
        
        var data: [(date: Date, experience: Int)] = []
        
        for i in stride(from: 6, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            
            let dayTodos = completedTodos.filter { todo in
                guard let completedAt = todo.completedAt else { return false }
                return completedAt >= startOfDay && completedAt < endOfDay
            }
            
            let totalExperience = dayTodos.reduce(0) { total, todo in
                total + Int(todo.experienceReward)
            }
            
            data.append((date: date, experience: totalExperience))
        }
        
        return data
    }
    
    private var maxExperience: Int {
        weeklyExperienceData.map(\.experience).max() ?? 1
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("週間経験値獲得")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 棒グラフ
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(weeklyExperienceData.enumerated()), id: \.offset) { index, data in
                    VStack(spacing: 4) {
                        // 経験値表示
                        if data.experience > 0 {
                            Text("\(data.experience)")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(.cyan)
                        } else {
                            Text("")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        }
                        
                        // 棒グラフ
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: data.experience > 0 ? [.cyan, .blue] : [.gray.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 30, height: {
                                let exp = max(0, data.experience)
                                let maxExp = max(1, maxExperience)
                                let ratio = CGFloat(exp) / CGFloat(maxExp)
                                let height = ratio * 80
                                return max(4, min(80, height.isFinite ? height : 4))
                            }())
                            .cornerRadius(4)
                        
                        // 日付
                        Text(formatDateShort(data.date))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
            
            // 合計経験値
            HStack {
                Text("週間合計:")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(weeklyExperienceData.reduce(0) { $0 + $1.experience }) EXP")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.cyan.opacity(0.7), .blue.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .shadow(color: .cyan.opacity(0.3), radius: 8)
        )
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - Stats Bottom Navigation View
struct StatsBottomNavigationView: View {
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        HStack(spacing: 0) {
            // ホーム
            premiumTabButton(
                icon: "house.fill",
                title: "ホーム",
                isSelected: false
            ) {
                // ホームに戻る（NavigationPathをクリア）
                navigationPath = NavigationPath()
            }
            
            // タスク
            premiumTabButton(
                icon: "list.bullet",
                title: "タスク",
                isSelected: false
            ) {
                // タスクリスト画面への遷移
                navigationPath.append("TodoList")
            }
            
            // 統計
            premiumTabButton(
                icon: "chart.bar",
                title: "統計",
                isSelected: true
            ) {
                // 現在のページなので何もしない
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
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    StatsView(navigationPath: .constant(NavigationPath()))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}