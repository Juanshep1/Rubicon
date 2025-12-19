import SwiftUI
import RubiconEngine

// MARK: - Story Chapter View

struct StoryChapterView: View {
    let chapter: StoryChapter
    let onComplete: () -> Void

    @State private var phase: ChapterPhase = .intro
    @State private var showMidMatchDialogue = false
    @State private var hasShownMidMatch = false
    @StateObject private var progressManager = StoryProgressManager.shared

    enum ChapterPhase {
        case intro
        case preMatch
        case battle
        case postMatch
        case complete

        var saved: SavedChapterPhase {
            switch self {
            case .intro: return .intro
            case .preMatch: return .preMatch
            case .battle: return .battle
            case .postMatch: return .postMatch
            case .complete: return .complete
            }
        }

        static func from(saved: SavedChapterPhase) -> ChapterPhase {
            switch saved {
            case .intro: return .intro
            case .preMatch: return .preMatch
            case .battle: return .battle
            case .postMatch: return .postMatch
            case .complete: return .complete
            }
        }
    }

    var body: some View {
        ZStack {
            switch phase {
            case .intro:
                ChapterIntroView(chapter: chapter) {
                    advanceToPhase(.preMatch)
                }

            case .preMatch:
                DialogueView(
                    dialogues: chapter.preMatchDialogue,
                    backgroundImage: chapter.backgroundImage
                ) {
                    advanceToPhase(.battle)
                }

            case .battle:
                StoryGameView(
                    chapter: chapter,
                    onVictory: {
                        advanceToPhase(.postMatch)
                    },
                    onMidMatchTrigger: {
                        if !hasShownMidMatch && !chapter.midMatchDialogue.isEmpty {
                            hasShownMidMatch = true
                            progressManager.setMidMatchShown()
                            showMidMatchDialogue = true
                        }
                    }
                )
                .fullScreenCover(isPresented: $showMidMatchDialogue) {
                    DialogueView(
                        dialogues: chapter.midMatchDialogue,
                        backgroundImage: chapter.backgroundImage
                    ) {
                        showMidMatchDialogue = false
                    }
                }

            case .postMatch:
                DialogueView(
                    dialogues: chapter.postMatchDialogue,
                    backgroundImage: chapter.backgroundImage
                ) {
                    progressManager.completeChapter(chapter.id)
                    advanceToPhase(.complete)
                }

            case .complete:
                ChapterCompleteView(chapter: chapter) {
                    onComplete()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupChapter()
        }
    }

    private func setupChapter() {
        // Check if we have saved progress for this chapter
        if let savedPhase = progressManager.getResumePhase(for: chapter.id) {
            // Resume from saved phase
            phase = ChapterPhase.from(saved: savedPhase)
            hasShownMidMatch = progressManager.inProgressChapter?.hasShownMidMatch ?? false
        } else {
            // Start fresh
            progressManager.startChapter(chapter.id)
            phase = .intro
        }
    }

    private func advanceToPhase(_ newPhase: ChapterPhase) {
        withAnimation(.easeInOut(duration: 0.4)) {
            phase = newPhase
        }
        progressManager.updateChapterPhase(newPhase.saved)
    }
}

// MARK: - Chapter Intro View

struct ChapterIntroView: View {
    let chapter: StoryChapter
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let width = max(1, geometry.size.width)
            let height = max(1, geometry.size.height)
            let safeBottom = max(0, geometry.safeAreaInsets.bottom)

            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                if geometry.size.width > 0 && geometry.size.height > 0 {
                    Image(chapter.backgroundImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.5),
                                    Color.black.opacity(0.7),
                                    Color.black.opacity(0.9)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .ignoresSafeArea()

                    // Content
                    VStack(spacing: 20) {
                        Spacer()

                        // Title
                        titleSection

                        Spacer().frame(height: 16)

                        // Opponent
                        opponentSection(portraitSize: 110)

                        Spacer()

                        // Button
                        beginButton
                            .padding(.bottom, safeBottom + 30)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text(chapter.chapterNumber.uppercased())
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(chapter.opponent.themeColor)
                .tracking(5)

            Text(chapter.title)
                .font(.system(size: 36, weight: .black, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

            Text(chapter.subtitle)
                .font(.headline.italic())
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private func opponentSection(portraitSize: CGFloat) -> some View {
        VStack(spacing: 14) {
            ZStack {
                // Glow
                Circle()
                    .fill(chapter.opponent.themeColor.opacity(0.3))
                    .frame(width: portraitSize + 20, height: portraitSize + 20)
                    .blur(radius: 25)

                // Portrait
                Image(chapter.opponent.portraitName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: portraitSize, height: portraitSize)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(chapter.opponent.themeColor, lineWidth: 3)
                    )
            }

            VStack(spacing: 4) {
                Text(chapter.opponent.fullName)
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text(chapter.opponent.title)
                    .font(.subheadline)
                    .foregroundColor(chapter.opponent.themeColor)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                        Text(chapter.location)
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))

                    difficultyBadge
                }
                .padding(.top, 4)
            }
        }
    }

    private var difficultyBadge: some View {
        let (text, color, icon) = difficultyInfo
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption.bold())
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.2))
        )
    }

    private var difficultyInfo: (String, Color, String) {
        switch chapter.difficulty {
        case .beginner: return ("Beginner", .green, "leaf.fill")
        case .easy: return ("Easy", .mint, "tortoise.fill")
        case .medium: return ("Medium", .blue, "figure.walk")
        case .hard: return ("Hard", .orange, "flame.fill")
        case .expert: return ("Expert", .red, "crown.fill")
        case .master: return ("Master", .purple, "bolt.shield.fill")
        }
    }

    private var beginButton: some View {
        Button(action: onContinue) {
            HStack(spacing: 10) {
                Text("Begin Chapter")
                    .font(.headline.bold())
                Image(systemName: "arrow.right")
            }
            .foregroundColor(.black)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [chapter.opponent.themeColor, chapter.opponent.themeColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: chapter.opponent.themeColor.opacity(0.4), radius: 12, y: 4)
            )
        }
    }

}

