import SwiftUI

struct GenderSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    @State private var selectedGender: String = ""
    @State private var showNextStep = false
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.6),
                    Color.blue.opacity(0.4),
                    Color.cyan.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // タイトル
                VStack(spacing: 20) {
                    Text("🎮")
                        .font(.system(size: 60))
                    
                    Text("冒険者登録")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("あなたの性別を選んでください")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // 性別選択ボタン
                VStack(spacing: 20) {
                    // 男性
                    Button(action: {
                        selectedGender = "male"
                        saveGenderAndProceed()
                    }) {
                        HStack {
                            Text("👨")
                                .font(.title)
                            Text("男性")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue.opacity(0.8))
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                    }
                    
                    // 女性
                    Button(action: {
                        selectedGender = "female"
                        saveGenderAndProceed()
                    }) {
                        HStack {
                            Text("👩")
                                .font(.title)
                            Text("女性")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.pink.opacity(0.8))
                                .shadow(color: .pink.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                    }
                    
                    // その他
                    Button(action: {
                        selectedGender = "other"
                        saveGenderAndProceed()
                    }) {
                        HStack {
                            Text("🌟")
                                .font(.title)
                            Text("その他")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.purple.opacity(0.8))
                                .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Text("※この設定は後で変更できます")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 30)
            }
        }
    }
    
    private func saveGenderAndProceed() {
        // UserDefaultsに性別を保存
        UserDefaults.standard.set(selectedGender, forKey: "userGender")
        UserDefaults.standard.set(true, forKey: "hasCompletedGenderSelection")
        
        // ユーザーデータを更新
        updateUserGender()
        
        // 0.5秒後に次の画面に進む
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isPresented = false
            }
        }
    }
    
    private func updateUserGender() {
        let userService = UserService(context: viewContext)
        let user = userService.getOrCreateUser()
        
        // 性別に応じて初期アバタータイプを設定
        switch selectedGender {
        case "male":
            user.currentAvatarType = "starter_male"
        case "female":
            user.currentAvatarType = "starter_female"
        default:
            user.currentAvatarType = "starter_male" // デフォルト
        }
        
        userService.saveContext()
    }
}

#Preview {
    GenderSelectionView(isPresented: .constant(true))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}