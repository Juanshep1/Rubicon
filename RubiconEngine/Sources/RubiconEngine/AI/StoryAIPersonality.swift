import Foundation

// MARK: - Story AI Personality System

/// Each story opponent has a unique playstyle that matches their character
public enum StoryAIPersonality: String, CaseIterable {
    case prodigy      // Luna - Fast, aggressive, overconfident
    case analyst      // Marcus - Calculated, pattern-focused, predictable
    case artist       // Yuki - Balanced, beautiful patterns, elegant
    case veteran      // Viktor - Defensive, patient, counter-puncher
    case scholar      // Amara - Adaptive, learns patterns, counters you
    case mirrors      // Ren & Sora - Chaotic, dual-threat, unpredictable
    case ghost        // Elias - Trap master, forcing moves, endgame
    case grandmaster  // Ishara - Perfect play, exploits every weakness
}

/// Configuration that defines an AI personality's behavior
public struct StoryAIConfig {
    public let personality: StoryAIPersonality
    public let baseDifficulty: AIDifficulty

    // Behavior modifiers (0.0 to 1.0)
    public let aggressionBias: Double       // How often to attack vs defend
    public let threatAwareness: Double      // Chance to notice player threats
    public let adaptiveness: Double         // Changes strategy mid-game
    public let chaosFactor: Double          // Random "genius" moves

    // Strategic preferences
    public let patternPreference: PatternType?      // Favored pattern type
    public let signatureVictory: VictorySetType?    // Preferred win condition
    public let useBreaks: Bool                      // Will break opponent patterns
    public let useTrapMoves: Bool                   // Uses forcing/trap moves
    public let useRiverDenial: Bool                 // Denies river stones
    public let useSuffocation: Bool                 // Restricts opponent moves

    // Special behaviors
    public let centerObsession: Bool               // Always prioritizes center
    public let neverBreaksPatterns: Bool           // Won't break (honorable)
    public let mirrorChance: Double                // Copies player moves
    public let desperationAggression: Bool         // Gets aggressive when behind
    public let hesitationOnKillingBlow: Bool       // Slight delay before winning

    // Search parameters
    public let minimaxDepth: Int
    public let movesToEvaluate: Int
}

// MARK: - Personality Configurations

