import SwiftUI
import RubiconEngine

struct LadderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ladderManager = LadderManager.shared
    @State private var showingGame = false
    @State private var showingRankUp = false
    @State private var showingRankDown = false
    @State private var showingPromoStart = false
    @State private var showingPromoResult = false
    @State private var showingRewards = false
    @State private var lastRankChange: RankChangeResult?
    @State private var newRewards: [LadderReward] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.06, blue: 0.12),
                        Color(red: 0.12, green: 0.08, blue: 0.14),
                        Color(red: 0.06, green: 0.04, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Rank color glow
                RadialGradient(
                    colors: [
                        ladderManager.currentRank.glowColor.opacity(0.25),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Rank Display
                        rankDisplaySection

                        // Promotion Series (if active)
                        if ladderManager.isInPromoSeries {
                            promoSeriesSection
                        }

                        // LP Progress Section
                        lpProgressSection

                        // Stats Section
                        statsSection

                        // Rewards Preview
                        rewardsPreviewSection

                        // Play Button
                        playButton

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ranked Ladder")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                    }
                }
            }
            .toolbarBackground(Color.clear, for: .navigationBar)
            .fullScreenCover(isPresented: $showingGame) {
                LadderGameView(onGameEnd: handleGameEnd)
            }
            .alert("Rank Up!", isPresented: $showingRankUp) {
                Button("Awesome!") {
                    if !newRewards.isEmpty {
                        showingRewards = true
                    }
                }
            } message: {
                if let change = lastRankChange {
                    Text("You've been promoted to \(change.newRank.displayName)!")
                }
            }
            .alert("Rank Down", isPresented: $showingRankDown) {
                Button("Keep Fighting!") { }
            } message: {
                if let change = lastRankChange {
                    Text("You've been demoted to \(change.newRank.displayName). Keep practicing!")
                }
            }
            .alert("Promotion Series!", isPresented: $showingPromoStart) {
                Button("Let's Go!") { }
            } message: {
                if let series = ladderManager.stats.promoSeries {
                    Text("You've entered a promotion series to \(series.targetRank.displayName)! Win 2 out of 3 games to advance.")
                }
            }
            .sheet(isPresented: $showingRewards) {
                RewardsUnlockedView(rewards: newRewards)
            }
        }
    }

    // MARK: - Rank Display

    private var rankDisplaySection: some View {
        VStack(spacing: 20) {
            // Rank badge
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ladderManager.currentRank.glowColor.opacity(0.5),
                                ladderManager.currentRank.glowColor.opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                ladderManager.currentRank.color.opacity(0.3),
                                ladderManager.currentRank.color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                // Border
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                ladderManager.currentRank.color,
                                ladderManager.currentRank.color.opacity(0.5)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 140, height: 140)

                // Icon
                Image(systemName: ladderManager.currentRank.icon)
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                ladderManager.currentRank.color,
                                ladderManager.currentRank.color.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: ladderManager.currentRank.glowColor.opacity(0.6), radius: 10)
            }

            // Rank name and LP
            VStack(spacing: 8) {
                Text(ladderManager.currentRank.displayName)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.white)

                Text(ladderManager.lpDisplay)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(ladderManager.currentRank.color)

                Text("vs \(ladderManager.currentRank.aiDifficulty.displayName) AI")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.5))
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Promotion Series Section

    private var promoSeriesSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("PROMOTION SERIES")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.yellow)
                    .tracking(1)
                Spacer()
                if let series = ladderManager.stats.promoSeries {
                    Text("to \(series.targetRank.displayName)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                }
            }

            if let series = ladderManager.stats.promoSeries {
                HStack(spacing: 16) {
                    ForEach(0..<series.gamesRequired, id: \.self) { index in
                        let result = getPromoGameResult(index: index, series: series)
                        Circle()
                            .fill(result.color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: result.icon)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(result.borderColor, lineWidth: 2)
                            )
                    }
                }

                Text("Win \(series.winsNeeded) games to promote!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func getPromoGameResult(index: Int, series: PromotionSeries) -> (color: Color, icon: String, borderColor: Color) {
        if index < series.wins {
            return (Color.green, "checkmark", Color.green)
        } else if index < series.wins + series.losses {
            return (Color.red, "xmark", Color.red)
        } else {
            return (Color.white.opacity(0.1), "minus", Color.white.opacity(0.3))
        }
    }

    // MARK: - LP Progress Section

    private var lpProgressSection: some View {
        VStack(spacing: 16) {
            // LP Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if ladderManager.isInPromoSeries {
                        Text("In Promotion Series")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.yellow)
                    } else if let nextRank = ladderManager.currentRank.next {
                        Text("Progress to \(nextRank.displayName)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.7))
                    } else {
                        Text("Maximum Rank Achieved!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.yellow)
                    }

                    Spacer()

                    if !ladderManager.isInPromoSeries {
                        Text("\(ladderManager.stats.currentLP) / 100 LP")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(ladderManager.currentRank.color)
                    }
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))

                        // Progress
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: ladderManager.isInPromoSeries
                                        ? [.yellow, .orange]
                                        : [ladderManager.currentRank.color, ladderManager.currentRank.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * ladderManager.progressToNextRank)
                            .animation(.easeInOut(duration: 0.3), value: ladderManager.progressToNextRank)
                    }
                }
                .frame(height: 12)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )

            // Streak indicator
            if ladderManager.stats.currentStreak != 0 {
                HStack {
                    Image(systemName: ladderManager.stats.currentStreak > 0 ? "flame.fill" : "arrow.down.circle.fill")
                        .foregroundColor(ladderManager.stats.currentStreak > 0 ? .orange : .red)

                    Text(ladderManager.stats.currentStreak > 0
                         ? "\(ladderManager.stats.currentStreak) Win Streak! +\(min(ladderManager.stats.currentStreak - 1, 5) * 2) bonus LP"
                         : "\(abs(ladderManager.stats.currentStreak)) Loss Streak")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ladderManager.stats.currentStreak > 0 ? .orange : .red)

                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill((ladderManager.stats.currentStreak > 0 ? Color.orange : Color.red).opacity(0.15))
                )
            }

            // Recent performance
            if ladderManager.stats.recentWins + ladderManager.stats.recentLosses > 0 {
                HStack {
                    Text("Recent: ")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.5))

                    Text("\(ladderManager.stats.recentWins)W")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)

                    Text("-")
                        .foregroundColor(Color.white.opacity(0.3))

                    Text("\(ladderManager.stats.recentLosses)L")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)

                    Spacer()

                    let recentRate = ladderManager.stats.recentWinRate
                    Text(String(format: "%.0f%% WR", recentRate))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(recentRate >= 50 ? .green : .red)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STATISTICS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.white.opacity(0.5))
                .tracking(1)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Wins", value: "\(ladderManager.stats.totalWins)", icon: "checkmark.circle.fill", color: .green)
                StatCard(title: "Losses", value: "\(ladderManager.stats.totalLosses)", icon: "xmark.circle.fill", color: .red)
                StatCard(title: "Win Rate", value: String(format: "%.0f%%", ladderManager.stats.winRate), icon: "percent", color: .blue)
                StatCard(title: "Best Streak", value: "\(ladderManager.stats.bestStreak)", icon: "flame.fill", color: .orange)
                StatCard(title: "Season Games", value: "\(ladderManager.stats.seasonGamesPlayed)", icon: "gamecontroller.fill", color: .purple)
                StatCard(title: "Peak Rank", value: ladderManager.stats.highestRank.displayName, icon: "crown.fill", color: ladderManager.stats.highestRank.color)
            }
        }
    }

    // MARK: - Rewards Preview Section

    private var rewardsPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("NEXT REWARDS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .tracking(1)

                Spacer()

                Text("\(ladderManager.unlockedRewards.count) unlocked")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
            }

            // Show next 2-3 unlockable rewards
            let nextRewards = getNextRewards()
            if !nextRewards.isEmpty {
                HStack(spacing: 12) {
                    ForEach(nextRewards, id: \.name) { reward in
                        VStack(spacing: 6) {
                            Image(systemName: reward.icon)
                                .font(.system(size: 20))
                                .foregroundColor(reward.rank.color)

                            Text(reward.name)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(reward.rank.displayName)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(reward.rank.color.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            } else {
                Text("All rewards unlocked!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.yellow)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.yellow.opacity(0.1))
                    )
            }
        }
    }

    private func getNextRewards() -> [LadderReward] {
        var rewards: [LadderReward] = []
        for rank in LadderRank.allCases where rank.rawValue > ladderManager.currentRank.rawValue {
            if let title = rank.unlockedTitle {
                rewards.append(LadderReward(type: .title, name: title, rank: rank))
            }
            if let stone = rank.unlockedStoneTheme {
                rewards.append(LadderReward(type: .stoneTheme, name: stone, rank: rank))
            }
            if let board = rank.unlockedBoardTheme {
                rewards.append(LadderReward(type: .boardTheme, name: board, rank: rank))
            }
            if rewards.count >= 3 { break }
        }
        return rewards
    }

    // MARK: - Play Button

    private var playButton: some View {
        Button {
            showingGame = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: ladderManager.isInPromoSeries ? "trophy.fill" : "play.fill")
                    .font(.system(size: 20, weight: .bold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(ladderManager.isInPromoSeries ? "Promotion Match" : "Play Ranked Match")
                        .font(.system(size: 18, weight: .bold))

                    Text("vs \(ladderManager.currentRank.aiDifficulty.displayName) AI")
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.8)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(ladderManager.isInPromoSeries ? "Series" : "+\(ladderManager.currentRank.baseLPGain) LP")
                        .font(.system(size: 14, weight: .bold))
                    Text(ladderManager.isInPromoSeries ? "Game" : "on win")
                        .font(.system(size: 10, weight: .medium))
                        .opacity(0.7)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: ladderManager.isInPromoSeries
                        ? [.yellow, .orange]
                        : [ladderManager.currentRank.color, ladderManager.currentRank.color.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: (ladderManager.isInPromoSeries ? Color.yellow : ladderManager.currentRank.color).opacity(0.4), radius: 10, x: 0, y: 5)
        }
        .padding(.top, 8)
    }

    // MARK: - Game End Handler

    private func handleGameEnd(playerWon: Bool) {
        showingGame = false

        let result = playerWon ? ladderManager.recordWin() : ladderManager.recordLoss()
        lastRankChange = result
        newRewards = result.unlockedRewards

        // Show appropriate alerts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if result.startedPromoSeries {
                showingPromoStart = true
            } else if result.didPromote {
                showingRankUp = true
            } else if result.didDemote {
                showingRankDown = true
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Rewards Unlocked View

struct RewardsUnlockedView: View {
    let rewards: [LadderReward]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("REWARDS UNLOCKED!")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(.yellow)

                ForEach(rewards) { reward in
                    HStack(spacing: 16) {
                        Image(systemName: reward.icon)
                            .font(.system(size: 32))
                            .foregroundColor(reward.rank.color)
                            .frame(width: 50)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(reward.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)

                            Text(rewardTypeText(reward.type))
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.6))
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }

                Button {
                    dismiss()
                } label: {
                    Text("Awesome!")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.yellow)
                        .cornerRadius(12)
                }
                .padding(.top, 16)
            }
            .padding(24)
        }
    }

    private func rewardTypeText(_ type: LadderReward.RewardType) -> String {
        switch type {
        case .title: return "Player Title"
        case .stoneTheme: return "Stone Theme"
        case .boardTheme: return "Board Theme"
        case .border: return "Profile Border"
        }
    }
}

// MARK: - Ladder Game View

struct LadderGameView: View {
    let onGameEnd: (Bool) -> Void
    @StateObject private var ladderManager = LadderManager.shared
    @State private var gameEnded = false
    @State private var playerWon = false

    var body: some View {
        GameView(
            gameMode: .vsAI(difficulty: ladderManager.currentRank.aiDifficulty)
        ) {
            // This is called when returning to menu
            if gameEnded {
                onGameEnd(playerWon)
            } else {
                // Player quit without finishing
                onGameEnd(false) // Count as loss for quitting
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .ladderGameEnded)) { notification in
            if let won = notification.userInfo?["playerWon"] as? Bool {
                gameEnded = true
                playerWon = won
            }
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let ladderGameEnded = Notification.Name("ladderGameEnded")
}

#Preview {
    LadderView()
}
