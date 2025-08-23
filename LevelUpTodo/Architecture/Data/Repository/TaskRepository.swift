import Foundation
import CoreData

/// Core Dataを使用したTaskRepositoryの実装
class TaskRepository: TaskRepositoryProtocol {
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func createTask(title: String, taskTypes: [TaskType], experienceReward: Int, isRoutine: Bool) async throws -> TodoItem {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    let task = TodoItem(context: self.viewContext)
                    task.title = title
                    task.createdAt = Date()
                    task.experienceReward = Int32(experienceReward)
                    task.isCompleted = false
                    task.isRoutineTask = isRoutine
                    
                    // 最初のタスクタイプを使用（簡略実装）
                    if let firstTaskType = taskTypes.first {
                        task.taskType = firstTaskType.rawValue
                    }
                    
                    try self.viewContext.save()
                    continuation.resume(returning: task)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func completeTask(_ task: TodoItem) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    task.isCompleted = true
                    task.completedAt = Date()
                    
                    try self.viewContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchActiveTasks() async throws -> [TodoItem] {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    let request: NSFetchRequest<TodoItem> = TodoItem.fetchRequest()
                    request.predicate = NSPredicate(format: "isCompleted == NO")
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \TodoItem.createdAt, ascending: false)]
                    
                    let tasks = try self.viewContext.fetch(request)
                    continuation.resume(returning: tasks)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchCompletedTasks() async throws -> [TodoItem] {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    let request: NSFetchRequest<TodoItem> = TodoItem.fetchRequest()
                    request.predicate = NSPredicate(format: "isCompleted == YES")
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \TodoItem.completedAt, ascending: false)]
                    
                    let tasks = try self.viewContext.fetch(request)
                    continuation.resume(returning: tasks)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func deleteTask(_ task: TodoItem) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    self.viewContext.delete(task)
                    try self.viewContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}