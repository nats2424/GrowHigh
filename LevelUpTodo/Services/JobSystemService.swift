import Foundation
import CoreData

// MARK: - Job System Models

struct Job {
    let id: String
    let name: String
    let category: JobCategory
    let requiredLevel: Int
    let avatarImageName: String
    let description: String
}

enum JobCategory: String, CaseIterable {
    case fighter = "fighter"
    case scholar = "scholar"  
    case explorer = "explorer"
    case master = "master"
    case artist = "artist"
    
    var displayName: String {
        switch self {
        case .fighter: return "ファイター系"
        case .scholar: return "スカラー系"
        case .explorer: return "エクスプローラー系" 
        case .master: return "マスター系"
        case .artist: return "アーティスト系"
        }
    }
    
    var correspondingStatType: StatType {
        switch self {
        case .fighter: return .strength
        case .scholar: return .intelligence
        case .explorer: return .endurance
        case .master: return .focus
        case .artist: return .creativity
        }
    }
}

enum StatType {
    case strength    // 筋力
    case intelligence // 知力
    case endurance   // 持久力
    case focus       // 集中力
    case creativity  // 創造力
}

// MARK: - Job System Service

class JobSystemService {
    static let shared = JobSystemService()
    private init() {}
    
    // MARK: - Job Definitions
    
