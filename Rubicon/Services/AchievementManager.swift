import Foundation
import SwiftUI

// MARK: - Achievement Definition

enum AchievementCategory: String, CaseIterable, Codable {
    case victories = "Victories"
    case mastery = "Mastery"
    case strategy = "Strategy"
    case dedication = "Dedication"
    case special = "Special"
}

struct Achievement: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let requirement: Int
    var progress: Int
    let isSecret: Bool

    var isUnlocked: Bool {
        progress >= requirement
    }

    var progressPercent: Double {
        min(1.0, Double(progress) / Double(requirement))
    }

    // Achievement color based on category
    var color: Color {
        switch category {
        case .victories: return .orange
        case .mastery: return .purple
        case .strategy: return .blue
        case .dedication: return .green
        case .special: return .yellow
        }
    }
}

// MARK: - Achievement Manager

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    @Published var achievements: [Achievement] = []
    @Published var recentUnlock: Achievement? = nil

    // Stats tracking
    @AppStorage("totalGamesPlayed") var totalGamesPlayed: Int = 0
    @AppStorage("totalWins") var totalWins: Int = 0
    @AppStorage("totalLosses") var totalLosses: Int = 0
    @AppStorage("winStreak") var winStreak: Int = 0
    @AppStorage("bestWinStreak") var bestWinStreak: Int = 0
    @AppStorage("lossStreak") var lossStreak: Int = 0
    @AppStorage("totalCaptures") var totalCaptures: Int = 0
    @AppStorage("totalLocks") var totalLocks: Int = 0
    @AppStorage("totalBreaks") var totalBreaks: Int = 0
    @AppStorage("riverDraws") var riverDraws: Int = 0
    @AppStorage("crossesFormed") var crossesFormed: Int = 0
    @AppStorage("longRoadsFormed") var longRoadsFormed: Int = 0
    @AppStorage("perfectGames") var perfectGames: Int = 0 // Win without losing a stone
    @AppStorage("comebackWins") var comebackWins: Int = 0 // Win after being down 5+ stones
    @AppStorage("quickWins") var quickWins: Int = 0 // Win in under 10 moves
    @AppStorage("beatenBeginner") var beatenBeginner: Bool = false
    @AppStorage("beatenEasy") var beatenEasy: Bool = false
    @AppStorage("beatenMedium") var beatenMedium: Bool = false
    @AppStorage("beatenHard") var beatenHard: Bool = false
    @AppStorage("beatenExpert") var beatenExpert: Bool = false
    @AppStorage("beatenMaster") var beatenMaster: Bool = false
    @AppStorage("eliminationWins") var eliminationWins: Int = 0
    @AppStorage("fortressWins") var fortressWins: Int = 0
    @AppStorage("twinRiversWins") var twinRiversWins: Int = 0
    @AppStorage("starWins") var starWins: Int = 0
    @AppStorage("longRoadWins") var longRoadWins: Int = 0

    private let achievementsKey = "savedAchievements"

    private init() {
        loadAchievements()
    }

    // MARK: - Achievement Definitions

    private func createDefaultAchievements() -> [Achievement] {
        return [
            // Victory Achievements
            Achievement(id: "first_win", name: "First Victory", description: "Win your first game", icon: "trophy.fill", category: .victories, requirement: 1, progress: 0, isSecret: false),
            Achievement(id: "win_10", name: "Rising Champion", description: "Win 10 games", icon: "trophy", category: .victories, requirement: 10, progress: 0, isSecret: false),
            Achievement(id: "win_50", name: "Seasoned Victor", description: "Win 50 games", icon: "trophy.circle.fill", category: .victories, requirement: 50, progress: 0, isSecret: false),
            Achievement(id: "win_100", name: "Centurion", description: "Win 100 games", icon: "star.circle.fill", category: .victories, requirement: 100, progress: 0, isSecret: false),
            Achievement(id: "win_streak_3", name: "Hot Streak", description: "Win 3 games in a row", icon: "flame.fill", category: .victories, requirement: 3, progress: 0, isSecret: false),
            Achievement(id: "win_streak_5", name: "Unstoppable", description: "Win 5 games in a row", icon: "flame.circle.fill", category: .victories, requirement: 5, progress: 0, isSecret: false),
            Achievement(id: "win_streak_10", name: "Legendary Streak", description: "Win 10 games in a row", icon: "bolt.circle.fill", category: .victories, requirement: 10, progress: 0, isSecret: false),

            // Mastery Achievements
            Achievement(id: "beat_beginner", name: "Baby Steps", description: "Defeat Beginner AI", icon: "leaf.fill", category: .mastery, requirement: 1, progress: 0, isSecret: false),
            Achievement(id: "beat_easy", name: "Getting Warmer", description: "Defeat Easy AI", icon: "tortoise.fill", category: .mastery, requirement: 1, progress: 0, isSecret: false),
            Achievement(id: "beat_medium", name: "Worthy Opponent", description: "Defeat Medium AI", icon: "figure.walk", category: .mastery, requirement: 1, progress: 0, isSecret: false),
            Achievement(id: "beat_hard", name: "Hardened Warrior", description: "Defeat Hard AI", icon: "flame.fill", category: .mastery, requirement: 1, progress: 0, isSecret: false),
            Achievement(id: "beat_expert", name: "Expert Slayer", description: "Defeat Expert AI", icon: "crown.fill", category: .mastery, requirement: 1, progress: 0, isSecret: false),
            Achievement(id: "beat_master", name: "Master Conqueror", description: "Defeat Master AI", icon: "bolt.shield.fill", category: .mastery, requirement: 1, progress: 0, isSecret: false),
            Achievement(id: "reach_gold", name: "Golden Path", description: "Reach Gold rank in Ladder", icon: "medal.fill", category: .mastery, requirement: 1, progress: 0, isSecret: false),
            Achievement(id: "reach_diamond", name: "Diamond Mind", description: "Reach Diamond rank in Ladder", icon: "diamond.fill", category: .mastery, requirement: 1, progress: 0, isSecret: false),
            Achievement(id: "reach_grandmaster", name: "Grandmaster", description: "Reach Grandmaster rank", icon: "crown.fill", category: .mastery, requirement: 1, progress: 0, isSecret: false),

            // Strategy Achievements
            Achievement(id: "captures_10", name: "Stone Collector", description: "Capture 10 enemy stones", icon: "hand.raised.fill", category: .strategy, requirement: 10, progress: 0, isSecret: false),
            Achievement(id: "captures_50", name: "Stone Hunter", description: "Capture 50 enemy stones", icon: "target", category: .strategy, requirement: 50, progress: 0, isSecret: false),
            Achievement(id: "captures_100", name: "Stone Predator", description: "Capture 100 enemy stones", icon: "scope", category: .strategy, requirement: 100, progress: 0, isSecret: false),
            Achievement(id: "locks_10", name: "Pattern Protector", description: "Lock 10 patterns", icon: "lock.fill", category: .strategy, requirement: 10, progress: 0, isSecret: false),
            Achievement(id: "locks_50", name: "Master Locksmith", description: "Lock 50 patterns", icon: "lock.shield.fill", category: .strategy, requirement: 50, progress: 0, isSecret: false),
            Achievement(id: "breaks_5", name: "Chain Breaker", description: "Break 5 enemy locks", icon: "hammer.fill", category: .strategy, requirement: 5, progress: 0, isSecret: false),
            Achievement(id: "breaks_20", name: "Lock Destroyer", description: "Break 20 enemy locks", icon: "hammer.circle.fill", category: .strategy, requirement: 20, progress: 0, isSecret: false),
            Achievement(id: "river_10", name: "River Walker", description: "Draw from river 10 times", icon: "drop.fill", category: .strategy, requirement: 10, progress: 0, isSecret: false),

            // Victory Type Achievements
            Achievement(id: "star_win", name: "Stargazer", description: "Win with The Star (Cross)", icon: "star.fill", category: .strategy, requirement: 1, progress: 0, isSecret: false),
            Achievement(id: "long_road_win", name: "Road Builder", description: "Win with The Long Road (5+ Line)", icon: "road.lanes", category: .strategy, requirement: 1, progress: 0, isSecret: false),
            Achievement(id: "fortress_win", name: "Fortress Builder", description: "Win with The Fortress (2 Gates)", icon: "building.columns.fill", category: .strategy, requirement: 1, progress: 0, isSecret: false),
            Achievement(id: "twin_rivers_win", name: "River Master", description: "Win with Twin Rivers (2 Lines)", icon: "water.waves", category: .strategy, requirement: 1, progress: 0, isSecret: false),
            Achievement(id: "elimination_win", name: "Exterminator", description: "Win by elimination", icon: "xmark.circle.fill", category: .strategy, requirement: 1, progress: 0, isSecret: false),

            // Dedication Achievements
            Achievement(id: "games_10", name: "Getting Started", description: "Play 10 games", icon: "gamecontroller.fill", category: .dedication, requirement: 10, progress: 0, isSecret: false),
            Achievement(id: "games_50", name: "Dedicated Player", description: "Play 50 games", icon: "gamecontroller", category: .dedication, requirement: 50, progress: 0, isSecret: false),
            Achievement(id: "games_100", name: "Rubicon Devotee", description: "Play 100 games", icon: "heart.fill", category: .dedication, requirement: 100, progress: 0, isSecret: false),
            Achievement(id: "games_500", name: "Rubicon Addict", description: "Play 500 games", icon: "heart.circle.fill", category: .dedication, requirement: 500, progress: 0, isSecret: false),

            // Special/Secret Achievements
            Achievement(id: "perfect_game", name: "Flawless Victory", description: "Win without losing any stones", icon: "sparkles", category: .special, requirement: 1, progress: 0, isSecret: true),
            Achievement(id: "comeback_win", name: "Against All Odds", description: "Win after being down 5+ stones", icon: "arrow.up.heart.fill", category: .special, requirement: 1, progress: 0, isSecret: true),
            Achievement(id: "quick_win", name: "Speed Demon", description: "Win in under 10 moves", icon: "hare.fill", category: .special, requirement: 1, progress: 0, isSecret: true),
            Achievement(id: "cross_5", name: "Cross Master", description: "Form 5 Crosses in your career", icon: "plus.circle.fill", category: .special, requirement: 5, progress: 0, isSecret: false),
            Achievement(id: "long_road_5", name: "Highway Builder", description: "Form 5 Long Roads (5+ Lines)", icon: "road.lanes.curved.right", category: .special, requirement: 5, progress: 0, isSecret: false),
        ]
    }

    // MARK: - Persistence

    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: achievementsKey),
           let saved = try? JSONDecoder().decode([Achievement].self, from: data) {
            // Merge saved progress with default achievements (in case new ones were added)
            let defaults = createDefaultAchievements()
            achievements = defaults.map { defaultAch in
                if let savedAch = saved.first(where: { $0.id == defaultAch.id }) {
                    var merged = defaultAch
                    merged.progress = savedAch.progress
                    return merged
                }
                return defaultAch
            }
        } else {
            achievements = createDefaultAchievements()
        }
    }

    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: achievementsKey)
        }
    }

    // MARK: - Progress Tracking

    func updateProgress(for achievementId: String, increment: Int = 1) {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId }) else { return }

        let wasUnlocked = achievements[index].isUnlocked
        achievements[index].progress += increment

        if !wasUnlocked && achievements[index].isUnlocked {
            recentUnlock = achievements[index]
            // Clear after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                if self?.recentUnlock?.id == achievementId {
                    self?.recentUnlock = nil
                }
            }
        }

        saveAchievements()
    }

    func setProgress(for achievementId: String, value: Int) {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId }) else { return }

        let wasUnlocked = achievements[index].isUnlocked
        achievements[index].progress = value

        if !wasUnlocked && achievements[index].isUnlocked {
            recentUnlock = achievements[index]
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                if self?.recentUnlock?.id == achievementId {
                    self?.recentUnlock = nil
                }
            }
        }

        saveAchievements()
    }

    // MARK: - Game Event Recording

    func recordGameEnd(won: Bool, difficulty: Int, stonesLost: Int, moveCount: Int, wasDown5Stones: Bool, victoryType: String?) {
        totalGamesPlayed += 1
        updateProgress(for: "games_10")
        updateProgress(for: "games_50")
        updateProgress(for: "games_100")
        updateProgress(for: "games_500")

        if won {
            totalWins += 1
            winStreak += 1
            lossStreak = 0

            if winStreak > bestWinStreak {
                bestWinStreak = winStreak
            }

            updateProgress(for: "first_win")
            updateProgress(for: "win_10")
            updateProgress(for: "win_50")
            updateProgress(for: "win_100")

            // Streak achievements
            setProgress(for: "win_streak_3", value: winStreak)
            setProgress(for: "win_streak_5", value: winStreak)
            setProgress(for: "win_streak_10", value: winStreak)

            // Difficulty achievements
            switch difficulty {
            case 1:
                if !beatenBeginner { beatenBeginner = true; updateProgress(for: "beat_beginner") }
            case 2:
                if !beatenEasy { beatenEasy = true; updateProgress(for: "beat_easy") }
            case 3:
                if !beatenMedium { beatenMedium = true; updateProgress(for: "beat_medium") }
            case 4:
                if !beatenHard { beatenHard = true; updateProgress(for: "beat_hard") }
            case 5:
                if !beatenExpert { beatenExpert = true; updateProgress(for: "beat_expert") }
            case 6:
                if !beatenMaster { beatenMaster = true; updateProgress(for: "beat_master") }
            default: break
            }

            // Special achievements
            if stonesLost == 0 {
                perfectGames += 1
                updateProgress(for: "perfect_game")
            }

            if wasDown5Stones {
                comebackWins += 1
                updateProgress(for: "comeback_win")
            }

            if moveCount < 10 {
                quickWins += 1
                updateProgress(for: "quick_win")
            }

            // Victory type achievements
            if let vType = victoryType {
                switch vType {
                case "The Star":
                    starWins += 1
                    updateProgress(for: "star_win")
                case "The Long Road":
                    longRoadWins += 1
                    updateProgress(for: "long_road_win")
                case "The Fortress":
                    fortressWins += 1
                    updateProgress(for: "fortress_win")
                case "Twin Rivers":
                    twinRiversWins += 1
                    updateProgress(for: "twin_rivers_win")
                case "Elimination":
                    eliminationWins += 1
                    updateProgress(for: "elimination_win")
                default: break
                }
            }
        } else {
            totalLosses += 1
            winStreak = 0
            lossStreak += 1
        }
    }

    func recordCapture(count: Int = 1) {
        totalCaptures += count
        setProgress(for: "captures_10", value: totalCaptures)
        setProgress(for: "captures_50", value: totalCaptures)
        setProgress(for: "captures_100", value: totalCaptures)
    }

    func recordLock() {
        totalLocks += 1
        setProgress(for: "locks_10", value: totalLocks)
        setProgress(for: "locks_50", value: totalLocks)
    }

    func recordBreak() {
        totalBreaks += 1
        setProgress(for: "breaks_5", value: totalBreaks)
        setProgress(for: "breaks_20", value: totalBreaks)
    }

    func recordRiverDraw() {
        riverDraws += 1
        setProgress(for: "river_10", value: riverDraws)
    }

    func recordCrossFormed() {
        crossesFormed += 1
        setProgress(for: "cross_5", value: crossesFormed)
    }

    func recordLongRoadFormed() {
        longRoadsFormed += 1
        setProgress(for: "long_road_5", value: longRoadsFormed)
    }

    func recordLadderRank(_ rank: String) {
        if rank.contains("Gold") {
            updateProgress(for: "reach_gold")
        }
        if rank.contains("Diamond") {
            updateProgress(for: "reach_diamond")
        }
        if rank == "Grandmaster" {
            updateProgress(for: "reach_grandmaster")
        }
    }

    // MARK: - Stats

    var winRate: Double {
        guard totalGamesPlayed > 0 else { return 0 }
        return Double(totalWins) / Double(totalGamesPlayed) * 100
    }

    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var totalAchievements: Int {
        achievements.count
    }

    func achievements(for category: AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }

    // Reset all progress (for testing)
    func resetAll() {
        totalGamesPlayed = 0
        totalWins = 0
        totalLosses = 0
        winStreak = 0
        bestWinStreak = 0
        lossStreak = 0
        totalCaptures = 0
        totalLocks = 0
        totalBreaks = 0
        riverDraws = 0
        crossesFormed = 0
        longRoadsFormed = 0
        perfectGames = 0
        comebackWins = 0
        quickWins = 0
        beatenBeginner = false
        beatenEasy = false
        beatenMedium = false
        beatenHard = false
        beatenExpert = false
        beatenMaster = false
        eliminationWins = 0
        fortressWins = 0
        twinRiversWins = 0
        starWins = 0
        longRoadWins = 0

        achievements = createDefaultAchievements()
        saveAchievements()
    }
}
