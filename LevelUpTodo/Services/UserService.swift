import CoreData
import Foundation

class UserService: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    func getOrCreateUser() -> User {
        let request: NSFetchRequest<User> = User.fetchRequest()
        
        if let existingUser = try? viewContext.fetch(request).first {
            return existingUser
        }
        
        // 新しいユーザーを作成
        let newUser = User(context: viewContext)
        newUser.name = "新しいハンター"
        newUser.level = 1
        newUser.experience = 0
        newUser.experienceToNextLevel = 100
        newUser.totalExperience = 0
        newUser.currentAvatarType = "default"
        newUser.createdAt = Date()
        
        // 初期アバターを作成
        createInitialAvatars(for: newUser)
        
        try? viewContext.save()
        return newUser
    }
    
    func addExperience(to user: User, amount: Int) -> Bool {
        user.experience += Int32(amount)
        user.totalExperience += Int32(amount)
        
        var didLevelUp = false
        
        // レベルアップチェック
        while user.experience >= user.experienceToNextLevel {
            user.experience -= user.experienceToNextLevel
            user.level += 1
            user.experienceToNextLevel = calculateNextLevelRequirement(level: Int(user.level))
            didLevelUp = true
            
            // アバターの解放チェック
            unlockAvatarsForLevel(user: user, level: Int(user.level))
        }
        
        try? viewContext.save()
        return didLevelUp
    }
    
    func subtractExperience(from user: User, amount: Int) {
        user.experience = max(0, user.experience - Int32(amount))
        user.totalExperience = max(0, user.totalExperience - Int32(amount))
        
        try? viewContext.save()
    }
    
    private func calculateNextLevelRequirement(level: Int) -> Int32 {
        // レベルに応じて必要経験値が増加する計算式
        return Int32(100 + (level - 1) * 50)
    }
    
    private func createInitialAvatars(for user: User) {
        let avatarData = [
            ("default", "デフォルトハンター", 1),
            ("warrior", "戦士", 5),
            ("mage", "魔法使い", 10),
            ("assassin", "暗殺者", 15),
            ("paladin", "パラディン", 20),
            ("archmage", "大魔法使い", 30)
        ]
        
        for (type, name, requiredLevel) in avatarData {
            let avatar = Avatar(context: viewContext)
            avatar.avatarType = type
            avatar.name = name
            avatar.requiredLevel = Int32(requiredLevel)
            avatar.isUnlocked = (requiredLevel == 1) // デフォルトは最初から解放
            avatar.imageURL = type
            avatar.user = user
        }
    }
    
    private func unlockAvatarsForLevel(user: User, level: Int) {
        let request: NSFetchRequest<Avatar> = Avatar.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND requiredLevel <= %d AND isUnlocked == NO", user, level)
        
        if let avatarsToUnlock = try? viewContext.fetch(request) {
            for avatar in avatarsToUnlock {
                avatar.isUnlocked = true
            }
        }
    }
    
    func updateUserName(_ user: User, newName: String) {
        user.name = newName
        try? viewContext.save()
    }
    
    func changeAvatar(_ user: User, to avatarType: String) {
        // アバターが解放されているかチェック
        let request: NSFetchRequest<Avatar> = Avatar.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND avatarType == %@ AND isUnlocked == YES", user, avatarType)
        
        if let avatar = try? viewContext.fetch(request).first {
            user.currentAvatarType = avatarType
            try? viewContext.save()
        }
    }
}