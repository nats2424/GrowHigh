import Foundation
import CoreData

/// Core Dataを使用したUserRepositoryの実装
class UserRepository: UserRepositoryProtocol {
    private let viewContext: NSManagedObjectContext
    private let experienceService = ExperienceService.shared
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func getCurrentUser() async throws -> User? {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    let request: NSFetchRequest<User> = User.fetchRequest()
                    let users = try self.viewContext.fetch(request)
                    continuation.resume(returning: users.first)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func createUser(name: String, avatarType: String) async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    let user = User(context: self.viewContext)
                    user.name = name
                    user.currentAvatarType = avatarType
                    user.level = 1
                    user.experience = 0
                    user.strength = 1
                    user.intelligence = 1
                    user.focus = 1
                    user.creativity = 1
                    user.endurance = 1
                    
                    try self.viewContext.save()
                    continuation.resume(returning: user)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func addExperience(to user: User, amount: Int) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    let oldLevel = Int(user.level)
                    user.experience += Int32(amount)
                    
                    // レベル再計算
                    let newLevel = self.experienceService.calculateLevel(from: Int(user.experience))
                    user.level = Int32(newLevel)
                    
                    // レベルアップチェック
                    if newLevel > oldLevel {
                        self.handleLevelUp(user: user, from: oldLevel, to: newLevel)
                    }
                    
                    try self.viewContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func incrementStat(for user: User, taskType: TaskType) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    switch taskType {
                    case .strength:
                        user.strength += 1
                    case .focus:
                        user.focus += 1
                    case .continuity:
                        user.endurance += 1
                    case .intelligence:
                        user.intelligence += 1
                    }
                    
                    try self.viewContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func updateAvatar(for user: User, avatarType: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    user.currentAvatarType = avatarType
                    try self.viewContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleLevelUp(user: User, from oldLevel: Int, to newLevel: Int) {
        // JobSystemServiceを使用して新しい職業をチェック
        if let newJob = JobSystemService.shared.checkForJobPromotion(user: user, previousLevel: oldLevel) {
            // 新しい職業のアバターに自動更新
            user.currentAvatarType = newJob.avatarImageName
            print("✅ Job promotion: \(newJob.name) (\(newJob.avatarImageName))")
        }
        
        // レベルアップ統計情報の作成（簡略版）
        let statistics = createSimpleLevelUpStatistics(user: user, newLevel: newLevel, previousLevel: oldLevel)
        
        // レベルアップ通知
        NotificationCenter.default.post(
            name: NSNotification.Name("UserLeveledUp"),
            object: nil,
            userInfo: [
                "oldLevel": oldLevel,
                "newLevel": newLevel,
                "statistics": statistics
            ]
        )
    }
    
    private func createSimpleLevelUpStatistics(user: User, newLevel: Int, previousLevel: Int) -> LevelUpStatistics {
        let daysSinceFirst = max(1, newLevel * 2)
        let taskCount = max(5, newLevel * 3)
        let consecutiveDays = min(daysSinceFirst, 14)
        
        let jobTitle = newLevel == 5 ? "見習い冒険者" : "レベル\(newLevel)冒険者"
        let dominantTaskType = TaskCategory.strength
        
        return LevelUpStatistics(
            daysSinceFirstTask: daysSinceFirst,
            mostCompletedTaskType: dominantTaskType,
            currentLevel: newLevel,
            jobTitle: jobTitle,
            previousJobTitle: previousLevel >= 4 ? "駆け出し冒険者" : nil,
            improvementMetric: "順調な成長",
            consecutiveDays: consecutiveDays,
            totalTasksCompleted: taskCount,
            completionRate: 85.0,
            averageCompletionTime: 1.2,
            jobCategory: dominantTaskType,
            isFirstJobAcquisition: newLevel == 5,
            isJobEvolution: newLevel >= 10,
            isConsecutiveStreak: consecutiveDays >= 7
        )
    }
}