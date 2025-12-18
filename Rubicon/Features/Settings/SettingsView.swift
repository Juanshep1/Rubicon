import SwiftUI
import PhotosUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @AppStorage("soundEnabled") var soundEnabled = true
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("showMoveHints") var showMoveHints = true
    @AppStorage("showPatternHighlights") var showPatternHighlights = true
    @AppStorage("confirmMoves") var confirmMoves = false
    @AppStorage("autoLockPatterns") var autoLockPatterns = false
    @AppStorage("aiMoveDelay") var aiMoveDelay = 0.5

    private init() {}
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var pieceCustomization = PieceCustomizationManager.shared
    @State private var showPieceCustomization = false

    var body: some View {
        NavigationStack {
            ZStack {
                RubiconColors.menuBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Board Theme
                        settingsSection(title: "Board Theme") {
                            BoardThemePicker(selectedTheme: $themeManager.boardThemeIndex)
                        }

                        // Stone Theme
                        settingsSection(title: "Stone Theme") {
                            StoneThemePicker(selectedTheme: $themeManager.stoneThemeIndex)
                        }

                        // Piece Customization
                        settingsSection(title: "Piece Customization") {
                            Button {
                                showPieceCustomization = true
                            } label: {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .foregroundColor(RubiconColors.textAccent)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Custom Pieces")
                                            .font(RubiconFonts.body(16))
                                            .foregroundColor(RubiconColors.textPrimary)

                                        Text("Upload icons or images for your pieces")
                                            .font(RubiconFonts.caption(12))
                                            .foregroundColor(RubiconColors.textSecondary)
                                    }

                                    Spacer()

                                    // Preview of current customization
                                    HStack(spacing: 6) {
                                        piecePreview(for: .light, size: 28)
                                        piecePreview(for: .dark, size: 28)
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(RubiconColors.textSecondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }

                        // Sound & Music
                        settingsSection(title: "Sound & Music") {
                            SettingsToggle(
                                title: "Sound Effects",
                                subtitle: "Play sounds for moves and captures",
                                icon: "speaker.wave.2.fill",
                                isOn: Binding(
                                    get: { AudioManager.shared.soundEffectsEnabled },
                                    set: { AudioManager.shared.soundEffectsEnabled = $0 }
                                )
                            )

                            // Sound Effects Volume
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "speaker.wave.1.fill")
                                        .foregroundColor(RubiconColors.textAccent)
                                        .frame(width: 24)

                                    Text("Effects Volume")
                                        .font(RubiconFonts.body(16))
                                        .foregroundColor(RubiconColors.textPrimary)

                                    Spacer()

                                    Text("\(Int(AudioManager.shared.soundEffectsVolume * 100))%")
                                        .font(RubiconFonts.caption(14))
                                        .foregroundColor(RubiconColors.textAccent)
                                        .frame(width: 45)
                                }

                                Slider(
                                    value: Binding(
                                        get: { AudioManager.shared.soundEffectsVolume },
                                        set: {
                                            AudioManager.shared.soundEffectsVolume = $0
                                            AudioManager.shared.updateSoundEffectsVolume()
                                        }
                                    ),
                                    in: 0...1,
                                    step: 0.1
                                )
                                .tint(RubiconColors.textAccent)
                            }
                            .padding(.vertical, 8)

                            Divider()
                                .background(RubiconColors.textSecondary.opacity(0.3))

                            SettingsToggle(
                                title: "Background Music",
                                subtitle: "Play relaxing music during games",
                                icon: "music.note",
                                isOn: Binding(
                                    get: { AudioManager.shared.musicEnabled },
                                    set: { newValue in
                                        AudioManager.shared.musicEnabled = newValue
                                        if newValue {
                                            AudioManager.shared.startBackgroundMusic()
                                        } else {
                                            AudioManager.shared.stopBackgroundMusic()
                                        }
                                    }
                                )
                            )

                            // Music Volume
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "speaker.wave.1.fill")
                                        .foregroundColor(RubiconColors.textAccent)
                                        .frame(width: 24)

                                    Text("Music Volume")
                                        .font(RubiconFonts.body(16))
                                        .foregroundColor(RubiconColors.textPrimary)

                                    Spacer()

                                    Text("\(Int(AudioManager.shared.musicVolume * 100))%")
                                        .font(RubiconFonts.caption(14))
                                        .foregroundColor(RubiconColors.textAccent)
                                        .frame(width: 45)
                                }

                                Slider(
                                    value: Binding(
                                        get: { AudioManager.shared.musicVolume },
                                        set: {
                                            AudioManager.shared.musicVolume = $0
                                            AudioManager.shared.updateMusicVolume()
                                        }
                                    ),
                                    in: 0...1,
                                    step: 0.1
                                )
                                .tint(RubiconColors.textAccent)
                            }
                            .padding(.vertical, 8)

                            Divider()
                                .background(RubiconColors.textSecondary.opacity(0.3))

                            SettingsToggle(
                                title: "Haptic Feedback",
                                subtitle: "Vibrate on stone placement",
                                icon: "iphone.radiowaves.left.and.right",
                                isOn: $settings.hapticsEnabled
                            )
                        }

                        // Gameplay
                        settingsSection(title: "Gameplay") {
                            SettingsToggle(
                                title: "Move Hints",
                                subtitle: "Highlight valid moves when selecting",
                                icon: "lightbulb.fill",
                                isOn: $settings.showMoveHints
                            )

                            SettingsToggle(
                                title: "Pattern Highlights",
                                subtitle: "Show available patterns to lock",
                                icon: "square.3.layers.3d.down.right",
                                isOn: $settings.showPatternHighlights
                            )

                            SettingsToggle(
                                title: "Confirm Moves",
                                subtitle: "Require confirmation before moves",
                                icon: "checkmark.circle.fill",
                                isOn: $settings.confirmMoves
                            )
                        }

                        // AI Settings
                        settingsSection(title: "AI Opponent") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "timer")
                                        .foregroundColor(RubiconColors.textAccent)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("AI Move Delay")
                                            .font(RubiconFonts.body(16))
                                            .foregroundColor(RubiconColors.textPrimary)

                                        Text("Time before AI makes its move")
                                            .font(RubiconFonts.caption(12))
                                            .foregroundColor(RubiconColors.textSecondary)
                                    }

                                    Spacer()

                                    Text(String(format: "%.1fs", settings.aiMoveDelay))
                                        .font(RubiconFonts.caption(14))
                                        .foregroundColor(RubiconColors.textAccent)
                                        .frame(width: 40)
                                }

                                Slider(value: $settings.aiMoveDelay, in: 0...2, step: 0.1)
                                    .tint(RubiconColors.textAccent)
                            }
                            .padding(.vertical, 8)
                        }

                        // About
                        settingsSection(title: "About") {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(RubiconColors.textAccent)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Rubicon")
                                        .font(RubiconFonts.body(16))
                                        .foregroundColor(RubiconColors.textPrimary)

                                    Text("Version 1.0.0")
                                        .font(RubiconFonts.caption(12))
                                        .foregroundColor(RubiconColors.textSecondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 8)

                            Button {
                                // Rate app
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(RubiconColors.textAccent)
                                        .frame(width: 24)

                                    Text("Rate Rubicon")
                                        .font(RubiconFonts.body(16))
                                        .foregroundColor(RubiconColors.textPrimary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(RubiconColors.textSecondary)
                                }
                                .padding(.vertical, 8)
                            }

                            Button {
                                // Privacy policy
                            } label: {
                                HStack {
                                    Image(systemName: "hand.raised.fill")
                                        .foregroundColor(RubiconColors.textAccent)
                                        .frame(width: 24)

                                    Text("Privacy Policy")
                                        .font(RubiconFonts.body(16))
                                        .foregroundColor(RubiconColors.textPrimary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(RubiconColors.textSecondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(RubiconFonts.heading(20))
                        .foregroundColor(RubiconColors.textPrimary)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(RubiconFonts.body(16))
                        .foregroundColor(RubiconColors.textSecondary)
                    }
                }
            }
            .toolbarBackground(RubiconColors.menuBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showPieceCustomization) {
                PieceCustomizationView()
            }
        }
    }

    @ViewBuilder
    private func piecePreview(for player: PlayerType, size: CGFloat) -> some View {
        let style = PieceStyle(rawValue: player == .light ? pieceCustomization.lightPieceStyle : pieceCustomization.darkPieceStyle) ?? .solid
        let icon = player == .light ? pieceCustomization.lightPieceIcon : pieceCustomization.darkPieceIcon
        let image = player == .light ? pieceCustomization.lightPieceImage : pieceCustomization.darkPieceImage

        let stoneTheme = themeManager.stoneTheme
        let baseColor = player == .light ? stoneTheme.lightStone : stoneTheme.darkStone

        ZStack {
            Circle()
                .fill(baseColor)
                .frame(width: size, height: size)

            switch style {
            case .solid:
                EmptyView()
            case .icon:
                Image(systemName: icon)
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(player == .light ? .black.opacity(0.6) : .white.opacity(0.8))
            case .customImage:
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size * 0.8, height: size * 0.8)
                        .clipShape(Circle())
                }
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
    }

    @ViewBuilder
    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(RubiconFonts.caption(13))
                .foregroundColor(RubiconColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(RubiconColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(RubiconColors.boardBorder.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Board Theme Picker

struct BoardThemePicker: View {
    @Binding var selectedTheme: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(BoardTheme.allCases) { theme in
                    BoardThemeCard(
                        theme: theme,
                        isSelected: selectedTheme == theme.rawValue,
                        onSelect: { selectedTheme = theme.rawValue }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct BoardThemeCard: View {
    let theme: BoardTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 10) {
                // Board preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.background)
                        .frame(width: 80, height: 80)

                    // Grid lines preview
                    VStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            HStack(spacing: 12) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Circle()
                                        .fill(theme.lightSquare)
                                        .frame(width: 14, height: 14)
                                }
                            }
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? RubiconColors.textAccent : Color.clear, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)

                Text(theme.name)
                    .font(RubiconFonts.caption(11))
                    .foregroundColor(isSelected ? RubiconColors.textAccent : RubiconColors.textSecondary)
                    .lineLimit(1)
                    .frame(width: 80)
            }
        }
    }
}

