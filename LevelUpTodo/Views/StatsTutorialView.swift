import SwiftUI
import CoreData

struct StatsTutorialView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    
    @State private var currentStep: Int = 1
    @State private var showingStats = false
    @State private var hasViewedStats = false
    
    private let totalSteps = 2
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.cyan.opacity(0.6),
                    Color.blue.opacity(0.4),
                    Color.purple.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // プログレスバー
                ProgressView(value: Double(currentStep), total: Double(totalSteps))
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(height: 8)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(4)
                    .padding(.horizontal, 40)
                    .padding(.top, 50)
                
                Text("最終チュートリアル \(currentStep)/\(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // ステップ別コンテンツ
                Group {
                    switch currentStep {
                    case 1:
                        step1Content
                    case 2:
                        step2Content
                    default:
                        EmptyView()
                    }
                }
                
                Spacer()
                
                // 次へボタン（条件付き表示）
                if shouldShowNextButton() {
                    Button(action: {
                        nextStep()
                    }) {
                        Text(currentStep == totalSteps ? "チュートリアル完了！🎉" : "次へ")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            )
                    }
                    .padding(.horizontal, 40)
                }
                
                Button(action: {
                    completeTutorial()
                }) {
                    Text("スキップ")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .underline()
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingStats) {
            NavigationView {
                StatsView()
                    .navigationTitle("ステータス")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("閉じる") {
                                showingStats = false
                                hasViewedStats = true
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - Step Contents
    
    @ViewBuilder
    private var step1Content: some View {
        VStack(spacing: 20) {
            Text("📊")
                .font(.system(size: 60))
            
            Text("右上のステータスボタンをタップして、あなたの成長を見てみましょう！")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("あなたの現在のレベル、経験値、ジョブなどが確認できます")
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // ステータス画面プレビュー
            VStack(spacing: 15) {
                Text("📋 ステータス画面で確認できること")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 10) {
                    HStack {
                        Text("⭐")
                        Text("現在のレベル")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    HStack {
                        Text("💫")
                        Text("経験値とプログレス")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    HStack {
                        Text("👤")
                        Text("現在のジョブ・職業")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    HStack {
                        Text("🏆")
                        Text("達成したタスク数")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                )
            }
            .padding(.horizontal, 20)
            
            Button(action: {
                showingStats = true
            }) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                    Text("ステータスを確認する")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cyan.opacity(0.8))
                        .shadow(color: .cyan.opacity(0.3), radius: 10, x: 0, y: 5)
                )
            }
        }
        .padding(.horizontal, 40)
    }
    
    @ViewBuilder
    private var step2Content: some View {
        VStack(spacing: 20) {
            Text("🎊")
                .font(.system(size: 60))
            
            Text("チュートリアル完了おめでとうございます！")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                Text("🎮 これからできること")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 10) {
                    HStack {
                        Text("📝")
                        Text("タスクを追加・管理")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    HStack {
                        Text("⬆️")
                        Text("タスク達成でレベルアップ")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    HStack {
                        Text("🏅")
                        Text("新しいジョブの解放")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    HStack {
                        Text("👤")
                        Text("アバターの変更")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                )
            }
            .padding(.horizontal, 20)
            
            Text("毎日のタスクでコツコツとレベルアップして、\nRPGのような成長を楽しんでください！")
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 10)
            
            Text("頑張って冒険者として成長していきましょう🚀")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Helper Functions
    
    private func shouldShowNextButton() -> Bool {
        switch currentStep {
        case 1:
            // ステータス画面を見たら次へボタンを表示
            return hasViewedStats
        case 2:
            // 最終ステップでは常に表示
            return true
        default:
            return false
        }
    }
    
    private func nextStep() {
        if currentStep < totalSteps {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            completeTutorial()
        }
    }
    
    private func completeTutorial() {
        UserDefaults.standard.set(true, forKey: "hasCompletedStatsTutorial")
        UserDefaults.standard.set(true, forKey: "hasCompletedAllTutorials")
        isPresented = false
    }
}

#Preview {
    StatsTutorialView(isPresented: .constant(true))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}