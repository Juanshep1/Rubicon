import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var achievementManager = AchievementManager.shared
    @ObservedObject private var ladderManager = LadderManager.shared

    @State private var selectedCategory: AchievementCategory? = nil
    @State private var showingResetAlert = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.06, blue: 0.14),
                    Color(red: 0.12, green: 0.08, blue: 0.18),
                    Color(red: 0.06, green: 0.04, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Rank Card
                    rankCard

                    // Stats Overview
                    statsOverview

                    // Achievements Section
                    achievementsSection
                }
                .padding()
                .padding(.bottom, 40)
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .alert("Reset Progress", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                achievementManager.resetAll()
                ladderManager.resetLadder()
            }
        } message: {
            Text("This will reset all achievements, stats, and ladder progress. This cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("PROFILE")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("\(achievementManager.unlockedCount)/\(achievementManager.totalAchievements) Achievements")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.top, 40)
    }

    // MARK: - Rank Card

    private var rankCard: some View {
        let rankColor = ladderManager.currentRank.color
        let rankIcon = ladderManager.currentRank.icon
        let rankName = ladderManager.currentRank.displayName

        return VStack(spacing: 16) {
            rankBadge(color: rankColor, icon: rankIcon)

            Text(rankName)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            rankProgressSection
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(rankColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func rankBadge(color: Color, icon: String) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 120, height: 120)
                .blur(radius: 20)

            Circle()
                .fill(color)
                .frame(width: 100, height: 100)
                .shadow(color: color.opacity(0.5), radius: 15)

            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2)
        }
    }

    @ViewBuilder
    private var rankProgressSection: some View {
        if ladderManager.currentRank != .grandmaster {
            VStack(spacing: 8) {
                HStack {
                    Text("Next Rank:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    if let next = ladderManager.currentRank.next {
                        Text(next.displayName)
                            .font(.caption.bold())
                            .foregroundColor(next.color)
                    }
                }

                rankProgressBar

                Text("\(ladderManager.stats.rankUpProgress)/\(ladderManager.currentRank.winsToRankUp) wins to rank up")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal)
        } else {
            Text("Maximum Rank Achieved!")
                .font(.caption)
                .foregroundColor(.yellow)
        }
    }

    private var rankProgressBar: some View {
        let progress = ladderManager.progressToNextRank
        let color = ladderManager.currentRank.color

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: max(0, geo.size.width * progress), height: 8)
            }
        }
        .frame(height: 8)
    }

    // MARK: - Stats Overview

    private var statsOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("STATISTICS")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ProfileStatCard(title: "Games", value: "\(achievementManager.totalGamesPlayed)", icon: "gamecontroller.fill", color: .blue)
                ProfileStatCard(title: "Wins", value: "\(achievementManager.totalWins)", icon: "trophy.fill", color: .orange)
                ProfileStatCard(title: "Win Rate", value: String(format: "%.0f%%", achievementManager.winRate), icon: "percent", color: .green)
                ProfileStatCard(title: "Best Streak", value: "\(achievementManager.bestWinStreak)", icon: "flame.fill", color: .red)
                ProfileStatCard(title: "Captures", value: "\(achievementManager.totalCaptures)", icon: "scope", color: .purple)
                ProfileStatCard(title: "Locks", value: "\(achievementManager.totalLocks)", icon: "lock.fill", color: .cyan)
            }
        }
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ACHIEVEMENTS")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)

                Spacer()

                Text("\(achievementManager.unlockedCount)/\(achievementManager.totalAchievements)")
                    .font(.caption.bold())
                    .foregroundColor(.yellow)
            }

            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(title: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }

                    ForEach(AchievementCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            title: category.rawValue,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }

            // Achievements Grid
            let filteredAchievements = selectedCategory == nil
                ? achievementManager.achievements
                : achievementManager.achievements(for: selectedCategory!)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(filteredAchievements) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
        }
    }
}

// MARK: - Profile Stat Card

struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                )
        }
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 12) {
            // Icon with glow if unlocked
            ZStack {
                if achievement.isUnlocked {
                    Circle()
                        .fill(achievement.color.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .blur(radius: 10)
                }

                Circle()
                    .fill(achievement.isUnlocked ? achievement.color : Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)

                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(achievement.isUnlocked ? .white : .gray)
            }

            VStack(spacing: 4) {
                Text(achievement.isSecret && !achievement.isUnlocked ? "???" : achievement.name)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(achievement.isSecret && !achievement.isUnlocked ? "Secret Achievement" : achievement.description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            // Progress bar if not unlocked
            if !achievement.isUnlocked && achievement.requirement > 1 {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(achievement.color)
                                .frame(width: max(0, geo.size.width * achievement.progressPercent), height: 4)
                        }
                    }
                    .frame(height: 4)

                    Text("\(achievement.progress)/\(achievement.requirement)")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(achievement.isUnlocked ? achievement.color.opacity(0.1) : Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            achievement.isUnlocked ? achievement.color.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }
}

#Preview {
    ProfileView()
}
