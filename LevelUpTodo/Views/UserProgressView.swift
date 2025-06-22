import SwiftUI

struct UserProgressView: View {
    @ObservedObject var user: User
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(user.name ?? "ハンター")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("レベル \(user.level)")
                        .font(.title3)
                        .foregroundColor(.purple)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("総経験値")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(user.totalExperience)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            
            // 経験値バー
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("次のレベルまで")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(user.experience) / \(user.experienceToNextLevel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: progressWidth(geometry.size.width), height: 8)
                            .animation(.easeInOut(duration: 0.5), value: user.experience)
                    }
                    .cornerRadius(4)
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(radius: 2)
        )
    }
    
    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        guard user.experienceToNextLevel > 0 else { return 0 }
        let progress = CGFloat(user.experience) / CGFloat(user.experienceToNextLevel)
        return totalWidth * min(progress, 1.0)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let user = User(context: context)
    user.name = "テストハンター"
    user.level = 5
    user.experience = 150
    user.experienceToNextLevel = 300
    user.totalExperience = 1250
    
    return UserProgressView(user: user)
        .padding()
}