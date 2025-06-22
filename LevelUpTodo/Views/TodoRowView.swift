import SwiftUI
import CoreData

struct TodoRowView: View {
    @ObservedObject var todo: TodoItem
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        HStack {
            Button(action: toggleCompletion) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title ?? "")
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("\(todo.experienceReward) EXP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if todo.isCompleted, let completedAt = todo.completedAt {
                        Text("完了: \(formatDate(completedAt))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            PriorityBadge(priority: todo.priority)
        }
        .padding(.vertical, 4)
    }
    
    private func toggleCompletion() {
        withAnimation {
            if !todo.isCompleted {
                todo.isCompleted = true
                todo.completedAt = Date()
                
                // 経験値を追加
                addExperience(amount: Int(todo.experienceReward))
            } else {
                todo.isCompleted = false
                todo.completedAt = nil
                
                // 経験値を減算
                subtractExperience(amount: Int(todo.experienceReward))
            }
            
            try? viewContext.save()
        }
    }
    
    private func addExperience(amount: Int) {
        guard let user = getUser() else { return }
        
        user.experience += Int32(amount)
        user.totalExperience += Int32(amount)
        
        // レベルアップチェック
        checkLevelUp(user: user)
    }
    
    private func subtractExperience(amount: Int) {
        guard let user = getUser() else { return }
        
        user.experience = max(0, user.experience - Int32(amount))
        user.totalExperience = max(0, user.totalExperience - Int32(amount))
    }
    
    private func checkLevelUp(user: User) {
        while user.experience >= user.experienceToNextLevel {
            user.experience -= user.experienceToNextLevel
            user.level += 1
            user.experienceToNextLevel = calculateNextLevelRequirement(level: Int(user.level))
            
            // レベルアップ通知（後で実装）
            print("レベルアップ! 新しいレベル: \(user.level)")
        }
    }
    
    private func calculateNextLevelRequirement(level: Int) -> Int32 {
        // レベルが上がるほど必要経験値が増加
        return Int32(100 + (level - 1) * 50)
    }
    
    private func getUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        return try? viewContext.fetch(request).first
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PriorityBadge: View {
    let priority: Int32
    
    var body: some View {
        let (text, color) = priorityInfo
        
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
    
    private var priorityInfo: (String, Color) {
        switch priority {
        case 3:
            return ("高", .red)
        case 2:
            return ("中", .orange)
        default:
            return ("低", .blue)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let todo = TodoItem(context: context)
    todo.title = "サンプルタスク"
    todo.experienceReward = 50
    todo.priority = 2
    todo.isCompleted = false
    
    return TodoRowView(todo: todo)
        .environment(\.managedObjectContext, context)
}