// MARK: - Stone Theme Picker

struct StoneThemePicker: View {
    @Binding var selectedTheme: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(StoneTheme.allCases) { theme in
                    StoneThemeCard(
                        theme: theme,
                        isSelected: selectedTheme == theme.rawValue,
                        onSelect: { selectedTheme = theme.rawValue }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct StoneThemeCard: View {
    let theme: StoneTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 10) {
                // Stone preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(RubiconColors.cardBackground)
                        .frame(width: 80, height: 80)

                    HStack(spacing: 8) {
                        // Light stone
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [theme.lightStoneHighlight, theme.lightStone, theme.lightStoneShadow],
                                        center: .topLeading,
                                        startRadius: 0,
                                        endRadius: 25
                                    )
                                )
                                .frame(width: 28, height: 28)
                                .shadow(color: .black.opacity(0.4), radius: 3, x: 2, y: 2)
                        }

                        // Dark stone
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [theme.darkStoneHighlight, theme.darkStone, theme.darkStoneShadow],
                                        center: .topLeading,
                                        startRadius: 0,
                                        endRadius: 25
                                    )
                                )
                                .frame(width: 28, height: 28)
                                .shadow(color: .black.opacity(0.4), radius: 3, x: 2, y: 2)
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? RubiconColors.textAccent : Color.clear, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                Text(theme.name)
                    .font(RubiconFonts.caption(11))
                    .foregroundColor(isSelected ? RubiconColors.textAccent : RubiconColors.textSecondary)
                    .lineLimit(1)
                    .frame(width: 80)
            }
        }
    }
}

