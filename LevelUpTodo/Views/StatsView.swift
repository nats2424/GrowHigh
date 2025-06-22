import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
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
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let user = getUser() {
                        // 基本統計
                        BasicStatsView(user: user, completedCount: completedTodos.count, pendingCount: pendingTodos.count)
                        
                        // 今日の実績
                        TodayAchievementsView(completedTodos: Array(completedTodos))
                        
                        // 週間進捗
                        WeeklyProgressView(completedTodos: Array(completedTodos))
                        
                        // 最近完了したタスク
                        RecentCompletedView(completedTodos: Array(completedTodos.prefix(5)))
                    }
                }
                .padding()
            }
            .navigationTitle("統計")
        }
    }
    
    private func getUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        return try? viewContext.fetch(request).first
    }
}

struct BasicStatsView: View {
    @ObservedObject var user: User
    let completedCount: Int
    let pendingCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                StatCard(title: "レベル", value: "\(user.level)", color: .purple)
                StatCard(title: "総経験値", value: "\(user.totalExperience)", color: .blue)
            }
            
            HStack {
                StatCard(title: "完了タスク", value: "\(completedCount)", color: .green)
                StatCard(title: "未完了タスク", value: "\(pendingCount)", color: .orange)
            }
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
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(radius: 2)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("今日の実績")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(todayCompletedTodos.count)個のタスク完了")
                        .font(.subheadline)
                    Text("\(todayExperience) EXP獲得")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(radius: 2)
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
            
            data.append(DayData(
                day: weekdaySymbol,
                count: dayTodos.count,
                experience: dayTodos.reduce(0) { $0 + Int($1.experienceReward) }
            ))
        }
        
        return data.reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("週間進捗")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weeklyData, id: \.day) { dayData in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(dayData.count > 0 ? Color.purple : Color.gray.opacity(0.3))
                            .frame(width: 30, height: max(CGFloat(dayData.count * 10), 5))
                            .cornerRadius(4)
                        
                        Text(dayData.day)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 80)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(radius: 2)
        )
    }
}

struct DayData {
    let day: String
    let count: Int
    let experience: Int
}

struct RecentCompletedView: View {
    let completedTodos: [TodoItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近完了したタスク")
                .font(.headline)
                .fontWeight(.semibold)
            
            if completedTodos.isEmpty {
                Text("まだ完了したタスクがありません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(completedTodos, id: \.objectID) { todo in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(todo.title ?? "")
                                    .font(.subheadline)
                                
                                if let completedAt = todo.completedAt {
                                    Text(formatDate(completedAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Text("+\(todo.experienceReward) EXP")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(radius: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    StatsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}