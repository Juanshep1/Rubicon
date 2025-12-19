import SwiftUI
import RubiconEngine

struct MainMenuView: View {
    @State private var selectedGameMode: GameMode?
    @State private var showDifficultyPicker = false
    @State private var showOnlineOptions = false
    @State private var showSettings = false
    @State private var showHowToPlay = false
    @State private var showLadder = false
    @State private var showProfile = false
    @State private var showStoryMode = false

    // Animation states
    @State private var titleScale: CGFloat = 0.8
    @State private var titleOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 50
    @State private var buttonsOpacity: Double = 0
    @State private var glowAnimation = false
    @State private var floatingOffset: CGFloat = 0

    private let audioManager = AudioManager.shared

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Epic background
                    epicBackground(size: geometry.size)

                    // Floating decorative stones
                    floatingStones(size: geometry.size)

                    // Main content
                    VStack(spacing: 0) {
                        Spacer()

                        // Epic Logo/Title
                        epicTitleSection
                            .scaleEffect(titleScale)
                            .opacity(titleOpacity)

                        Spacer()
                            .frame(height: 50)

                        // Menu buttons with epic styling
                        epicMenuButtons
                            .offset(y: buttonsOffset)
                            .opacity(buttonsOpacity)
                            .padding(.horizontal, 28)

                        Spacer()

                        // Footer
                        epicFooterSection
                            .padding(.bottom, 24)
                    }
                }
            }
            .ignoresSafeArea()
            .navigationDestination(item: $selectedGameMode) { mode in
                GameView(gameMode: mode) {
                    selectedGameMode = nil
                }
            }
            .sheet(isPresented: $showDifficultyPicker) {
                difficultyPickerSheet
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showHowToPlay) {
                HowToPlayView()
            }
            .fullScreenCover(isPresented: $showLadder) {
                LadderView()
            }
            .fullScreenCover(isPresented: $showProfile) {
                ProfileView()
            }
            .fullScreenCover(isPresented: $showStoryMode) {
                StoryModeView()
            }
            .onAppear {
                audioManager.startBackgroundMusic()
                startAnimations()
            }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Title entrance
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
            titleScale = 1.0
            titleOpacity = 1.0
        }

        // Buttons entrance
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
            buttonsOffset = 0
            buttonsOpacity = 1.0
        }

        // Continuous glow animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowAnimation = true
        }

        // Floating animation
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            floatingOffset = 10
        }
    }

    // MARK: - Epic Background

    private func epicBackground(size: CGSize) -> some View {
        ZStack {
            // Deep gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.06, blue: 0.12),
                    Color(red: 0.12, green: 0.08, blue: 0.16),
                    Color(red: 0.06, green: 0.04, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Radial glow from center
            RadialGradient(
                colors: [
                    Color(red: 0.6, green: 0.4, blue: 0.2).opacity(glowAnimation ? 0.15 : 0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: size.width * 0.8
            )

            // Top ambient light
            RadialGradient(
                colors: [
                    Color(red: 0.4, green: 0.3, blue: 0.5).opacity(0.2),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: size.height * 0.6
            )

            // Bottom warm glow
            RadialGradient(
                colors: [
                    Color(red: 0.5, green: 0.3, blue: 0.1).opacity(0.1),
                    Color.clear
                ],
                center: .bottom,
                startRadius: 0,
                endRadius: size.height * 0.5
            )

            // Subtle noise/texture overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.02), location: 0),
                            .init(color: Color.clear, location: 0.3),
                            .init(color: Color.white.opacity(0.01), location: 0.6),
                            .init(color: Color.clear, location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    // MARK: - Floating Stones

    private func floatingStones(size: CGSize) -> some View {
        ZStack {
            // Large floating decorative stones
            // Top left stone
            FloatingStone(isLight: true, size: 60)
                .offset(x: -size.width * 0.35, y: -size.height * 0.3 + floatingOffset)
                .blur(radius: 1)

            // Top right stone
            FloatingStone(isLight: false, size: 50)
                .offset(x: size.width * 0.38, y: -size.height * 0.25 - floatingOffset * 0.7)
                .blur(radius: 0.5)

            // Bottom left stone
            FloatingStone(isLight: false, size: 45)
                .offset(x: -size.width * 0.4, y: size.height * 0.28 - floatingOffset * 0.5)
                .blur(radius: 1)

            // Bottom right stone
            FloatingStone(isLight: true, size: 55)
                .offset(x: size.width * 0.35, y: size.height * 0.32 + floatingOffset * 0.8)
                .blur(radius: 0.5)
        }
    }

    // MARK: - Epic Title Section

    private var epicTitleSection: some View {
        VStack(spacing: 20) {
            // Decorative stone emblem
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.8, green: 0.6, blue: 0.3).opacity(glowAnimation ? 0.6 : 0.3),
                                Color(red: 0.6, green: 0.4, blue: 0.2).opacity(glowAnimation ? 0.4 : 0.2),
                                Color(red: 0.8, green: 0.6, blue: 0.3).opacity(glowAnimation ? 0.6 : 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: glowAnimation ? 4 : 2)

                // Inner emblem
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.15, green: 0.12, blue: 0.18),
                                Color(red: 0.1, green: 0.08, blue: 0.12)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 45
                        )
                    )
                    .frame(width: 90, height: 90)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.3, green: 0.25, blue: 0.2), lineWidth: 1)
                    )

                // Interlocking stones emblem
                HStack(spacing: -12) {
                    // Light stone
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.98, blue: 0.92),
                                    Color(red: 0.85, green: 0.82, blue: 0.75)
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)

                    // Dark stone
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.35, green: 0.32, blue: 0.38),
                                    Color(red: 0.12, green: 0.1, blue: 0.14)
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
                }
            }

            // Title with epic styling
            VStack(spacing: 8) {
                Text("RUBICON")
                    .font(.system(size: 52, weight: .black, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.95, blue: 0.85),
                                Color(red: 0.85, green: 0.7, blue: 0.5),
                                Color(red: 1.0, green: 0.9, blue: 0.75)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 0.8, green: 0.6, blue: 0.3).opacity(glowAnimation ? 0.8 : 0.4), radius: glowAnimation ? 20 : 10, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 2, y: 2)
                    .tracking(12)

                // Decorative line
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, Color(red: 0.7, green: 0.5, blue: 0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60, height: 1)

                    Circle()
                        .fill(Color(red: 0.8, green: 0.6, blue: 0.4))
                        .frame(width: 6, height: 6)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.7, green: 0.5, blue: 0.3), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60, height: 1)
                }

                // Tagline
                Text("Cross the line. Claim your victory.")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(Color(red: 0.7, green: 0.6, blue: 0.5))
                    .italic()
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Epic Menu Buttons

    private var epicMenuButtons: some View {
        VStack(spacing: 14) {
            // Story Mode - Featured
            EpicMenuButton(
                icon: "book.pages.fill",
                title: "Story Mode",
                subtitle: "The Rubicon Chronicles",
                isPrimary: true,
                accentColor: Color(red: 0.6, green: 0.4, blue: 0.8)
            ) {
                showStoryMode = true
            }

            // Ranked Ladder
            EpicMenuButton(
                icon: "chart.line.uptrend.xyaxis",
                title: "Ranked Ladder",
                subtitle: "Climb the ranks to Master",
                isPrimary: true,
                accentColor: Color(red: 0.9, green: 0.5, blue: 0.3)
            ) {
                showLadder = true
            }

            // Play vs AI
            EpicMenuButton(
                icon: "cpu",
                title: "Play vs AI",
                subtitle: "Challenge the computer",
                isPrimary: false,
                accentColor: Color(red: 0.9, green: 0.7, blue: 0.3)
            ) {
                showDifficultyPicker = true
            }

            // Local Game
            EpicMenuButton(
                icon: "person.2.fill",
                title: "Local Game",
                subtitle: "Pass & play with a friend",
                isPrimary: false,
                accentColor: Color(red: 0.5, green: 0.7, blue: 0.9)
            ) {
                selectedGameMode = .localPassAndPlay
            }

            // Online (Coming Soon)
            EpicMenuButton(
                icon: "globe",
                title: "Online",
                subtitle: "Coming Soon",
                isPrimary: false,
                accentColor: Color(red: 0.6, green: 0.5, blue: 0.7),
                isDisabled: true
            ) {
                // Coming soon
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.vertical, 6)

            // How to Play
            EpicMenuButton(
                icon: "book.fill",
                title: "How to Play",
                subtitle: "Learn the rules",
                isPrimary: false,
                accentColor: Color(red: 0.4, green: 0.7, blue: 0.6),
                isCompact: true
            ) {
                showHowToPlay = true
            }

            // Settings
            EpicMenuButton(
                icon: "gearshape.fill",
                title: "Settings",
                subtitle: "Customize your experience",
                isPrimary: false,
                accentColor: Color(red: 0.6, green: 0.6, blue: 0.65),
                isCompact: true
            ) {
                showSettings = true
            }

            // Profile
            EpicMenuButton(
                icon: "person.crop.circle.fill",
                title: "Profile",
                subtitle: "View achievements and stats",
                isPrimary: false,
                accentColor: Color(red: 0.7, green: 0.5, blue: 0.9),
                isCompact: true
            ) {
                showProfile = true
            }
        }
    }

    // MARK: - Epic Footer

    private var epicFooterSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                Text("Version 1.0")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(Color.white.opacity(0.3))
        }
    }

    // MARK: - Difficulty Picker

    private var difficultyPickerSheet: some View {
        ZStack {
            // Background
            Color(red: 0.08, green: 0.06, blue: 0.1)
                .ignoresSafeArea()

            // Ambient glow
            RadialGradient(
                colors: [
                    Color(red: 0.5, green: 0.3, blue: 0.2).opacity(0.15),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.9, green: 0.7, blue: 0.3).opacity(0.15))
                            .frame(width: 70, height: 70)

                        Image(systemName: "cpu")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.3))
                    }

                    Text("Choose Your Challenge")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                }
                .padding(.top, 32)

                // Difficulty cards
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                            DifficultyCard(
                                difficulty: difficulty,
                                isRecommended: difficulty == .medium
                            ) {
                                showDifficultyPicker = false
                                selectedGameMode = .vsAI(difficulty: difficulty)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Cancel button
                Button {
                    showDifficultyPicker = false
                } label: {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.5))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                        )
                }
                .padding(.bottom, 24)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Floating Stone Component

