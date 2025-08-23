import Foundation
import Combine

extension Notification.Name {
    static let createSampleTask = Notification.Name("createSampleTask")
}

class TutorialManager: ObservableObject {
    @Published var currentStep: TutorialStep = .genderSelection
    @Published var isActive: Bool = false
    @Published var shouldShowGenderSelection: Bool = false
    @Published var sampleTaskId: String? = nil
    
    static let shared = TutorialManager()
    
    private init() {
        checkInitialState()
    }
    
    func checkInitialState() {
        let hasSeenTutorial = UserDefaults.standard.bool(forKey: "hasSeenTutorial")
        let hasSelectedGender = UserDefaults.standard.string(forKey: "selectedGender") != nil
        
        if !hasSeenTutorial {
            if !hasSelectedGender {
                // 性別選択から開始
                shouldShowGenderSelection = true
                currentStep = .genderSelection
            } else {
                // 性別選択済みなので概要から開始
                isActive = true
                currentStep = .appOverview
            }
        }
    }
    
    func startTutorial(from step: TutorialStep = .appOverview) {
        currentStep = step
        isActive = true
    }
    
    func nextStep() {
        guard let nextStep = TutorialStep(rawValue: currentStep.rawValue + 1) else {
            completeTutorial()
            return
        }
        
        currentStep = nextStep
        
        if currentStep == .finished {
            completeTutorial()
        }
    }
    
    func skipTutorial() {
        guard currentStep.isSkippable else { return }
        completeTutorial()
    }
    
    func completeTutorial() {
        isActive = false
        shouldShowGenderSelection = false
        currentStep = .finished
        UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
        
        // サンプルタスクがあれば削除
        if let sampleTaskId = sampleTaskId {
            removeSampleTask(id: sampleTaskId)
        }
    }
    
    func onGenderSelected(_ gender: Gender) {
        shouldShowGenderSelection = false
        UserDefaults.standard.set(gender.rawValue, forKey: "selectedGender")
        
        // チュートリアル開始
        startTutorial(from: .appOverview)
    }
    
    func createSampleTask() {
        // サンプルタスクのID生成
        sampleTaskId = UUID().uuidString
        
        // サンプルタスク作成をトリガー（NotificationCenterを使用）
        NotificationCenter.default.post(
            name: .createSampleTask,
            object: nil,
            userInfo: ["taskId": sampleTaskId ?? UUID().uuidString]
        )
    }
    
    private func removeSampleTask(id: String) {
        // Core Dataからサンプルタスクを削除
        // 実装はCore Dataアクセス部分で行う
    }
    
    // 各ステップの説明文を取得
    func getStepDescription() -> String {
        switch currentStep {
        case .genderSelection:
            return "性別を選択してください"
        case .appOverview:
            return "ToDoリストとして使えるアプリです。\nタスクを達成すると経験値を取得できます。\nアバターを自分自身だと思いながら、現実世界でも成長しましょう！"
        case .addSampleTask:
            return "まずはサンプルタスクを追加してみましょう。"
        case .completeSampleTask:
            return "タスクが終わったら完了にしましょう！"
        case .experienceGain:
            return "タスク完了で経験値を獲得できます。"
        case .levelUpExplanation:
            return "経験値がたまると、あなたのレベルが上がります！"
        case .finished:
            return "チュートリアル完了！"
        }
    }
    
    // 各ステップのタイトルを取得
    func getStepTitle() -> String {
        switch currentStep {
        case .genderSelection:
            return "プロフィール設定"
        case .appOverview:
            return "LevelUp Todo とは？"
        case .addSampleTask:
            return "タスクを追加する"
        case .completeSampleTask:
            return "タスクを完了する"
        case .experienceGain:
            return "経験値を獲得"
        case .levelUpExplanation:
            return "レベルアップ"
        case .finished:
            return "準備完了"
        }
    }
}