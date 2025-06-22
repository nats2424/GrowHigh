import SwiftUI
import CoreData

struct TodoListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TodoItem.createdAt, ascending: false)],
        animation: .default)
    private var todos: FetchedResults<TodoItem>
    
    @State private var showingAddTodo = false
    @State private var newTodoTitle = ""
    @State private var newTodoReward = 10
    
    var body: some View {
        NavigationView {
            VStack {
                // 進捗情報
                if let user = getUser() {
                    UserProgressView(user: user)
                        .padding()
                }
                
                // ToDoリスト
                List {
                    ForEach(todos) { todo in
                        TodoRowView(todo: todo)
                    }
                    .onDelete(perform: deleteTodos)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("レベルアップToDo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTodo = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTodo) {
                AddTodoView()
            }
        }
    }
    
    private func getUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        return try? viewContext.fetch(request).first
    }
    
    private func deleteTodos(offsets: IndexSet) {
        withAnimation {
            offsets.map { todos[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    TodoListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}