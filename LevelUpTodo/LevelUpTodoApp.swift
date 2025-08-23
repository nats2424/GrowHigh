import SwiftUI
import CoreData

@main
struct LevelUpTodoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    cleanupOldCompletedTasks()
                }
        }
    }
    
    private func cleanupOldCompletedTasks() {
        let context = persistenceController.container.viewContext
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        
        let request: NSFetchRequest<TodoItem> = TodoItem.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == true AND completedAt < %@", oneDayAgo as NSDate)
        
        do {
            let oldTasks = try context.fetch(request)
            for task in oldTasks {
                context.delete(task)
            }
            
            if !oldTasks.isEmpty {
                try context.save()
                print("Cleaned up \(oldTasks.count) completed tasks older than 1 day")
            }
        } catch {
            print("Failed to cleanup old tasks: \(error)")
        }
    }
}