// MARK: - Chapter Complete View

struct ChapterCompleteView: View {
    let chapter: StoryChapter
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let safeBottom = max(0, geometry.safeAreaInsets.bottom)

            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.12, blue: 0.08),
                        Color(red: 0.05, green: 0.06, blue: 0.04),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if geometry.size.width > 0 && geometry.size.height > 0 {
                    // Content
                    VStack(spacing: 20) {
                        Spacer()

                        victorySection
                        defeatedOpponent

                        Spacer()

                        nextChapterSection

                        continueButton
                            .padding(.bottom, safeBottom + 30)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    private var victorySection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: 110, height: 110)
                    .blur(radius: 30)

                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text("VICTORY")
                .font(.system(size: 32, weight: .black, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("\(chapter.chapterNumber) Complete")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private var defeatedOpponent: some View {
        VStack(spacing: 10) {
            Image(chapter.opponent.portraitName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                .grayscale(0.7)
                .opacity(0.7)

            Text("Defeated \(chapter.opponent.fullName)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
        }
    }

    @ViewBuilder
    private var nextChapterSection: some View {
        if chapter.id < 8 {
            if let nextChapter = StoryContent.chapter(for: chapter.id + 1) {
                VStack(spacing: 10) {
                    Text("NEXT CHALLENGE")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)

                    HStack(spacing: 14) {
                        Image(nextChapter.opponent.portraitName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(nextChapter.opponent.themeColor.opacity(0.5), lineWidth: 2)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(nextChapter.title)
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("vs \(nextChapter.opponent.fullName)")
                                .font(.caption)
                                .foregroundColor(nextChapter.opponent.themeColor)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
        } else {
            storyCompleteSection
        }
    }

    private var storyCompleteSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 35))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Story Complete!")
                .font(.title3.bold())
                .foregroundColor(.white)

            Text("You have mastered the Rubicon\nand become its Guardian.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            HStack(spacing: 10) {
                Text(chapter.id < 8 ? "Continue" : "Complete Story")
                    .font(.headline.bold())
                Image(systemName: chapter.id < 8 ? "arrow.right" : "checkmark")
            }
            .foregroundColor(.black)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
    }
}

// MARK: - Story Game View

struct StoryGameView: View {
    let chapter: StoryChapter
    let onVictory: () -> Void
    let onMidMatchTrigger: () -> Void

    @StateObject private var viewModel: GameViewModel
    @State private var hasTriggeredMidMatch = false
    @State private var gameKey = UUID()

    init(chapter: StoryChapter, onVictory: @escaping () -> Void, onMidMatchTrigger: @escaping () -> Void) {
        self.chapter = chapter
        self.onVictory = onVictory
        self.onMidMatchTrigger = onMidMatchTrigger
        // Pass story personality for unique opponent behavior
        _viewModel = StateObject(wrappedValue: GameViewModel(
            gameMode: .vsAI(difficulty: chapter.difficulty),
            storyPersonality: chapter.aiPersonality
        ))
    }

    var body: some View {
        ZStack {
            GameContentView(viewModel: viewModel, chapter: chapter)
                .id(gameKey)

            if viewModel.showVictoryBanner, let winner = viewModel.winner {
                StoryVictoryBanner(
                    winner: winner,
                    chapter: chapter,
                    onRetry: winner == .dark ? retryGame : nil
                )

                if winner == .light {
                    Color.clear
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                onVictory()
                            }
                        }
                }
            }
        }
        .onChange(of: viewModel.state.moveHistory.count) { _, newCount in
            if newCount >= 6 && !hasTriggeredMidMatch {
                hasTriggeredMidMatch = true
                onMidMatchTrigger()
            }
        }
        .onAppear {
            viewModel.checkForAITurn()
        }
    }

    private func retryGame() {
        hasTriggeredMidMatch = false
        gameKey = UUID()
        viewModel.resetGame()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewModel.checkForAITurn()
        }
    }
}

// MARK: - Game Content View

struct GameContentView: View {
    @ObservedObject var viewModel: GameViewModel
    let chapter: StoryChapter

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                Color(red: 0.08, green: 0.06, blue: 0.08)
                    .ignoresSafeArea()

                if isLandscape {
                    landscapeLayout(geometry: geometry)
                } else {
                    portraitLayout(geometry: geometry)
                }

                if viewModel.showVictoryBanner, let winner = viewModel.winner {
                    StoryVictoryBanner(winner: winner, chapter: chapter, onRetry: nil)
                }
            }
        }
    }

    private func portraitLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            opponentBar

            BoardView(
                board: viewModel.board,
                selectedPosition: viewModel.selectedPosition,
                validDestinations: viewModel.validDestinations,
                breakModeSelections: viewModel.isInBreakMode ? viewModel.breakSacrificePositions : [],
                breakModeTargets: viewModel.isInBreakMode && viewModel.breakSacrificePositions.count == 2 ? viewModel.opponentLockedPositions : [],
                onCellTap: { position in
                    if viewModel.isInBreakMode {
                        viewModel.handleBreakSelection(position)
                    } else {
                        viewModel.handleCellTap(position)
                    }
                }
            )
            .frame(maxWidth: min(geometry.size.width - 32, 400))

            GameHUDView(
                state: viewModel.state,
                availablePatterns: viewModel.availablePatterns,
                onLockPattern: viewModel.performLock,
                onDrawFromRiver: viewModel.drawFromRiver,
                onPass: { viewModel.pass() },
                onBreak: { viewModel.startBreakMode() }
            )
            .frame(maxWidth: 400)
        }
        .padding()
    }

    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 16) {
            VStack(spacing: 12) {
                opponentBar
                Spacer()
                GameHUDView(
                    state: viewModel.state,
                    availablePatterns: viewModel.availablePatterns,
                    onLockPattern: viewModel.performLock,
                    onDrawFromRiver: viewModel.drawFromRiver,
                    onPass: { viewModel.pass() },
                    onBreak: { viewModel.startBreakMode() }
                )
            }
            .frame(width: 200)

            BoardView(
                board: viewModel.board,
                selectedPosition: viewModel.selectedPosition,
                validDestinations: viewModel.validDestinations,
                breakModeSelections: viewModel.isInBreakMode ? viewModel.breakSacrificePositions : [],
                breakModeTargets: viewModel.isInBreakMode && viewModel.breakSacrificePositions.count == 2 ? viewModel.opponentLockedPositions : [],
                onCellTap: { position in
                    if viewModel.isInBreakMode {
                        viewModel.handleBreakSelection(position)
                    } else {
                        viewModel.handleCellTap(position)
                    }
                }
            )
            .frame(maxWidth: geometry.size.height - 60)
        }
        .padding()
    }

    private var opponentBar: some View {
        HStack(spacing: 10) {
            Image(chapter.opponent.portraitName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(chapter.opponent.themeColor, lineWidth: 2)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(chapter.opponent.fullName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                Text(chapter.opponent.title)
                    .font(.caption2)
                    .foregroundColor(chapter.opponent.themeColor)
            }

            Spacer()

            if chapter.difficulty.rawValue >= 5 {
                Text(chapter.difficulty == .master ? "MASTER" : "EXPERT")
                    .font(.caption2.bold())
                    .foregroundColor(chapter.difficulty == .master ? .purple : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((chapter.difficulty == .master ? Color.purple : Color.red).opacity(0.2))
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.5))
        )
    }
}

// MARK: - Story Victory Banner

struct StoryVictoryBanner: View {
    let winner: Player
    let chapter: StoryChapter
    let onRetry: (() -> Void)?

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                if winner == .light {
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .blur(radius: 25)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("VICTORY!")
                        .font(.system(size: 36, weight: .black, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("You defeated \(chapter.opponent.fullName)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)

                    Text("DEFEAT")
                        .font(.system(size: 36, weight: .black, design: .serif))
                        .foregroundColor(.red)

                    Text("\(chapter.opponent.fullName) was victorious")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))

                    // Retry button for defeats
                    if let retry = onRetry {
                        Button(action: retry) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Try Again")
                                    .font(.headline.bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [chapter.opponent.themeColor, chapter.opponent.themeColor.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: chapter.opponent.themeColor.opacity(0.4), radius: 10, y: 4)
                            )
                        }
                        .opacity(buttonOpacity)
                        .padding(.top, 8)
                    }
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                buttonOpacity = 1.0
            }
        }
    }
}

#Preview {
    StoryChapterView(chapter: StoryContent.chapter1) {}
}
