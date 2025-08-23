import Foundation

enum Gender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female" 
    case unspecified = "unspecified"
    
    var displayName: String {
        switch self {
        case .male:
            return "男"
        case .female:
            return "女"
        case .unspecified:
            return "回答しない"
        }
    }
    
    var defaultAvatarImage: String {
        switch self {
        case .male, .unspecified:
            return "boy1"
        case .female:
            return "girl1"
        }
    }
}

enum TutorialStep: Int, CaseIterable {
    case genderSelection = 0
    case appOverview = 1
    case addSampleTask = 2
    case completeSampleTask = 3
    case experienceGain = 4
    case levelUpExplanation = 5
    case finished = 6
    
    var isSkippable: Bool {
        // 性別選択は必須、それ以降はスキップ可能
        return self != .genderSelection
    }
}