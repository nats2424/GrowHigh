import Foundation
import CoreData

/// タスク関連のビジネスロジックを担当するUseCase
protocol TaskUseCaseProtocol {
    func createTask(title: String, taskTypes: [TaskType], isRoutine: Bool, isChallenge: Bool, hasAnxiety: Bool, requiredHours: Double) async throws -> TodoItem
    func completeTask(_ task: TodoItem) async throws
    func fetchActiveTasks() async throws -> [TodoItem]
    func fetchCompletedTasks() async throws -> [TodoItem]
}

class TaskUseCase: TaskUseCaseProtocol {
    private let taskRepository: TaskRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let experienceService: ExperienceService
    
    init(
        taskRepository: TaskRepositoryProtocol,
        userRepository: UserRepositoryProtocol,
        experienceService: ExperienceService = .shared
    ) {
        self.taskRepository = taskRepository
        self.userRepository = userRepository
        self.experienceService = experienceService
    }
    
    func createTask(
        title: String,
        taskTypes: [TaskType],
        isRoutine: Bool,
        isChallenge: Bool,
        hasAnxiety: Bool,
        requiredHours: Double
    ) async throws -> TodoItem {
        // タスクの経験値を計算
        let experienceReward = calculateExperienceReward(
            isRoutine: isRoutine,
            isChallenge: isChallenge,
            hasAnxiety: hasAnxiety,
            requiredHours: requiredHours
        )
        
        // タスクを作成
        let task = try await taskRepository.createTask(
            title: title,
            taskTypes: taskTypes,
            experienceReward: experienceReward,
            isRoutine: isRoutine
        )
        
        return task
    }
    
    func completeTask(_ task: TodoItem) async throws {
        // ユーザー取得
        guard let user = try await userRepository.getCurrentUser() else {
            throw TaskError.userNotFound
        }
        
        // タスクを完了状態に更新
        try await taskRepository.completeTask(task)
        
        // 経験値をユーザーに追加
        let experience = Int(task.experienceReward)
        try await userRepository.addExperience(to: user, amount: experience)
        
        // タスクタイプに応じたステータス成長
        if let taskTypeString = task.taskType,
           let taskType = TaskType(rawValue: taskTypeString) {
            try await userRepository.incrementStat(for: user, taskType: taskType)
        }
    }
    
    func fetchActiveTasks() async throws -> [TodoItem] {
        return try await taskRepository.fetchActiveTasks()
    }
    
    func fetchCompletedTasks() async throws -> [TodoItem] {
        return try await taskRepository.fetchCompletedTasks()
    }
    
    // MARK: - Private Methods
    
    private func calculateExperienceReward(
        isRoutine: Bool,
        isChallenge: Bool,
        hasAnxiety: Bool,
        requiredHours: Double
    ) -> Int {
        var baseExp = 10
        
        // 挑戦タスクの場合 +5 EXP
        if isChallenge {
            baseExp += 5
        }
        
        // 必要時間に応じてEXP追加
        let timeBonus = getTimeBonusExp(hours: requiredHours)
        baseExp += timeBonus
        
        // 不安や緊張がある場合 +10 EXP
        if hasAnxiety {
            baseExp += 10
        }
        
        // ルーティンタスクの場合は半分
        if isRoutine {
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
}

enum TaskError: Error {
    case userNotFound
    case taskNotFound
    case invalidData
}