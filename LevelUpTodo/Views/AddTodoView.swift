import SwiftUI
import CoreData

struct AddTodoView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var experienceReward = 10
    @State private var priority = 1
    
    let priorityOptions = ["低", "中", "高"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("タスク情報")) {
                    TextField("タスクのタイトル", text: $title)
                    
                    Stepper("経験値: \(experienceReward)", value: $experienceReward, in: 5...100, step: 5)
                    
                    Picker("優先度", selection: $priority) {
                        ForEach(0..<priorityOptions.count, id: \.self) { index in
                            Text(priorityOptions[index]).tag(index + 1)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(footer: Text("経験値は5〜100の間で設定できます。優先度が高いほど緊急度が高いタスクです。")) {
                    // 空のセクション
                }
            }
            .navigationTitle("新しいタスク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        addTodo()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func addTodo() {
        withAnimation {
            let newTodo = TodoItem(context: viewContext)
            newTodo.title = title
            newTodo.experienceReward = Int32(experienceReward)
            newTodo.priority = Int32(priority)
            newTodo.isCompleted = false
            newTodo.createdAt = Date()
            
            // ユーザーと関連付け
            if let user = getUser() {
                newTodo.user = user
            }
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func getUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        return try? viewContext.fetch(request).first
    }
}

#Preview {
    AddTodoView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}