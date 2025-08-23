import Foundation

class LevelUpMessageService {
    static let shared = LevelUpMessageService()
    
    private init() {}
    
    // MARK: - Template Selection and Message Generation
    
    /// 統計情報に基づいて適切なメッセージテンプレートを選択し、変数を置換してメッセージを生成
    func generateLevelUpMessage(for statistics: LevelUpStatistics) -> (title: String, message: String, nextActionPrompt: String, iconEmoji: String, backgroundColor: String) {
        let template = selectAppropriateTemplate(for: statistics)
        
        let processedTitle = substituteVariables(in: template.title, with: statistics)
        let processedMessage = substituteVariables(in: template.message, with: statistics)
        let processedActionPrompt = substituteVariables(in: template.nextActionPrompt, with: statistics)
        
        return (
            title: processedTitle,
            message: processedMessage,
            nextActionPrompt: processedActionPrompt,
            iconEmoji: template.iconEmoji,
            backgroundColor: template.backgroundColor
        )
    }
    
    // MARK: - Template Selection Logic
    
    /// 統計情報に基づいて最適なテンプレートを選択
    private func selectAppropriateTemplate(for statistics: LevelUpStatistics) -> LevelUpMessageTemplate {
        let templates = LevelUpMessageTemplate.templates
        
        // 優先度順でテンプレートを選択
        
        // 1. 最高レベル到達（Lv100）
        if statistics.currentLevel >= 100 {
            return templates.first { $0.id == "maximum_level" } ?? templates[0]
        }
        
        // 2. 初回職業獲得（Lv5）
        if statistics.isFirstJobAcquisition {
            return templates.first { $0.id == "first_job_acquisition" } ?? templates[0]
        }
        
        // 3. 連続達成による昇格
        if statistics.isConsecutiveStreak && statistics.consecutiveDays >= 14 {
            return templates.first { $0.id == "consecutive_streak" } ?? templates[0]
        }
        
        // 4. 職業系統特化テンプレート
        if statistics.currentLevel >= 10 {
            let categoryTemplate = selectCategorySpecificTemplate(for: statistics.jobCategory)
            if let template = categoryTemplate {
                return template
            }
        }
        
        // 5. 一般的な職業進化
        if statistics.isJobEvolution {
            return templates.first { $0.id == "job_evolution" } ?? templates[0]
        }
        
        // 6. デフォルト（一般的なレベルアップ）
        return templates.first { $0.id == "job_evolution" } ?? templates[0]
    }
    
    /// 職業カテゴリに特化したテンプレートを選択
    private func selectCategorySpecificTemplate(for category: JobCategory) -> LevelUpMessageTemplate? {
        let templates = LevelUpMessageTemplate.templates
        
        switch category {
        case .fighter:
            return templates.first { $0.id == "fighter_specific" }
        case .scholar:
            return templates.first { $0.id == "scholar_specific" }
        case .explorer:
            return templates.first { $0.id == "explorer_specific" }
        case .master:
            return templates.first { $0.id == "master_specific" }
        case .artist:
            return templates.first { $0.id == "artist_specific" }
        }
    }
    
    // MARK: - Variable Substitution
    
    /// テンプレート内の変数を実際の値で置換
    private func substituteVariables(in template: String, with statistics: LevelUpStatistics) -> String {
        var result = template
        
        // 主要変数の置換
        result = result.replacingOccurrences(of: "{daysSinceFirstTask}", with: "\(statistics.daysSinceFirstTask)")
        result = result.replacingOccurrences(of: "{mostCompletedTaskType}", with: statistics.mostCompletedTaskType.displayName)
        result = result.replacingOccurrences(of: "{currentLevel}", with: "\(statistics.currentLevel)")
        result = result.replacingOccurrences(of: "{jobTitle}", with: statistics.jobTitle)
        result = result.replacingOccurrences(of: "{previousJobTitle}", with: statistics.previousJobTitle ?? "前職")
        result = result.replacingOccurrences(of: "{improvementMetric}", with: statistics.improvementMetric)
        
        // 追加統計変数の置換
        result = result.replacingOccurrences(of: "{consecutiveDays}", with: "\(statistics.consecutiveDays)")
        result = result.replacingOccurrences(of: "{totalTasksCompleted}", with: "\(statistics.totalTasksCompleted)")
        result = result.replacingOccurrences(of: "{completionRate}", with: String(format: "%.1f%%", statistics.completionRate))
        result = result.replacingOccurrences(of: "{averageCompletionTime}", with: String(format: "%.1f時間", statistics.averageCompletionTime))
        
        // 動的計算が必要な変数の置換
        result = result.replacingOccurrences(of: "{nextTargetLevel}", with: "\(statistics.currentLevel + 5)")
        result = result.replacingOccurrences(of: "{currentLevel + 5}", with: "\(statistics.currentLevel + 5)")
        
        return result
    }
    
    // MARK: - Helper Methods for Advanced Templates
    
    /// 挫折後復帰のパターンを検知
    func isRecoveryAfterBreak(statistics: LevelUpStatistics) -> Bool {
        // 簡易実装: 長期間のブランクがあった場合
        return statistics.daysSinceFirstTask > 30 && statistics.consecutiveDays < 7
    }
    
    /// レベルアップのペースを評価
    func evaluateLevelUpPace(statistics: LevelUpStatistics) -> String {
        let daysPerLevel = Double(statistics.daysSinceFirstTask) / Double(statistics.currentLevel)
        
        switch daysPerLevel {
        case 0..<3:
            return "驚異的なペース"
        case 3..<7:
            return "優秀なペース"
        case 7..<14:
            return "安定したペース"
        case 14..<30:
            return "着実なペース"
        default:
            return "マイペース"
        }
    }
    
    /// タスクタイプの多様性を評価
    func evaluateTaskDiversity(statistics: LevelUpStatistics) -> String {
        // この実装では簡略化
        // 実際は複数のタスクタイプの分布を分析する必要がある
        return "バランスよく"
    }
}

// MARK: - Message Formatting Extensions

extension LevelUpMessageService {
    
    /// メッセージをフォーマットして視認性を向上
    func formatMessage(_ message: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: message)
        
        // 基本的なフォーマット設定
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .center
        
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attributedString.length)
        )
        
        // 重要な数値を太字にハイライト
        let boldPattern = "\\d+(?:日|時間|%|個|レベル)"
        
        do {
            let regex = try NSRegularExpression(pattern: boldPattern)
            let matches = regex.matches(
                in: message,
                range: NSRange(location: 0, length: message.count)
            )
            
            for match in matches {
                attributedString.addAttribute(
                    .font,
                    value: UIFont.boldSystemFont(ofSize: 16),
                    range: match.range
                )
            }
        } catch {
            print("Regex error in message formatting: \(error)")
        }
        
        return attributedString
    }
    
    /// 職業名を適切な色でハイライト
    func highlightJobTitle(_ title: String, category: JobCategory) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: title)
        
        let color: UIColor = {
            switch category {
            case .fighter:
                return .systemRed
            case .scholar:
                return .systemPurple
            case .explorer:
                return .systemGreen
            case .master:
                return .systemBlue
            case .artist:
                return .systemPink
            }
        }()
        
        // 職業名らしき部分を色付け
        if let jobRange = title.range(of: "「.*」", options: .regularExpression) {
            let nsRange = NSRange(jobRange, in: title)
            attributedString.addAttribute(.foregroundColor, value: color, range: nsRange)
            attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 18), range: nsRange)
        }
        
        return attributedString
    }
}