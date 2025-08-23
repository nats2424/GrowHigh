import SwiftUI

struct TutorialOverlayView: View {
    @StateObject private var tutorialManager = TutorialManager.shared
    @State private var highlightRect: CGRect = .zero
    @State private var showContent = false
    
    let highlightTarget: TutorialHighlightTarget?
    
    var body: some View {
        if tutorialManager.isActive {
            ZStack {
                // セミトランスペアレント背景
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // 背景タップで次へ（概要ステップのみ）
                        if tutorialManager.currentStep == .appOverview {
                            tutorialManager.nextStep()
                        }
                    }
                
                // ハイライト部分の切り抜き
                if let target = highlightTarget {
                    highlightOverlay(for: target)
                }
                
                // チュートリアル説明UI
                VStack {
                    Spacer()
                    tutorialContentView
                    Spacer().frame(height: 100)
                }
                .opacity(showContent ? 1.0 : 0.0)
                .scaleEffect(showContent ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 0.5), value: showContent)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showContent = true
                }
            }
        }
    }
    
    private var tutorialContentView: some View {
        VStack(spacing: 20) {
            // タイトル
            Text(tutorialManager.getStepTitle())
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // 説明文
            Text(tutorialManager.getStepDescription())
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            // ボタン領域
            HStack(spacing: 20) {
                // スキップボタン（スキップ可能なステップのみ）
                if tutorialManager.currentStep.isSkippable {
                    Button("スキップ") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showContent = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            tutorialManager.skipTutorial()
                        }
                    }
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray.opacity(0.5), lineWidth: 1)
                    )
                }
                
                Spacer()
                
                // 次へボタン
                Button(getNextButtonText()) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showContent = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        handleNextAction()
                    }
                }
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.cyan, .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
                .shadow(color: .cyan.opacity(0.3), radius: 5)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 25)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.cyan.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .cyan.opacity(0.2), radius: 10)
        )
        .padding(.horizontal, 20)
    }
    
    private func highlightOverlay(for target: TutorialHighlightTarget) -> some View {
        GeometryReader { geometry in
            let targetFrame = getTargetFrame(for: target, in: geometry)
            
            Path { path in
                path.addRect(CGRect(origin: .zero, size: geometry.size))
                path.addRoundedRect(
                    in: targetFrame.insetBy(dx: -10, dy: -10),
                    cornerSize: CGSize(width: 12, height: 12)
                )
            }
            .fill(Color.clear, style: FillStyle(eoFill: true))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.cyan, lineWidth: 2)
                    .frame(
                        width: targetFrame.width + 20,
                        height: targetFrame.height + 20
                    )
                    .position(
                        x: targetFrame.midX,
                        y: targetFrame.midY
                    )
                    .shadow(color: .cyan.opacity(0.5), radius: 5)
            )
        }
    }
    
    private func getTargetFrame(for target: TutorialHighlightTarget, in geometry: GeometryProxy) -> CGRect {
        switch target {
        case .addTaskButton:
            // 画面右下のフローティング追加ボタン位置を推定
            return CGRect(
                x: geometry.size.width - 96,
                y: geometry.size.height - 200,
                width: 56,
                height: 56
            )
        case .taskCheckbox:
            // タスクリストの最初のタスクのチェックボックス位置を推定
            return CGRect(
                x: 30,
                y: geometry.size.height * 0.4,
                width: 30,
                height: 30
            )
        case .experienceBar:
            // 画面上部のプロフィール部分の経験値バー位置を推定
            return CGRect(
                x: 40,
                y: 120,
                width: geometry.size.width - 80,
                height: 40
            )
        case .levelDisplay:
            // レベル表示部分
            return CGRect(
                x: 40,
                y: 80,
                width: 100,
                height: 30
            )
        }
    }
    
    private func getNextButtonText() -> String {
        switch tutorialManager.currentStep {
        case .appOverview:
            return "始める"
        case .addSampleTask:
            return "サンプルを追加"
        case .completeSampleTask:
            return "完了してみる"
        case .experienceGain:
            return "次へ"
        case .levelUpExplanation:
            return "完了"
        default:
            return "次へ"
        }
    }
    
    private func handleNextAction() {
        switch tutorialManager.currentStep {
        case .addSampleTask:
            // サンプルタスク作成をトリガー
            tutorialManager.createSampleTask()
            tutorialManager.nextStep()
        default:
            tutorialManager.nextStep()
        }
    }
}

enum TutorialHighlightTarget {
    case addTaskButton
    case taskCheckbox
    case experienceBar
    case levelDisplay
}

#Preview {
    TutorialOverlayView(highlightTarget: .addTaskButton)
}