struct FloatingStone: View {
    let isLight: Bool
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: isLight
                        ? [Color(red: 0.95, green: 0.92, blue: 0.85), Color(red: 0.75, green: 0.72, blue: 0.65)]
                        : [Color(red: 0.3, green: 0.28, blue: 0.32), Color(red: 0.1, green: 0.08, blue: 0.12)],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: size * 0.6
                )
            )
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.4), radius: size * 0.15, x: size * 0.05, y: size * 0.05)
            .opacity(0.6)
    }
}

// MARK: - Epic Menu Button

struct EpicMenuButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isPrimary: Bool
    let accentColor: Color
    var isDisabled: Bool = false
    var isCompact: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(isPrimary ? 0.2 : 0.12))
                        .frame(width: isCompact ? 40 : 48, height: isCompact ? 40 : 48)

                    Image(systemName: icon)
                        .font(.system(size: isCompact ? 16 : 20, weight: .semibold))
                        .foregroundColor(accentColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: isCompact ? 15 : 17, weight: .semibold))
                        .foregroundColor(.white)

                    if !isCompact {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.3))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, isCompact ? 12 : 16)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: isPrimary
                                    ? [Color(red: 0.2, green: 0.15, blue: 0.1), Color(red: 0.12, green: 0.1, blue: 0.08)]
                                    : [Color.white.opacity(0.08), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: isPrimary
                                    ? [accentColor.opacity(0.5), accentColor.opacity(0.2)]
                                    : [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isPrimary ? 1.5 : 1
                        )

                    // Inner glow for primary
                    if isPrimary {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(accentColor.opacity(0.05))
                    }
                }
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Difficulty Card

