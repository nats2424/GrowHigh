import SwiftUI

struct BottomNavigationView: View {
    let currentPage: String
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        HStack(spacing: 0) {
            // ホーム
            tabBarButton(
                icon: "house.fill",
                title: "ホーム",
                isSelected: currentPage == "Home"
            ) {
                // ホームに戻る（NavigationPathをクリア）
                navigationPath = NavigationPath()
            }
            
            // タスク
            tabBarButton(
                icon: "list.bullet",
                title: "タスク",
                isSelected: currentPage == "TodoList"
            ) {
                // タスクリスト画面への遷移
                if currentPage != "TodoList" {
                    navigationPath.append("TodoList")
                }
            }
            
            // 統計
            tabBarButton(
                icon: "chart.bar",
                title: "統計",
                isSelected: currentPage == "Stats"
            ) {
                // 統計画面への遷移
                if currentPage != "Stats" {
                    navigationPath.append("Stats")
                }
            }
            
            // 設定
            tabBarButton(
                icon: "gearshape.fill",
                title: "設定",
                isSelected: currentPage == "Settings"
            ) {
                // 設定画面への遷移
                if currentPage != "Settings" {
                    navigationPath.append("Settings")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.8))
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    @ViewBuilder
    private func tabBarButton(
        icon: String,
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .cyan : .gray)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? .cyan : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}