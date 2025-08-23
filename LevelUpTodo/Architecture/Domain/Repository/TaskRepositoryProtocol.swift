import Foundation

/// タスクデータアクセスのプロトコル
protocol TaskRepositoryProtocol {
    func createTask(title: String, taskTypes: [TaskType], experienceReward: Int, isRoutine: Bool) async throws -> TodoItem
    func completeTask(_ task: TodoItem) async throws
    func fetchActiveTasks() async throws -> [TodoItem]
    func fetchCompletedTasks() async throws -> [TodoItem]
    func deleteTask(_ task: TodoItem) async throws
}

/// ユーザーデータアクセスのプロトコル
protocol UserRepositoryProtocol {
    func getCurrentUser() async throws -> User?
    func createUser(name: String, avatarType: String) async throws -> User
    func addExperience(to user: User, amount: Int) async throws
    func incrementStat(for user: User, taskType: TaskType) async throws
    func updateAvatar(for user: User, avatarType: String) async throws
}