// MARK: - Settings Toggle

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(RubiconColors.textAccent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RubiconFonts.body(16))
                    .foregroundColor(RubiconColors.textPrimary)

                Text(subtitle)
                    .font(RubiconFonts.caption(12))
                    .foregroundColor(RubiconColors.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(RubiconColors.textAccent)
                .labelsHidden()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Piece Customization View

struct PieceCustomizationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var customization = PieceCustomizationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedPlayer: PlayerType = .light
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                RubiconColors.menuBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Player selector
                        playerSelector

                        // Current piece preview
                        piecePreviewSection

                        // Style selector
                        styleSelector

                        // Style-specific options
                        styleOptions

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Piece Customization")
                        .font(RubiconFonts.heading(18))
                        .foregroundColor(RubiconColors.textPrimary)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(RubiconFonts.body(16))
                    .foregroundColor(RubiconColors.textAccent)
                }
            }
            .toolbarBackground(RubiconColors.menuBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: selectedPhotoItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        // Resize image to reasonable size
                        let resized = resizeImage(image, to: CGSize(width: 200, height: 200))
                        customization.saveImage(resized, for: selectedPlayer)
                    }
                }
            }
        }
    }

    // MARK: - Player Selector

    private var playerSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SELECT PLAYER")
                .font(RubiconFonts.caption(13))
                .foregroundColor(RubiconColors.textSecondary)
                .tracking(1)

            HStack(spacing: 12) {
                ForEach(PlayerType.allCases, id: \.rawValue) { player in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPlayer = player
                        }
                    } label: {
                        HStack(spacing: 10) {
                            // Stone preview
                            currentPiecePreview(for: player, size: 36)

                            Text(player.displayName)
                                .font(RubiconFonts.body(16))
                                .fontWeight(selectedPlayer == player ? .semibold : .regular)
                        }
                        .foregroundColor(selectedPlayer == player ? RubiconColors.textPrimary : RubiconColors.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedPlayer == player ? RubiconColors.cardBackground : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedPlayer == player ? RubiconColors.textAccent : RubiconColors.textSecondary.opacity(0.3), lineWidth: selectedPlayer == player ? 2 : 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Piece Preview Section

    private var piecePreviewSection: some View {
        VStack(spacing: 16) {
            Text("PREVIEW")
                .font(RubiconFonts.caption(13))
                .foregroundColor(RubiconColors.textSecondary)
                .tracking(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                // Board background
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.boardTheme.background)
                    .frame(height: 140)

                // Grid pattern
                HStack(spacing: 20) {
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(spacing: 20) {
                            ForEach(0..<2, id: \.self) { _ in
                                Circle()
                                    .fill(themeManager.boardTheme.lightSquare.opacity(0.3))
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }

                // Large piece preview
                currentPiecePreview(for: selectedPlayer, size: 80)
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 2, y: 4)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(themeManager.boardTheme.border, lineWidth: 2)
            )
        }
    }

    // MARK: - Style Selector

    private var styleSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PIECE STYLE")
                .font(RubiconFonts.caption(13))
                .foregroundColor(RubiconColors.textSecondary)
                .tracking(1)

            HStack(spacing: 8) {
                ForEach(PieceStyle.allCases, id: \.rawValue) { style in
                    let isSelected = currentStyle == style

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            setStyle(style)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: styleIcon(for: style))
                                .font(.system(size: 20))

                            Text(style.displayName)
                                .font(RubiconFonts.caption(11))
                                .lineLimit(1)
                        }
                        .foregroundColor(isSelected ? RubiconColors.textAccent : RubiconColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? RubiconColors.textAccent.opacity(0.15) : RubiconColors.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? RubiconColors.textAccent : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Style Options

    @ViewBuilder
    private var styleOptions: some View {
        switch currentStyle {
        case .solid:
            VStack(alignment: .leading, spacing: 12) {
                Text("INFO")
                    .font(RubiconFonts.caption(13))
                    .foregroundColor(RubiconColors.textSecondary)
                    .tracking(1)

                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(RubiconColors.textAccent)

                    Text("Classic stone appearance. Colors are controlled by the Stone Theme setting.")
                        .font(RubiconFonts.caption(13))
                        .foregroundColor(RubiconColors.textSecondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(RubiconColors.cardBackground)
                )
            }

        case .icon:
            iconPicker

        case .customImage:
            imagePicker
        }
    }

    // MARK: - Icon Picker

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SELECT ICON")
                .font(RubiconFonts.caption(13))
                .foregroundColor(RubiconColors.textSecondary)
                .tracking(1)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(PieceCustomizationManager.availableIcons, id: \.icon) { item in
                    let isSelected = currentIcon == item.icon

                    Button {
                        withAnimation(.spring(response: 0.2)) {
                            setIcon(item.icon)
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? RubiconColors.textAccent.opacity(0.2) : RubiconColors.cardBackground)

                            Image(systemName: item.icon)
                                .font(.system(size: 24))
                                .foregroundColor(isSelected ? RubiconColors.textAccent : RubiconColors.textSecondary)
                        }
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? RubiconColors.textAccent : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Image Picker

    private var imagePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CUSTOM IMAGE")
                .font(RubiconFonts.caption(13))
                .foregroundColor(RubiconColors.textSecondary)
                .tracking(1)

            VStack(spacing: 16) {
                if customization.hasCustomImage(for: selectedPlayer) {
                    // Show current image with option to change
                    HStack(spacing: 12) {
                        currentPiecePreview(for: selectedPlayer, size: 60)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Custom image set")
                                .font(RubiconFonts.body(14))
                                .foregroundColor(RubiconColors.textPrimary)

                            HStack(spacing: 8) {
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    Text("Change")
                                        .font(RubiconFonts.caption(13))
                                        .foregroundColor(RubiconColors.textAccent)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .stroke(RubiconColors.textAccent, lineWidth: 1)
                                        )
                                }

                                Button {
                                    customization.removeCustomImage(for: selectedPlayer)
                                } label: {
                                    Text("Remove")
                                        .font(RubiconFonts.caption(13))
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                        )
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(RubiconColors.cardBackground)
                    )
                } else {
                    // Upload button
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(RubiconColors.textAccent)

                            Text("Tap to upload an image")
                                .font(RubiconFonts.body(14))
                                .foregroundColor(RubiconColors.textSecondary)

                            Text("Square images work best")
                                .font(RubiconFonts.caption(12))
                                .foregroundColor(RubiconColors.textSecondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(RubiconColors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                        .foregroundColor(RubiconColors.textSecondary.opacity(0.3))
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var currentStyle: PieceStyle {
        let styleInt = selectedPlayer == .light ? customization.lightPieceStyle : customization.darkPieceStyle
        return PieceStyle(rawValue: styleInt) ?? .solid
    }

    private var currentIcon: String {
        selectedPlayer == .light ? customization.lightPieceIcon : customization.darkPieceIcon
    }

    private func setStyle(_ style: PieceStyle) {
        if selectedPlayer == .light {
            customization.lightPieceStyle = style.rawValue
        } else {
            customization.darkPieceStyle = style.rawValue
        }
    }

    private func setIcon(_ icon: String) {
        if selectedPlayer == .light {
            customization.lightPieceIcon = icon
            customization.lightPieceStyle = PieceStyle.icon.rawValue
        } else {
            customization.darkPieceIcon = icon
            customization.darkPieceStyle = PieceStyle.icon.rawValue
        }
    }

    private func styleIcon(for style: PieceStyle) -> String {
        switch style {
        case .solid: return "circle.fill"
        case .icon: return "star.fill"
        case .customImage: return "photo.fill"
        }
    }

    @ViewBuilder
    private func currentPiecePreview(for player: PlayerType, size: CGFloat) -> some View {
        let style = PieceStyle(rawValue: player == .light ? customization.lightPieceStyle : customization.darkPieceStyle) ?? .solid
        let icon = player == .light ? customization.lightPieceIcon : customization.darkPieceIcon
        let image = player == .light ? customization.lightPieceImage : customization.darkPieceImage

        let stoneTheme = themeManager.stoneTheme
        let baseColors = player == .light
            ? [stoneTheme.lightStoneHighlight, stoneTheme.lightStone, stoneTheme.lightStoneShadow]
            : [stoneTheme.darkStoneHighlight, stoneTheme.darkStone, stoneTheme.darkStoneShadow]

        ZStack {
            // Base stone
            Circle()
                .fill(
                    RadialGradient(
                        colors: baseColors,
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.8
                    )
                )
                .frame(width: size, height: size)

            switch style {
            case .solid:
                EmptyView()
            case .icon:
                Image(systemName: icon)
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: player == .light
                                ? [Color.black.opacity(0.7), Color.black.opacity(0.5)]
                                : [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            case .customImage:
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size * 0.85, height: size * 0.85)
                        .clipShape(Circle())
                }
            }
        }
        .shadow(color: .black.opacity(0.3), radius: size * 0.05, x: 1, y: 2)
    }

    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview {
    SettingsView()
}