struct DifficultyCard: View {
    let difficulty: AIDifficulty
    let isRecommended: Bool
    let onSelect: () -> Void

    @State private var isPressed = false

    private var difficultyColor: Color {
        switch difficulty {
        case .beginner: return Color(red: 0.3, green: 0.8, blue: 0.4)
        case .easy: return Color(red: 0.4, green: 0.8, blue: 0.7)
        case .medium: return Color(red: 0.4, green: 0.6, blue: 0.9)
        case .hard: return Color(red: 0.95, green: 0.6, blue: 0.3)
        case .expert: return Color(red: 0.95, green: 0.35, blue: 0.35)
        case .master: return Color(red: 0.8, green: 0.3, blue: 0.9)
        }
    }

    private var difficultyIcon: String {
        switch difficulty {
        case .beginner: return "leaf.fill"
        case .easy: return "tortoise.fill"
        case .medium: return "figure.walk"
        case .hard: return "flame.fill"
        case .expert: return "crown.fill"
        case .master: return "bolt.shield.fill"
        }
    }

    private var difficultyDescription: String {
        switch difficulty {
        case .beginner: return "Random moves, perfect for learning"
        case .easy: return "Makes mistakes often, casual play"
        case .medium: return "Balanced challenge for most players"
        case .hard: return "Strategic AI, blocks your plans"
        case .expert: return "Deep analysis, very challenging"
        case .master: return "Near-perfect play, almost unbeatable"
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(difficultyColor.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Circle()
                        .stroke(difficultyColor.opacity(0.3), lineWidth: 1)
                        .frame(width: 52, height: 52)

                    Image(systemName: difficultyIcon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(difficultyColor)
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(difficulty.displayName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        if isRecommended {
                            Text("RECOMMENDED")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(difficultyColor)
                                )
                        }
                    }

                    Text(difficultyDescription)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()

                // Difficulty bars
                HStack(spacing: 3) {
                    ForEach(0..<6, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index < difficulty.rawValue
                                  ? difficultyColor
                                  : Color.white.opacity(0.15))
                            .frame(width: 4, height: 14 + CGFloat(index) * 2)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.3))
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))

                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isRecommended
                                ? difficultyColor.opacity(0.4)
                                : Color.white.opacity(0.1),
                            lineWidth: isRecommended ? 1.5 : 1
                        )
                }
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview {
    MainMenuView()
}
