import Foundation
import CoreData

/// Dependency Injection Container
class DIContainer: ObservableObject {
    // MARK: - Core Data
    let persistenceController: PersistenceController
    var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    // MARK: - Repositories
    private(set) lazy var taskRepository: TaskRepositoryProtocol = TaskRepository(viewContext: viewContext)
    private(set) lazy var userRepository: UserRepositoryProtocol = UserRepository(viewContext: viewContext)
    
    // MARK: - Use Cases
    private(set) lazy var taskUseCase: TaskUseCaseProtocol = TaskUseCase(
        taskRepository: taskRepository,
        userRepository: userRepository
    )
    
    // MARK: - Services
    private(set) lazy var experienceService = ExperienceService.shared
    private(set) lazy var jobSystemService = JobSystemService.shared
    
    // MARK: - App State
    private(set) lazy var appState = AppState(viewContext: viewContext)
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Factory Methods
    
    /// TaskUseCaseのファクトリーメソッド
    func makeTaskUseCase() -> TaskUseCaseProtocol {
        return taskUseCase
    }
    
    /// AppStateのファクトリーメソッド
    func makeAppState() -> AppState {
        return appState
    }
}

// MARK: - Environment Key
struct DIContainerKey: EnvironmentKey {
    static let defaultValue = DIContainer()
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}