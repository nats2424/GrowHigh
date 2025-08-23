import SwiftUI
import CoreData

struct TodoListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var navigationPath: NavigationPath
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TodoItem.createdAt, ascending: false)],
        animation: .default)
    private var todos: FetchedResults<TodoItem>
    
    @State private var showingAddTodo = false
    @State private var selectedFilter: TaskFilter = .incomplete
    @State private var showingSnackbar = false
    @State private var showingAllTasksCompleted = false
    
    // フィルター用のenum
    enum TaskFilter: String, CaseIterable {
        case incomplete = "未完了"
        case completed = "完了済み"
        case routine = "ルーティンタスク"
        case all = "すべて"
    }
    
    // フィルタリングされたタスク
    var filteredTodos: [TodoItem] {
        let todoArray = Array(todos)
        
        switch selectedFilter {
        case .all:
            return todoArray
        case .incomplete:
            return todoArray.filter { !$0.isCompleted }
        case .completed:
            return todoArray.filter { $0.isCompleted }
        case .routine:
            return todoArray.filter { $0.isRoutineTask }
        }
    }
    
    var body: some View {
        ZStack {
            // ホームと同じ背景グラデーション
            backgroundGradient
            
            VStack(spacing: 0) {
                // フィルターセクション  
                filterSection
                    .padding(.top, 20) // 最小限の上部余白
                
                // タスクリスト
                taskListSection
                
                // ボトムナビゲーション
                VStack {
                    Spacer()
                    TodoListBottomNavigationView(navigationPath: $navigationPath)
                }
            }
        }
        .overlay(
            // スナックバー通知
            snackbarView
        )
        .overlay(
            // フローティング追加ボタン
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingAddTodo = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.cyan, .blue]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .cyan.opacity(0.4), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 120) // ボトムナビゲーション分の余白
                }
            }
        )
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddTodo) {
            AddTodoView()
        }
        .fullScreenCover(isPresented: $showingAllTasksCompleted) {
            AllTasksCompletedModal(isPresented: $showingAllTasksCompleted)
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
    
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    filterButton(filter)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }
    
    private var snackbarView: some View {
        VStack {
            Spacer()
            
            if showingSnackbar {
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    Text("経験値を獲得しました")
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
                .padding(.bottom, 100)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingSnackbar)
    }
    
    private func filterButton(_ filter: TaskFilter) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        }) {
            Text(filter.rawValue)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(selectedFilter == filter ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(filterButtonBackground(filter))
        }
    }
    
    private func filterButtonBackground(_ filter: TaskFilter) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                selectedFilter == filter ?
                LinearGradient(
                    gradient: Gradient(colors: [.cyan, .white]),
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0.6)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: selectedFilter == filter ? .cyan.opacity(0.3) : .clear, radius: 5)
    }
    
    private var taskListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if filteredTodos.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredTodos, id: \.self) { todo in
                        taskCard(todo)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.cyan.opacity(0.6))
            
            Text("タスクがありません")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(selectedFilter == .all ? "新しいタスクを追加してレベルアップを始めましょう！" : "\(selectedFilter.rawValue)のタスクはありません")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    private func taskCard(_ todo: TodoItem) -> some View {
        HStack(spacing: 15) {
            // 完了チェックボックス
            Button(action: {
                toggleTaskCompletion(todo)
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(todo.isCompleted ? .green : .gray)
            }
            
            // タスク情報
            VStack(alignment: .leading, spacing: 8) {
                // タスクタイトル
                Text(todo.title ?? "")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(todo.isCompleted ? .gray : .white)
                    .strikethrough(todo.isCompleted)
                
                // タスク詳細情報
                HStack(spacing: 12) {
                    // タスクタイプ
                    if let taskType = TaskType(rawValue: todo.taskType ?? "strength") {
                        Text(taskType.displayName)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(getTaskTypeColor(for: taskType))
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // 削除ボタン
            Button(action: {
                deleteTask(todo)
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(taskCardBackground(todo))
        .contextMenu {
            Button(action: {
                toggleTaskCompletion(todo)
            }) {
                Label(todo.isCompleted ? "未完了にする" : "完了にする", 
                      systemImage: todo.isCompleted ? "circle" : "checkmark.circle")
            }
            
            Button(role: .destructive, action: {
                deleteTask(todo)
            }) {
                Label("削除", systemImage: "trash")
            }
        }
    }
    
    private func taskCardBackground(_ todo: TodoItem) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black.opacity(todo.isCompleted ? 0.3 : 0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        todo.isCompleted ? 
                        Color.green.opacity(0.3) : 
                        Color.cyan.opacity(0.4),
                        lineWidth: 1
                    )
            )
            .shadow(color: todo.isCompleted ? .clear : .cyan.opacity(0.1), radius: 3)
    }
    
    private func toggleTaskCompletion(_ todo: TodoItem) {
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
                    // 経験値を追加
                    user.addExperience(Int(todo.experienceReward))
                    
                    // タスクタイプに応じてステータスを成長
                    if let taskTypeString = todo.taskType,
                       let taskType = TaskType(rawValue: taskTypeString) {
                        user.completeTask(taskType: taskType)
                    }
                    
                    // スナックバー表示
                    showSnackbar()
                    
                    // 全タスク完了チェック
                    checkAllTasksCompleted()
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
            } catch {
                print("❌ Failed to save: \(error)")
            }
        }
    }
    
    private func deleteTask(_ todo: TodoItem) {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewContext.delete(todo)
            
            do {
                try viewContext.save()
            } catch {
                print("❌ Failed to delete: \(error)")
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
    
    private func showSnackbar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingSnackbar = true
        }
        
        // 2秒後に自動で非表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingSnackbar = false
            }
        }
    }
    
    private func checkAllTasksCompleted() {
        let incompleteTasks = todos.filter { !$0.isCompleted }
        
        // 今日作成されたタスクがすべて完了している場合にモーダルを表示
        if incompleteTasks.isEmpty && !todos.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingAllTasksCompleted = true
            }
        }
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

struct AllTasksCompletedModal: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("今日のタスクを\n全て達成しました！")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("お疲れ様でした！")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Button("閉じる") {
                    isPresented = false
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(20)
                .fontWeight(.semibold)
            }
            .padding(40)
            .background(Color.black)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cyan, lineWidth: 2)
            )
            .padding(.horizontal, 40)
        }
        .onTapGesture {
            isPresented = false
        }
    }
}

// MARK: - TodoList Bottom Navigation View
struct TodoListBottomNavigationView: View {
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
                isSelected: true
            ) {
                // 現在のページなので何もしない
            }
            
            // 統計
            premiumTabButton(
                icon: "chart.bar",
                title: "統計",
                isSelected: false
            ) {
                // 統計画面への遷移
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
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TodoListView(navigationPath: .constant(NavigationPath()))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}