    private let jobProgression: [JobCategory: [Job]] = [
        .fighter: [
            Job(id: "fighter_5", name: "見習い戦士", category: .fighter, requiredLevel: 5, avatarImageName: "warrior_male", description: "戦いの道を歩み始めた見習い"),
            Job(id: "fighter_10", name: "戦士", category: .fighter, requiredLevel: 10, avatarImageName: "warrior_male", description: "基礎を身につけた戦士"),
            Job(id: "fighter_15", name: "剣士", category: .fighter, requiredLevel: 15, avatarImageName: "warrior_female", description: "剣術に長けた剣士"),
            Job(id: "fighter_20", name: "騎士", category: .fighter, requiredLevel: 20, avatarImageName: "knight_male", description: "誇り高き騎士"),
            Job(id: "fighter_30", name: "パラディン", category: .fighter, requiredLevel: 30, avatarImageName: "knight_male", description: "聖なる力を持つ聖騎士"),
            Job(id: "fighter_50", name: "聖騎士", category: .fighter, requiredLevel: 50, avatarImageName: "knight_female", description: "神に選ばれし聖騎士"),
            Job(id: "fighter_70", name: "武神", category: .fighter, requiredLevel: 70, avatarImageName: "knight_male", description: "武の極みに達した神"),
            Job(id: "fighter_90", name: "伝説の戦士", category: .fighter, requiredLevel: 90, avatarImageName: "knight_female", description: "語り継がれる伝説の戦士"),
            Job(id: "fighter_100", name: "不敗の英雄", category: .fighter, requiredLevel: 100, avatarImageName: "knight_male", description: "決して敗れぬ英雄")
        ],
        
        .scholar: [
            Job(id: "scholar_5", name: "学徒", category: .scholar, requiredLevel: 5, avatarImageName: "wizard_male", description: "学問の道を歩み始めた学徒"),
            Job(id: "scholar_10", name: "研究者", category: .scholar, requiredLevel: 10, avatarImageName: "wizard_male", description: "知識を探求する研究者"),
            Job(id: "scholar_15", name: "学者", category: .scholar, requiredLevel: 15, avatarImageName: "wizard_female", description: "深い知識を持つ学者"),
            Job(id: "scholar_20", name: "博士", category: .scholar, requiredLevel: 20, avatarImageName: "wizard_female", description: "専門分野を極めた博士"),
            Job(id: "scholar_30", name: "賢者", category: .scholar, requiredLevel: 30, avatarImageName: "archmage_male", description: "智慧に満ちた賢者"),
            Job(id: "scholar_50", name: "大賢者", category: .scholar, requiredLevel: 50, avatarImageName: "archmage_male", description: "偉大なる賢者"),
            Job(id: "scholar_70", name: "魔導師", category: .scholar, requiredLevel: 70, avatarImageName: "archmage_female", description: "魔法の奥義を極めし者"),
            Job(id: "scholar_90", name: "大魔導師", category: .scholar, requiredLevel: 90, avatarImageName: "archmage_female", description: "魔導の頂点に立つ者"),
            Job(id: "scholar_100", name: "真理の探求者", category: .scholar, requiredLevel: 100, avatarImageName: "archmage_male", description: "世界の真理を求める者")
        ],
        
        .explorer: [
            Job(id: "explorer_5", name: "冒険者", category: .explorer, requiredLevel: 5, avatarImageName: "boy1", description: "未知への一歩を踏み出した冒険者"),
            Job(id: "explorer_10", name: "探検家", category: .explorer, requiredLevel: 10, avatarImageName: "thief_male", description: "新天地を求める探検家"),
            Job(id: "explorer_15", name: "レンジャー", category: .explorer, requiredLevel: 15, avatarImageName: "thief_male", description: "自然と共に生きるレンジャー"),
            Job(id: "explorer_20", name: "ガイド", category: .explorer, requiredLevel: 20, avatarImageName: "thief_female", description: "道案内のプロフェッショナル"),
            Job(id: "explorer_30", name: "パスファインダー", category: .explorer, requiredLevel: 30, avatarImageName: "thief_female", description: "新たな道を切り開く者"),
            Job(id: "explorer_50", name: "マスターガイド", category: .explorer, requiredLevel: 50, avatarImageName: "thief_male", description: "最高峰のガイド"),
            Job(id: "explorer_70", name: "地平の開拓者", category: .explorer, requiredLevel: 70, avatarImageName: "thief_female", description: "未踏の地を開拓する者"),
            Job(id: "explorer_90", name: "世界の歩き手", category: .explorer, requiredLevel: 90, avatarImageName: "thief_male", description: "世界を股にかける旅人"),
            Job(id: "explorer_100", name: "無限の旅人", category: .explorer, requiredLevel: 100, avatarImageName: "thief_female", description: "永遠に旅を続ける者")
        ],
        
        .master: [
            Job(id: "master_5", name: "職人見習い", category: .master, requiredLevel: 5, avatarImageName: "guard", description: "技を磨き始めた見習い職人"),
            Job(id: "master_10", name: "職人", category: .master, requiredLevel: 10, avatarImageName: "guard", description: "確かな技術を持つ職人"),
            Job(id: "master_15", name: "熟練工", category: .master, requiredLevel: 15, avatarImageName: "knight_male", description: "熟練した技術者"),
            Job(id: "master_20", name: "マスター", category: .master, requiredLevel: 20, avatarImageName: "knight_male", description: "技術の頂点に立つマスター"),
            Job(id: "master_30", name: "名工", category: .master, requiredLevel: 30, avatarImageName: "knight_female", description: "名声高き名工"),
            Job(id: "master_50", name: "宗匠", category: .master, requiredLevel: 50, avatarImageName: "knight_female", description: "道の真髄を極めし宗匠"),
            Job(id: "master_70", name: "達人", category: .master, requiredLevel: 70, avatarImageName: "archmage_male", description: "技の極致に達した達人"),
            Job(id: "master_90", name: "人間国宝", category: .master, requiredLevel: 90, avatarImageName: "archmage_male", description: "国が認めた至宝"),
            Job(id: "master_100", name: "伝説の匠", category: .master, requiredLevel: 100, avatarImageName: "archmage_female", description: "伝説となった究極の匠")
        ],
        
        .artist: [
            Job(id: "artist_5", name: "創作者", category: .artist, requiredLevel: 5, avatarImageName: "girl1", description: "創造の世界に足を踏み入れた者"),
            Job(id: "artist_10", name: "アーティスト", category: .artist, requiredLevel: 10, avatarImageName: "wizard_female", description: "芸術を愛するアーティスト"),
            Job(id: "artist_15", name: "クリエイター", category: .artist, requiredLevel: 15, avatarImageName: "wizard_female", description: "新しいものを生み出すクリエイター"),
            Job(id: "artist_20", name: "イノベーター", category: .artist, requiredLevel: 20, avatarImageName: "archmage_female", description: "革新をもたらすイノベーター"),
            Job(id: "artist_30", name: "ビジョナリー", category: .artist, requiredLevel: 30, avatarImageName: "archmage_female", description: "未来を見据えるビジョナリー"),
            Job(id: "artist_50", name: "マエストロ", category: .artist, requiredLevel: 50, avatarImageName: "archmage_male", description: "芸術の巨匠"),
            Job(id: "artist_70", name: "天才", category: .artist, requiredLevel: 70, avatarImageName: "archmage_male", description: "天から授かりし才能の持ち主"),
            Job(id: "artist_90", name: "革命家", category: .artist, requiredLevel: 90, avatarImageName: "archmage_female", description: "時代を変える革命家"),
            Job(id: "artist_100", name: "時代の創造主", category: .artist, requiredLevel: 100, avatarImageName: "archmage_female", description: "新たな時代を創造する者")
        ]
    ]
    
