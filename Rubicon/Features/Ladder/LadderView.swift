import SwiftUI
import RubiconEngine

struct LadderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ladderManager = LadderManager.shared
    @State private var showingGame = false
    @State private var showingRankUp = false
    @State private var showingRankDown = false
    @State private var lastRankChange: RankChangeResult?

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
                        ladderManager.currentRank.color.opacity(0.2),
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

                        // Progress Section
                        progressSection

                        // Stats Section
                        statsSection

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
                Button("Awesome!") { }
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
                                ladderManager.currentRank.color.opacity(0.4),
                                ladderManager.currentRank.color.opacity(0.1),
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
                    .shadow(color: ladderManager.currentRank.color.opacity(0.5), radius: 10)
            }

            // Rank name
            VStack(spacing: 4) {
                Text(ladderManager.currentRank.displayName)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.white)

                Text("vs \(ladderManager.currentRank.aiDifficulty.displayName) AI")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.5))
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 16) {
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress to \(ladderManager.currentRank.next?.displayName ?? "Max Rank")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))

                    Spacer()

                    Text("\(ladderManager.stats.rankUpProgress)/\(ladderManager.currentRank.winsToRankUp)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(ladderManager.currentRank.color)
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
                                    colors: [
                                        ladderManager.currentRank.color,
                                        ladderManager.currentRank.color.opacity(0.7)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * ladderManager.progressToNextRank)

                        // Markers
                        HStack(spacing: 0) {
                            ForEach(0..<ladderManager.currentRank.winsToRankUp, id: \.self) { index in
                                if index > 0 {
                                    Spacer()
                                }
                                Circle()
                                    .fill(index < ladderManager.stats.rankUpProgress
                                          ? ladderManager.currentRank.color
                                          : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .frame(height: 12)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )

            // Win streak
            if ladderManager.stats.currentStreak != 0 {
                HStack {
                    Image(systemName: ladderManager.stats.currentStreak > 0 ? "flame.fill" : "arrow.down.circle.fill")
                        .foregroundColor(ladderManager.stats.currentStreak > 0 ? .orange : .red)

                    Text(ladderManager.stats.currentStreak > 0
                         ? "\(ladderManager.stats.currentStreak) Win Streak!"
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
                StatCard(title: "Games Played", value: "\(ladderManager.stats.seasonGamesPlayed)", icon: "gamecontroller.fill", color: .purple)
                StatCard(title: "Highest Rank", value: ladderManager.stats.highestRank.tier, icon: "crown.fill", color: ladderManager.stats.highestRank.color)
            }
        }
    }

    // MARK: - Play Button

    private var playButton: some View {
        Button {
            showingGame = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 20, weight: .bold))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Play Ranked Match")
                        .font(.system(size: 18, weight: .bold))

                    Text("vs \(ladderManager.currentRank.aiDifficulty.displayName) AI")
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.8)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        ladderManager.currentRank.color,
                        ladderManager.currentRank.color.opacity(0.7)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: ladderManager.currentRank.color.opacity(0.4), radius: 10, x: 0, y: 5)
        }
        .padding(.top, 8)
    }

    // MARK: - Game End Handler

    private func handleGameEnd(playerWon: Bool) {
        showingGame = false

        let result = playerWon ? ladderManager.recordWin() : ladderManager.recordLoss()
        lastRankChange = result

        // Show rank change alerts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if result.didPromote {
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
