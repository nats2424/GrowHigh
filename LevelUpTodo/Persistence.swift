import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // プレビュー用のサンプルデータを作成
        let user = User(context: viewContext)
        user.name = "テストユーザー"
        user.level = 5
        user.experience = 250
        user.experienceToNextLevel = 300
        
        let todo1 = TodoItem(context: viewContext)
        todo1.title = "サンプルタスク1"
        todo1.isCompleted = false
        todo1.experienceReward = 50
        todo1.createdAt = Date()
        
        let todo2 = TodoItem(context: viewContext)
        todo2.title = "完了したタスク"
        todo2.isCompleted = true
        todo2.experienceReward = 30
        todo2.createdAt = Date().addingTimeInterval(-86400)
        todo2.completedAt = Date().addingTimeInterval(-3600)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LevelUpTodo")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}