extension StoryAIPersonality {
    public var config: StoryAIConfig {
        switch self {

        // ═══════════════════════════════════════════════════════════════════
        // CHAPTER 1: Luna Chen - "The Prodigy"
        // Speed over strategy, overconfident, underestimates you
        // ═══════════════════════════════════════════════════════════════════
        case .prodigy:
            return StoryAIConfig(
                personality: .prodigy,
                baseDifficulty: .easy,
                aggressionBias: 0.9,          // Almost always attacks
                threatAwareness: 0.2,         // Rarely notices your threats
                adaptiveness: 0.1,            // Doesn't change strategy
                chaosFactor: 0.0,
                patternPreference: .line,      // Goes for lines (fast win)
                signatureVictory: .theLongRoad,
                useBreaks: false,              // Too impatient to break
                useTrapMoves: false,
                useRiverDenial: false,         // Never draws from river
                useSuffocation: false,
                centerObsession: false,
                neverBreaksPatterns: true,     // Doesn't bother breaking
                mirrorChance: 0.0,
                desperationAggression: false,
                hesitationOnKillingBlow: false,
                minimaxDepth: 1,
                movesToEvaluate: 8
            )

        // ═══════════════════════════════════════════════════════════════════
        // CHAPTER 2: Marcus Webb - "The Analyst"
        // Data-driven, speaks in statistics, predictable optimal plays
        // ═══════════════════════════════════════════════════════════════════
        case .analyst:
            return StoryAIConfig(
                personality: .analyst,
                baseDifficulty: .easy,
                aggressionBias: 0.4,          // Balanced, calculates everything
                threatAwareness: 0.6,         // Notices obvious threats
                adaptiveness: 0.0,            // NEVER adapts (predictable)
                chaosFactor: 0.0,
                patternPreference: nil,        // No preference - follows data
                signatureVictory: nil,         // Pursues "optimal" path
                useBreaks: true,
                useTrapMoves: false,
                useRiverDenial: false,
                useSuffocation: false,
                centerObsession: true,         // Always takes center first!
                neverBreaksPatterns: false,
                mirrorChance: 0.0,
                desperationAggression: false,
                hesitationOnKillingBlow: false,
                minimaxDepth: 2,
                movesToEvaluate: 10
            )

        // ═══════════════════════════════════════════════════════════════════
        // CHAPTER 3: Yuki Tanaka - "The Artist"
        // Sees patterns as art, values beauty over efficiency
        // ═══════════════════════════════════════════════════════════════════
        case .artist:
            return StoryAIConfig(
                personality: .artist,
                baseDifficulty: .medium,
                aggressionBias: 0.5,          // Balanced, elegant play
                threatAwareness: 0.5,
                adaptiveness: 0.3,
                chaosFactor: 0.0,
                patternPreference: .gate,      // Loves symmetrical 2x2 gates
                signatureVictory: .theFortress, // Two gates = symmetrical beauty
                useBreaks: false,
                useTrapMoves: false,
                useRiverDenial: false,
                useSuffocation: false,
                centerObsession: false,
                neverBreaksPatterns: true,     // Breaking is "ugly/dishonorable"
                mirrorChance: 0.0,
                desperationAggression: false,
                hesitationOnKillingBlow: false,
                minimaxDepth: 2,
                movesToEvaluate: 12
            )

        // ═══════════════════════════════════════════════════════════════════
        // CHAPTER 4: Viktor Kross - "The Veteran"
        // Former champion, bitter, patient, waits for your mistakes
        // ═══════════════════════════════════════════════════════════════════
        case .veteran:
            return StoryAIConfig(
                personality: .veteran,
                baseDifficulty: .medium,
                aggressionBias: 0.3,          // Defensive counter-puncher
                threatAwareness: 0.9,         // Spots your patterns EARLY
                adaptiveness: 0.5,
                chaosFactor: 0.0,
                patternPreference: .gate,      // Defensive 2x2 formations
                signatureVictory: .theFortress,
                useBreaks: true,               // Will break if necessary
                useTrapMoves: false,
                useRiverDenial: true,
                useSuffocation: false,
                centerObsession: false,
                neverBreaksPatterns: false,
                mirrorChance: 0.0,
                desperationAggression: true,   // Gets AGGRESSIVE when behind
                hesitationOnKillingBlow: false,
                minimaxDepth: 3,
                movesToEvaluate: 14
            )

        // ═══════════════════════════════════════════════════════════════════
        // CHAPTER 5: Dr. Amara Okonkwo - "The Scholar"
        // Studies ancient patterns, adapts to YOUR playstyle
        // ═══════════════════════════════════════════════════════════════════
        case .scholar:
            return StoryAIConfig(
                personality: .scholar,
                baseDifficulty: .hard,
                aggressionBias: 0.6,          // Balanced but smart
                threatAwareness: 0.85,        // Excellent threat detection
                adaptiveness: 0.9,            // HIGHLY adaptive - counters you
                chaosFactor: 0.0,
                patternPreference: .cross,     // Sacred geometry - the Cross
                signatureVictory: .theStar,    // Pursues Cross (ancient power)
                useBreaks: true,
                useTrapMoves: true,
                useRiverDenial: true,
                useSuffocation: false,
                centerObsession: false,
                neverBreaksPatterns: false,
                mirrorChance: 0.0,
                desperationAggression: false,
                hesitationOnKillingBlow: false,
                minimaxDepth: 4,
                movesToEvaluate: 15
            )

        // ═══════════════════════════════════════════════════════════════════
        // CHAPTER 6: Ren & Sora - "The Mirrors"
        // Two minds as one, unpredictable, chaotic dual-threat strategy
        // ═══════════════════════════════════════════════════════════════════
        case .mirrors:
            return StoryAIConfig(
                personality: .mirrors,
                baseDifficulty: .hard,
                aggressionBias: 0.7,          // Aggressive but erratic
                threatAwareness: 0.7,
                adaptiveness: 0.5,
                chaosFactor: 0.2,             // 20% random "genius" moves!
                patternPreference: .line,      // Twin Rivers = two minds
                signatureVictory: .twinRivers, // Signature: 2 lines = 2 minds
                useBreaks: true,
                useTrapMoves: true,
                useRiverDenial: true,
                useSuffocation: false,
                centerObsession: false,
                neverBreaksPatterns: false,
                mirrorChance: 0.3,            // 30% chance to copy your move!
                desperationAggression: false,
                hesitationOnKillingBlow: false,
                minimaxDepth: 4,
                movesToEvaluate: 16
            )

        // ═══════════════════════════════════════════════════════════════════
        // CHAPTER 7: Elias Crane - "The Ghost"
        // Legendary player, sees 5 moves ahead, sets devastating traps
        // ═══════════════════════════════════════════════════════════════════
        case .ghost:
            return StoryAIConfig(
                personality: .ghost,
                baseDifficulty: .expert,
                aggressionBias: 0.5,          // Patient trap-setter
                threatAwareness: 0.95,        // Sees almost everything
                adaptiveness: 0.7,
                chaosFactor: 0.0,
                patternPreference: nil,        // Master of all patterns
                signatureVictory: nil,         // Wins however he can
                useBreaks: true,
                useTrapMoves: true,            // MAXIMUM trap setting
                useRiverDenial: true,
                useSuffocation: true,          // Limits your options
                centerObsession: false,
                neverBreaksPatterns: false,
                mirrorChance: 0.0,
                desperationAggression: false,
                hesitationOnKillingBlow: false,
                minimaxDepth: 5,
                movesToEvaluate: 18
            )

        // ═══════════════════════════════════════════════════════════════════
        // CHAPTER 8: Ishara - "The Grandmaster"
        // 700-year guardian, perfect play, transcendent understanding
        // ═══════════════════════════════════════════════════════════════════
        case .grandmaster:
            return StoryAIConfig(
                personality: .grandmaster,
                baseDifficulty: .master,
                aggressionBias: 0.8,          // Relentless perfect pressure
                threatAwareness: 1.0,         // PERFECT threat detection
                adaptiveness: 1.0,            // Fully adaptive
                chaosFactor: 0.0,
                patternPreference: .cross,     // The Cross is sacred
                signatureVictory: .theStar,    // The Star = transcendence
                useBreaks: true,
                useTrapMoves: true,
                useRiverDenial: true,
                useSuffocation: true,
                centerObsession: false,
                neverBreaksPatterns: false,
                mirrorChance: 0.0,
                desperationAggression: false,
                hesitationOnKillingBlow: true, // ONE chance to survive!
                minimaxDepth: 6,
                movesToEvaluate: 20
            )
        }
    }

    /// Character name for display
    public var characterName: String {
        switch self {
        case .prodigy: return "Luna Chen"
        case .analyst: return "Marcus Webb"
        case .artist: return "Yuki Tanaka"
        case .veteran: return "Viktor Kross"
        case .scholar: return "Dr. Amara Okonkwo"
        case .mirrors: return "Ren & Sora"
        case .ghost: return "Elias Crane"
        case .grandmaster: return "Ishara"
        }
    }

    /// Character title for display
    public var title: String {
        switch self {
        case .prodigy: return "The Prodigy"
        case .analyst: return "The Analyst"
        case .artist: return "The Artist"
        case .veteran: return "The Veteran"
        case .scholar: return "The Scholar"
        case .mirrors: return "The Mirrors"
        case .ghost: return "The Ghost"
        case .grandmaster: return "The Grandmaster"
        }
    }
}
