import SwiftUI
import RubiconEngine

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingFinalBoard = false

    let gameMode: GameMode
    let onMainMenu: () -> Void

    init(gameMode: GameMode, onMainMenu: @escaping () -> Void) {
        self.gameMode = gameMode
        self.onMainMenu = onMainMenu
        _viewModel = StateObject(wrappedValue: GameViewModel(gameMode: gameMode))
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                // Background
                RubiconColors.menuBackground
                    .ignoresSafeArea()

                if isLandscape {
                    landscapeLayout(geometry: geometry)
                } else {
                    portraitLayout(geometry: geometry)
                }

                // Victory overlay
                if viewModel.showVictoryBanner && !showingFinalBoard, let winner = viewModel.winner {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    VictoryBannerView(
                        winner: winner,
                        victorySet: viewModel.victorySet,
                        totalMoves: viewModel.state.moveHistory.count,
                        onNewGame: {
                            showingFinalBoard = false
                            viewModel.startNewGame(gameMode: gameMode)
                        },
                        onMainMenu: onMainMenu,
                        onViewBoard: {
                            withAnimation {
                                showingFinalBoard = true
                            }
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                // Final board view overlay (shows board with dismiss button)
                if showingFinalBoard {
                    finalBoardOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.checkForAITurn()
        }
    }

    // MARK: - Final Board View

    private var finalBoardOverlay: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Final Board")
                    .font(RubiconFonts.heading(20))
                    .foregroundColor(RubiconColors.textPrimary)

                Spacer()

                Button {
                    withAnimation {
                        showingFinalBoard = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(RubiconColors.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Winner info
            if let winner = viewModel.winner {
                HStack(spacing: 8) {
                    Circle()
                        .fill(winner == .light ? Color.white : Color.black)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))

                    Text("\(winner == .light ? "Light" : "Dark") won")
                        .font(RubiconFonts.body(16))
                        .foregroundColor(RubiconColors.textPrimary)

                    if let victorySet = viewModel.victorySet {
                        Text("with \(victorySet.displayName)")
                            .font(RubiconFonts.body(14))
                            .foregroundColor(RubiconColors.textAccent)
                    }
                }
            }

            Spacer()

            // Board (view only)
            BoardView(
                board: viewModel.board,
                selectedPosition: nil,
                validDestinations: [],
                breakModeSelections: [],
                breakModeTargets: [],
                onCellTap: { _ in } // No interaction
            )
            .padding(.horizontal, 16)

            // Move history
            MoveLogView(
                moves: viewModel.state.moveHistory,
                currentPlayer: viewModel.currentPlayer
            )
            .frame(height: 70)
            .padding(.horizontal, 16)

            Spacer()

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    showingFinalBoard = false
                    viewModel.startNewGame(gameMode: gameMode)
                } label: {
                    Text("Play Again")
                }
                .rubiconStyle(isPrimary: true)

                Button {
                    onMainMenu()
                } label: {
                    Text("Menu")
                }
                .rubiconStyle(isPrimary: false)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(RubiconColors.menuBackground.ignoresSafeArea())
    }

    // MARK: - Layouts

    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View {
        ZStack {
            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal)
                    .padding(.top, 8)

                Spacer()

                // Board
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
                .padding(.horizontal, 8)

                // Move History Log
                MoveLogView(
                    moves: viewModel.state.moveHistory,
                    currentPlayer: viewModel.currentPlayer
                )
                .frame(height: 70)
                .padding(.horizontal, 8)
                .padding(.top, 8)

                Spacer()

                // HUD
                GameHUDView(
                    state: viewModel.state,
                    availablePatterns: viewModel.availablePatterns,
                    onLockPattern: viewModel.performLock,
                    onDrawFromRiver: viewModel.drawFromRiver,
                    onPass: {
                        viewModel.pass()
                    },
                    onBreak: {
                        viewModel.startBreakMode()
                    }
                )
            }
            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)

            // Break mode instructions overlay (floats above content)
            if viewModel.isInBreakMode {
                VStack {
                    Spacer()
                    breakModeOverlay
                        .padding(.bottom, 200) // Position above HUD
                }
            }
        }
    }

    @ViewBuilder
    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        ZStack {
            HStack(spacing: 0) {
                // Left panel (player info)
                VStack {
                    topBar
                    Spacer()
                    GameHUDView(
                        state: viewModel.state,
                        availablePatterns: viewModel.availablePatterns,
                        onLockPattern: viewModel.performLock,
                        onDrawFromRiver: viewModel.drawFromRiver,
                        onPass: {
                            viewModel.pass()
                        },
                        onBreak: {
                            viewModel.startBreakMode()
                        }
                    )
                }
                .frame(width: geometry.size.width * 0.35)
                .padding()

                // Board (center)
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
                .padding()
            }

            // Break mode overlay (floating)
            if viewModel.isInBreakMode {
                breakModeOverlay
            }
        }
    }

    // MARK: - Components

    private var topBar: some View {
        HStack {
            Button {
                onMainMenu()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Menu")
                }
                .font(RubiconFonts.body(16))
                .foregroundColor(RubiconColors.textSecondary)
            }

            Spacer()

            // Game mode indicator
            Text(gameModeText)
                .font(RubiconFonts.caption(12))
                .foregroundColor(RubiconColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(RubiconColors.cardBackground)
                )
        }
    }

    private var gameModeText: String {
        switch gameMode {
        case .localPassAndPlay:
            return "Local Game"
        case .vsAI(let difficulty):
            return "vs AI (\(difficulty.displayName))"
        case .onlineRanked:
            return "Ranked"
        case .onlineCasual:
            return "Casual"
        case .puzzle:
            return "Puzzle"
        case .tutorial:
            return "Tutorial"
        }
    }

    // MARK: - Break Mode Overlay

    private var breakModeOverlay: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "hammer.fill")
                    .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.3))
                Text("Break Mode")
                    .font(RubiconFonts.heading(16))
                    .foregroundColor(RubiconColors.textPrimary)
            }

            if viewModel.breakSacrificePositions.count < 2 {
                Text("Select \(2 - viewModel.breakSacrificePositions.count) of your locked stones to sacrifice")
                    .font(RubiconFonts.body(13))
                    .foregroundColor(RubiconColors.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Now tap an opponent's locked stone to break")
                    .font(RubiconFonts.body(13))
                    .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.3))
                    .multilineTextAlignment(.center)
            }

            Button("Cancel") {
                viewModel.cancelBreakMode()
            }
            .font(RubiconFonts.caption(12))
            .foregroundColor(RubiconColors.textSecondary)
            .padding(.top, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(RubiconColors.cardBackground)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.9, green: 0.4, blue: 0.3).opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview {
    GameView(gameMode: .localPassAndPlay, onMainMenu: {})
}
