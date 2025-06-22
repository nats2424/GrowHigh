import SwiftUI
import CoreData

struct AvatarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Avatar.requiredLevel, ascending: true)],
        animation: .default)
    private var avatars: FetchedResults<Avatar>
    
    @State private var selectedAvatarType = "default"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let user = getUser() {
                        // 現在のアバター表示
                        CurrentAvatarView(user: user)
                            .padding()
                        
                        // 利用可能なアバターリスト
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 16) {
                            ForEach(avatars) { avatar in
                                AvatarCard(avatar: avatar, user: user, isSelected: avatar.avatarType == user.currentAvatarType)
                                    .onTapGesture {
                                        if avatar.isUnlocked {
                                            selectAvatar(avatar, user: user)
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("アバター")
            .onAppear {
                setupInitialAvatars()
            }
        }
    }
    
    private func getUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        return try? viewContext.fetch(request).first
    }
    
    private func selectAvatar(_ avatar: Avatar, user: User) {
        user.currentAvatarType = avatar.avatarType
        try? viewContext.save()
    }
    
    private func setupInitialAvatars() {
        guard avatars.isEmpty else { return }
        
        let avatarData = [
            ("default", "デフォルトハンター", 1, true),
            ("warrior", "戦士", 5, false),
            ("mage", "魔法使い", 10, false),
            ("assassin", "暗殺者", 15, false),
            ("paladin", "パラディン", 20, false),
            ("archmage", "大魔法使い", 30, false)
        ]
        
        for (type, name, level, unlocked) in avatarData {
            let avatar = Avatar(context: viewContext)
            avatar.avatarType = type
            avatar.name = name
            avatar.requiredLevel = Int32(level)
            avatar.isUnlocked = unlocked
            avatar.imageURL = type // プレースホルダー
        }
        
        try? viewContext.save()
    }
}

struct CurrentAvatarView: View {
    @ObservedObject var user: User
    
    var body: some View {
        VStack(spacing: 16) {
            // アバター画像プレースホルダー
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.purple, .blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: avatarIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                )
                .shadow(radius: 8)
            
            VStack(spacing: 4) {
                Text(avatarName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("レベル \(user.level)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(radius: 4)
        )
    }
    
    private var avatarIcon: String {
        switch user.currentAvatarType {
        case "warrior":
            return "sword.fill"
        case "mage":
            return "wand.and.stars"
        case "assassin":
            return "eye.fill"
        case "paladin":
            return "shield.fill"
        case "archmage":
            return "sparkles"
        default:
            return "person.fill"
        }
    }
    
    private var avatarName: String {
        switch user.currentAvatarType {
        case "warrior":
            return "戦士"
        case "mage":
            return "魔法使い"
        case "assassin":
            return "暗殺者"
        case "paladin":
            return "パラディン"
        case "archmage":
            return "大魔法使い"
        default:
            return "デフォルトハンター"
        }
    }
}

struct AvatarCard: View {
    @ObservedObject var avatar: Avatar
    @ObservedObject var user: User
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(avatar.isUnlocked ? 
                    LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(gradient: Gradient(colors: [.gray, .gray.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Group {
                        if avatar.isUnlocked {
                            Image(systemName: avatarIcon)
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                )
            
            VStack(spacing: 2) {
                Text(avatar.name ?? "")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(avatar.isUnlocked ? .primary : .secondary)
                
                if !avatar.isUnlocked {
                    Text("Lv.\(avatar.requiredLevel)で解放")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.purple.opacity(0.2) : Color.gray.opacity(0.1))
                .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
        )
        .scaleEffect(avatar.isUnlocked ? 1.0 : 0.9)
        .opacity(avatar.isUnlocked ? 1.0 : 0.6)
    }
    
    private var avatarIcon: String {
        switch avatar.avatarType {
        case "warrior":
            return "sword.fill"
        case "mage":
            return "wand.and.stars"
        case "assassin":
            return "eye.fill"
        case "paladin":
            return "shield.fill"
        case "archmage":
            return "sparkles"
        default:
            return "person.fill"
        }
    }
}

#Preview {
    AvatarView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}