    // MARK: - Public Methods
    
    /// ユーザーの現在のレベルに基づいて適切な職業を取得
    func getCurrentJob(for user: User) -> Job? {
        guard user.level >= 5 else { return nil }
        
        let category = getDominantJobCategory(for: user)
        let jobs = jobProgression[category] ?? []
        
        // レベルに応じた最適な職業を見つける
        let availableJobs = jobs.filter { $0.requiredLevel <= user.level }
        return availableJobs.last // 最高レベルの職業を返す
    }
    
    /// ユーザーのステータスに基づいて主要な職業カテゴリを決定
    func getDominantJobCategory(for user: User) -> JobCategory {
        let stats = [
            (value: Int(user.strength), category: JobCategory.fighter),
            (value: Int(user.intelligence), category: JobCategory.scholar),
            (value: Int(user.endurance), category: JobCategory.explorer),
            (value: Int(user.focus), category: JobCategory.master),
            (value: Int(user.creativity), category: JobCategory.artist)
        ]
        
        // 最も高いステータスのカテゴリを返す
        return stats.max(by: { $0.value < $1.value })?.category ?? .fighter
    }
    
    /// レベルアップ時に職業が変更されるかチェック
    func checkForJobPromotion(user: User, previousLevel: Int) -> Job? {
        let currentJob = getCurrentJob(for: user)
        
        // 前のレベルでの職業を取得
        let tempUser = user
        tempUser.level = Int32(previousLevel)
        let previousJob = getCurrentJob(for: tempUser)
        tempUser.level = user.level // 元に戻す
        
        // 職業が変わった場合は新しい職業を返す
        if currentJob?.id != previousJob?.id {
            return currentJob
        }
        
        return nil
    }
    
    /// 特定の職業カテゴリの全職業を取得
    func getJobsForCategory(_ category: JobCategory) -> [Job] {
        return jobProgression[category] ?? []
    }
    
    /// 職業昇格の必要レベルリスト
    func getPromotionLevels() -> [Int] {
        return [5, 10, 15, 20, 30, 50, 70, 90, 100]
    }
    
    /// 次の昇格レベルを取得
    func getNextPromotionLevel(currentLevel: Int) -> Int? {
        let promotionLevels = getPromotionLevels()
        return promotionLevels.first { $0 > currentLevel }
    }
    
    /// 職業に基づいてアバター画像を更新
    func updateAvatarForCurrentJob(user: User) {
        if let currentJob = getCurrentJob(for: user) {
            user.currentAvatarType = currentJob.avatarImageName
        }
    }
}

// MARK: - Job System Extensions

extension User {
    
    /// 現在の職業を取得（計算プロパティ）
    var currentJob: Job? {
        return JobSystemService.shared.getCurrentJob(for: self)
    }
    
    /// 職業カテゴリを取得
    var jobCategory: JobCategory {
        return JobSystemService.shared.getDominantJobCategory(for: self)
    }
    
    /// 次の昇格まで必要なレベル数
    var levelsUntilNextPromotion: Int? {
        if let nextLevel = JobSystemService.shared.getNextPromotionLevel(currentLevel: Int(level)) {
            return nextLevel - Int(level)
        }
        return nil
    }
}