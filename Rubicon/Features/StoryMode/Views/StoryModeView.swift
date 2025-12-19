import SwiftUI

struct StoryModeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var progressManager = StoryProgressManager.shared
    @State private var selectedChapter: StoryChapter?
    @State private var showingChapter = false
    @State private var headerOpacity: Double = 0
    @State private var headerOffset: CGFloat = -30
    @State private var cardsAppeared = false
    @State private var particlePhase: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.06, blue: 0.12),
                        Color(red: 0.15, green: 0.10, blue: 0.20),
                        Color(red: 0.08, green: 0.04, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Ambient particles
                StoryParticleField(phase: particlePhase)
                    .opacity(0.2)

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                            .opacity(headerOpacity)
                            .offset(y: headerOffset)

                        // Progress Bar
                        progressSection
                            .opacity(headerOpacity)

                        // Chapter Grid
                        chapterGrid
                    }
                    .padding()
                    .padding(.bottom, 40)
                }

                // Close Button
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
            .navigationDestination(item: $selectedChapter) { chapter in
                StoryChapterView(chapter: chapter) {
                    selectedChapter = nil
                }
            }
            .onAppear {
                startEntryAnimations()
            }
        }
    }

    // MARK: - Entry Animations

    private func startEntryAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            headerOpacity = 1.0
            headerOffset = 0
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            cardsAppeared = true
        }

        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            particlePhase = 1
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Decorative emblem
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.9, green: 0.8, blue: 0.6).opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)

                Image(systemName: "book.pages.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.9, green: 0.8, blue: 0.6),
                                Color(red: 0.7, green: 0.5, blue: 0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text("THE RUBICON")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .tracking(4)

            Text("CHRONICLES")
                .font(.system(size: 36, weight: .black, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.9, green: 0.8, blue: 0.6),
                            Color(red: 0.7, green: 0.5, blue: 0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

            Text("A journey of mastery and transformation")
                .font(.subheadline.italic())
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.top, 50)
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Your Journey")
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(progressManager.completedChapterCount)/\(progressManager.totalChapters)")
                    .font(.headline.bold())
                    .foregroundColor(Color(red: 0.9, green: 0.8, blue: 0.6))
            }

            // Progress with chapter markers
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.9, green: 0.8, blue: 0.6),
                                    Color(red: 0.7, green: 0.5, blue: 0.3)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * progressManager.progressPercentage), height: 12)

                    // Chapter markers
                    HStack(spacing: 0) {
                        ForEach(1...8, id: \.self) { chapter in
                            if chapter > 1 {
                                Spacer()
                            }
                            Circle()
                                .fill(progressManager.isChapterCompleted(chapter) ? Color.yellow : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .frame(height: 12)

            if progressManager.isStoryComplete {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("Guardian of the Rubicon")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Chapter Grid

    private var chapterGrid: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(StoryContent.chapters.enumerated()), id: \.element.id) { index, chapter in
                ChapterCard(
                    chapter: chapter,
                    isUnlocked: progressManager.isChapterUnlocked(chapter.id),
                    isCompleted: progressManager.isChapterCompleted(chapter.id)
                ) {
                    if progressManager.isChapterUnlocked(chapter.id) {
                        selectedChapter = chapter
                    }
                }
                .opacity(cardsAppeared ? 1 : 0)
                .offset(y: cardsAppeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.08), value: cardsAppeared)
            }
        }
    }
}

// MARK: - Chapter Card

struct ChapterCard: View {
    let chapter: StoryChapter
    let isUnlocked: Bool
    let isCompleted: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background image (blurred)
                if isUnlocked {
                    Image(chapter.backgroundImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 130)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.7),
                                    Color.black.opacity(0.85)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blur(radius: 2)
                }

                HStack(spacing: 16) {
                    // Character Portrait
                    ZStack {
                        if isUnlocked {
                            // Glow
                            Circle()
                                .fill(chapter.opponent.themeColor.opacity(0.3))
                                .frame(width: 90, height: 90)
                                .blur(radius: 15)

                            Image(chapter.opponent.portraitName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(chapter.opponent.themeColor, lineWidth: 2)
                                )
                                .shadow(color: chapter.opponent.themeColor.opacity(0.5), radius: 10)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "lock.fill")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                )
                        }

                        // Completion Badge
                        if isCompleted {
                            VStack {
                                HStack {
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .fill(Color.black)
                                            .frame(width: 28, height: 28)
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.green)
                                    }
                                }
                                Spacer()
                            }
                            .frame(width: 80, height: 80)
                        }
                    }

                    // Chapter Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(chapter.chapterNumber.uppercased())
                            .font(.caption2.bold())
                            .foregroundColor(isUnlocked ? chapter.opponent.themeColor : .gray)
                            .tracking(2)

                        Text(chapter.title)
                            .font(.title3.bold())
                            .foregroundColor(isUnlocked ? .white : .gray)

                        Text(chapter.subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))

                        if isUnlocked {
                            HStack(spacing: 8) {
                                Text("vs \(chapter.opponent.fullName)")
                                    .font(.caption.bold())
                                    .foregroundColor(chapter.opponent.themeColor)

                                Text("•")
                                    .foregroundColor(.white.opacity(0.3))

                                difficultyBadge
                            }
                            .padding(.top, 2)
                        }
                    }

                    Spacer()

                    // Play Arrow
                    if isUnlocked && !isCompleted {
                        ZStack {
                            Circle()
                                .fill(chapter.opponent.themeColor.opacity(0.2))
                                .frame(width: 50, height: 50)

                            Image(systemName: "play.fill")
                                .font(.title3)
                                .foregroundColor(chapter.opponent.themeColor)
                        }
                    } else if isUnlocked && isCompleted {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 44, height: 44)

                            Image(systemName: "arrow.counterclockwise")
                                .font(.body.bold())
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(16)
            }
            .frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isUnlocked ? chapter.opponent.themeColor.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isUnlocked ? Color.clear : Color.black.opacity(0.3))
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isUnlocked ? 1 : 0.5)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }

    private var difficultyBadge: some View {
        let (text, color, icon) = difficultyInfo
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2.bold())
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
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
}

// Make StoryChapter Hashable for navigation
extension StoryChapter: Hashable {
    static func == (lhs: StoryChapter, rhs: StoryChapter) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Particle Field

struct StoryParticleField: View {
    let phase: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<15, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.1...0.25)))
                        .frame(width: CGFloat.random(in: 2...5))
                        .offset(
                            x: particleX(index: index, width: geometry.size.width),
                            y: particleY(index: index, height: geometry.size.height)
                        )
                        .blur(radius: 0.5)
                }
            }
        }
    }

    private func particleX(index: Int, width: CGFloat) -> CGFloat {
        let base = CGFloat(index) / 15.0 * width
        let offset = sin(phase * .pi * 2 + CGFloat(index) * 0.5) * 20
        return base + offset - width / 2
    }

    private func particleY(index: Int, height: CGFloat) -> CGFloat {
        let speed = CGFloat(index % 4 + 1) * 0.25
        let base = (phase * speed).truncatingRemainder(dividingBy: 1.0) * height
        return base - height / 2
    }
}

#Preview {
    StoryModeView()
}
