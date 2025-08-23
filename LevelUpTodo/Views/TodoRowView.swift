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
                    // タスクタイプ表示
                    if let taskType = TaskType(rawValue: todo.taskType ?? "strength") {
                        Text(taskType.emoji)
                            .font(.caption)
                        Text(taskType.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
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
                
                // 経験値とステータスを追加
                addExperienceAndStats(amount: Int(todo.experienceReward), taskType: todo.taskType ?? "strength")
            } else {
                todo.isCompleted = false
                todo.completedAt = nil
                
                // 経験値を減算（ステータスは減算しない）
                subtractExperience(amount: Int(todo.experienceReward))
            }
            
            try? viewContext.save()
        }
    }
    
    private func addExperienceAndStats(amount: Int, taskType: String) {
        guard let user = getUser() else { return }
        guard let taskTypeEnum = TaskType(rawValue: taskType) else { return }
        
        // 経験値を追加
        user.addExperience(amount)
        
        // ステータスを成長
        user.completeTask(taskType: taskTypeEnum)
    }
    
    private func subtractExperience(amount: Int) {
        guard let user = getUser() else { return }
        
        user.experience = max(0, user.experience - Int32(amount))
        user.totalExperience = max(0, user.totalExperience - Int32(amount))
        
        // レベルの再計算
        let newLevel = ExperienceService.shared.calculateLevel(from: Int(user.experience))
        user.level = Int32(newLevel)
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