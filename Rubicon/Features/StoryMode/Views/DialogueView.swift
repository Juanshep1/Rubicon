import SwiftUI

struct DialogueView: View {
    let dialogues: [DialogueEntry]
    let backgroundImage: String?
    let onComplete: () -> Void

    @State private var currentIndex = 0
    @State private var displayedText = ""
    @State private var isTyping = false

    private let typewriterSpeed = 0.025

    init(dialogues: [DialogueEntry], backgroundImage: String? = nil, onComplete: @escaping () -> Void) {
        self.dialogues = dialogues
        self.backgroundImage = backgroundImage
        self.onComplete = onComplete
    }

    private var currentDialogue: DialogueEntry {
        guard currentIndex < dialogues.count else {
            return DialogueEntry(speaker: .narrator, text: "")
        }
        return dialogues[currentIndex]
    }

    private var shouldShowPortrait: Bool {
        !currentDialogue.isNarration && currentDialogue.speaker != .narrator
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // OPAQUE background - completely covers everything
                Color.black
                    .ignoresSafeArea()

                // Background image (optional)
                if let bgImage = backgroundImage {
                    Image(bgImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.3),
                                    Color.black.opacity(0.6),
                                    Color.black.opacity(0.9)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .ignoresSafeArea()
                }

                // Content
                VStack(spacing: 0) {
                    // Skip button at top
                    HStack {
                        Spacer()
                        Button(action: { onComplete() }) {
                            HStack(spacing: 4) {
                                Text("Skip")
                                    .font(.caption.bold())
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 8))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.6))
                            )
                        }
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 8)
                    .padding(.horizontal, 16)

                    Spacer()

                    // Portrait section (if showing)
                    if shouldShowPortrait {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(currentDialogue.speaker.themeColor.opacity(0.3))
                                    .frame(width: 70, height: 70)
                                    .blur(radius: 12)

                                Image(currentDialogue.speaker.portraitName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(currentDialogue.speaker.themeColor, lineWidth: 2)
                                    )
                            }

                            Text(currentDialogue.speaker.displayName)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)

                            Text(currentDialogue.speaker.title)
                                .font(.caption)
                                .foregroundColor(currentDialogue.speaker.themeColor)
                        }
                        .padding(.bottom, 16)
                    }

                    Spacer()

                    // Dialogue box - FIXED WIDTH and properly constrained
                    VStack(alignment: .leading, spacing: 10) {
                        // Speaker name bar (for non-narration)
                        if !currentDialogue.isNarration {
                            HStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(currentDialogue.speaker.themeColor)
                                    .frame(width: 3, height: 16)

                                Text(currentDialogue.speaker.displayName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(currentDialogue.speaker.themeColor)

                                Spacer()
                            }
                        }

                        // Text content - properly constrained
                        ScrollView(.vertical, showsIndicators: false) {
                            Text(currentDialogue.isNarration ? displayedText : "\"\(displayedText)\"")
                                .font(.system(size: 16))
                                .italic(currentDialogue.isNarration)
                                .foregroundColor(.white)
                                .lineSpacing(5)
                                .multilineTextAlignment(currentDialogue.isNarration ? .center : .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(height: 100)

                        // Progress indicator
                        HStack {
                            Text("\(currentIndex + 1)/\(dialogues.count)")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.5))

                            Spacer()

                            if !isTyping {
                                HStack(spacing: 4) {
                                    Text("Tap to continue")
                                        .font(.caption)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(currentDialogue.speaker.themeColor.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startTypewriter()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
    }

    // MARK: - Typewriter Effect

    private func startTypewriter() {
        guard currentIndex < dialogues.count else { return }
        let fullText = dialogues[currentIndex].text
        displayedText = ""
        isTyping = true

        var charIndex = 0
        Timer.scheduledTimer(withTimeInterval: typewriterSpeed, repeats: true) { timer in
            if charIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: charIndex)
                displayedText += String(fullText[index])
                charIndex += 1
            } else {
                timer.invalidate()
                isTyping = false
            }
        }
    }

    private func handleTap() {
        if isTyping {
            displayedText = dialogues[currentIndex].text
            isTyping = false
        } else {
            if currentIndex < dialogues.count - 1 {
                currentIndex += 1
                startTypewriter()
            } else {
                onComplete()
            }
        }
    }
}
