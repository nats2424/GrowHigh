import SwiftUI
import CoreData

struct TaskTutorialView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    
    @State private var currentStep: Int = 1
    @State private var showingAddTask = false
    @State private var tutorialTaskId: NSManagedObjectID?
    @State private var taskCompleted = false
    
    private let totalSteps = 3
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.orange.opacity(0.6),
                    Color.red.opacity(0.4),
                    Color.pink.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // プログレスバー
                ProgressView(value: Double(currentStep), total: Double(totalSteps))
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(height: 8)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(4)
                    .padding(.horizontal, 40)
                    .padding(.top, 50)
                
                Text("チュートリアル \(currentStep)/\(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // ステップ別コンテンツ
                Group {
                    switch currentStep {
                    case 1:
                        step1Content
                    case 2:
                        step2Content
                    case 3:
                        step3Content
                    default:
                        EmptyView()
                    }
                }
                
                Spacer()
                
                // 次へボタン（条件付き表示）
                if shouldShowNextButton() {
                    Button(action: {
                        nextStep()
                    }) {
                        Text(currentStep == totalSteps ? "チュートリアル完了！" : "次へ")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            )
                    }
                    .padding(.horizontal, 40)
                }
                
                Button(action: {
                    skipTutorial()
                }) {
                    Text("スキップ")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .underline()
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingAddTask) {
            NavigationView {
                AddTodoView()
                    .navigationTitle("初回タスク登録")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("キャンセル") {
                                showingAddTask = false
                            }
                        }
                    }
            }
            .onDisappear {
                checkForNewTask()
            }
        }
        .onAppear {
            checkTaskCompletionStatus()
        }
    }
    
    // MARK: - Step Contents
    
    @ViewBuilder
    private var step1Content: some View {
        VStack(spacing: 20) {
            Text("🎯")
                .font(.system(size: 60))
            
            Text("まずはタスクを1件登録してみましょう！")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("タスクを達成すると経験値がもらえて、レベルアップできます")
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button(action: {
                showingAddTask = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("タスクを追加する")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.8))
                        .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                )
            }
        }
        .padding(.horizontal, 40)
    }
    
    @ViewBuilder
    private var step2Content: some View {
        VStack(spacing: 20) {
            Text("✅")
                .font(.system(size: 60))
            
            Text("次はこのタスクを達成してみましょう！")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("タスクリストから先ほど登録したタスクの完了ボタンをタップしてください")
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // 簡易タスクリストプレビュー（読み取り専用）
            if let taskId = tutorialTaskId,
               let task = getTask(by: taskId) {
                VStack(spacing: 10) {
                    Text("📋 あなたのタスク")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack {
                        Text("• \(task.title ?? "新しいタスク")")
                            .foregroundColor(.white)
                        Spacer()
                        if task.isCompleted {
                            Text("✅")
                        } else {
                            Text("⭕")
                                .opacity(0.5)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.2))
                    )
                }
                .padding(.horizontal, 20)
            }
            
            Button(action: {
                // タスクリストを開く（メイン画面に戻る）
                isPresented = false
            }) {
                HStack {
                    Image(systemName: "list.bullet")
                        .font(.title2)
                    Text("タスクリストを開く")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.8))
                        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                )
            }
        }
        .padding(.horizontal, 40)
    }
    
    @ViewBuilder
    private var step3Content: some View {
        VStack(spacing: 20) {
            Text("🎉")
                .font(.system(size: 60))
            
            Text("タスクを達成すると経験値がもらえて、成長につながります！")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                HStack {
                    Text("💪")
                    Text("タスク達成で経験値+10")
                        .foregroundColor(.white)
                }
                HStack {
                    Text("⬆️")
                    Text("レベルアップでジョブ解放")
                        .foregroundColor(.white)
                }
                HStack {
                    Text("🎮")
                    Text("RPGのように成長を楽しめます")
                        .foregroundColor(.white)
                }
            }
            .font(.body)
            
            Text("これでチュートリアルは完了です！\n日々のタスクでレベルアップしていきましょう🚀")
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 10)
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Helper Functions
    
    private func shouldShowNextButton() -> Bool {
        switch currentStep {
        case 1:
            // タスクが登録されたら次へボタンを表示
            return tutorialTaskId != nil
        case 2:
            // タスクが完了されたら次へボタンを表示
            return taskCompleted
        case 3:
            // 最終ステップでは常に表示
            return true
        default:
            return false
        }
    }
    
    private func nextStep() {
        if currentStep < totalSteps {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            completeTutorial()
        }
    }
    
    private func completeTutorial() {
        UserDefaults.standard.set(true, forKey: "hasCompletedTaskTutorial")
        isPresented = false
    }
    
    private func skipTutorial() {
        UserDefaults.standard.set(true, forKey: "hasCompletedTaskTutorial")
        isPresented = false
    }
    
    private func checkForNewTask() {
        // 新しく追加されたタスクをチェック
        let request = NSFetchRequest<TodoItem>(entityName: "TodoItem")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TodoItem.createdAt, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let tasks = try viewContext.fetch(request)
            if let latestTask = tasks.first {
                tutorialTaskId = latestTask.objectID
            }
        } catch {
            print("Error fetching latest task: \(error)")
        }
    }
    
    private func checkTaskCompletionStatus() {
        guard let taskId = tutorialTaskId,
              let task = getTask(by: taskId) else { return }
        
        taskCompleted = task.isCompleted
        
        // タスクが完了されていて、現在ステップ2にいる場合、自動的にステップ3に進む
        if taskCompleted && currentStep == 2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = 3
                }
            }
        }
    }
    
    private func getTask(by objectId: NSManagedObjectID) -> TodoItem? {
        do {
            return try viewContext.existingObject(with: objectId) as? TodoItem
        } catch {
            print("Error fetching task: \(error)")
            return nil
        }
    }
}

#Preview {
    TaskTutorialView(isPresented: .constant(true))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}