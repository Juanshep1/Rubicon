import SwiftUI
import RubiconEngine

// MARK: - Story Character

enum StoryCharacter: String, CaseIterable, Codable {
    case kai = "kai_morrow"
    case luna = "luna_chen"
    case marcus = "marcus_webb"
    case yuki = "yuki_tanaka"
    case viktor = "viktor_kross"
    case amara = "amara_okonkwo"
    case ren = "ren"
    case sora = "sora"
    case elias = "elias_crane"
    case ishara = "ishara"
    case kaiGrandmaster = "kai_grandmaster"
    case narrator = "narrator"

    var displayName: String {
        switch self {
        case .kai, .kaiGrandmaster: return "Kai"
        case .luna: return "Luna"
        case .marcus: return "Marcus"
        case .yuki: return "Yuki"
        case .viktor: return "Viktor"
        case .amara: return "Amara"
        case .ren: return "Ren"
        case .sora: return "Sora"
        case .elias: return "Elias"
        case .ishara: return "Ishara"
        case .narrator: return ""
        }
    }

    var fullName: String {
        switch self {
        case .kai: return "Kai Morrow"
        case .luna: return "Luna Chen"
        case .marcus: return "Marcus Webb"
        case .yuki: return "Yuki Tanaka"
        case .viktor: return "Viktor Kross"
        case .amara: return "Dr. Amara Okonkwo"
        case .ren: return "Ren"
        case .sora: return "Sora"
        case .elias: return "Elias Crane"
        case .ishara: return "Ishara"
        case .kaiGrandmaster: return "Kai Morrow"
        case .narrator: return "Narrator"
        }
    }

    var title: String {
        switch self {
        case .kai: return "The Challenger"
        case .luna: return "The Prodigy"
        case .marcus: return "The Analyst"
        case .yuki: return "The Artist"
        case .viktor: return "The Veteran"
        case .amara: return "The Scholar"
        case .ren, .sora: return "The Mirrors"
        case .elias: return "The Ghost"
        case .ishara: return "The Grandmaster"
        case .kaiGrandmaster: return "The Guardian"
        case .narrator: return ""
        }
    }

    var portraitName: String {
        return rawValue
    }

    var themeColor: Color {
        switch self {
        case .kai, .kaiGrandmaster: return Color(red: 0.3, green: 0.5, blue: 0.8)
        case .luna: return Color(red: 0.7, green: 0.7, blue: 0.9)
        case .marcus: return Color(red: 0.4, green: 0.4, blue: 0.5)
        case .yuki: return Color(red: 0.9, green: 0.6, blue: 0.7)
        case .viktor: return Color(red: 0.6, green: 0.3, blue: 0.2)
        case .amara: return Color(red: 0.8, green: 0.6, blue: 0.3)
        case .ren: return Color(red: 0.9, green: 0.9, blue: 0.95)
        case .sora: return Color(red: 0.15, green: 0.15, blue: 0.2)
        case .elias: return Color(red: 0.6, green: 0.7, blue: 0.8)
        case .ishara: return Color(red: 0.8, green: 0.7, blue: 0.9)
        case .narrator: return .gray
        }
    }

    var isLeftSide: Bool {
        switch self {
        case .kai, .kaiGrandmaster: return true
        default: return false
        }
    }
}

// MARK: - Dialogue Entry

struct DialogueEntry: Identifiable, Codable {
    let id: UUID
    let speaker: StoryCharacter
    let text: String
    let isNarration: Bool
    let triggersAt: DialogueTrigger?

    init(speaker: StoryCharacter, text: String, isNarration: Bool = false, triggersAt: DialogueTrigger? = nil) {
        self.id = UUID()
        self.speaker = speaker
        self.text = text
        self.isNarration = isNarration
        self.triggersAt = triggersAt
    }

    // Convenience for narration
    static func narration(_ text: String) -> DialogueEntry {
        DialogueEntry(speaker: .narrator, text: text, isNarration: true)
    }
}

enum DialogueTrigger: String, Codable {
    case preMatch = "pre_match"
    case midMatch = "mid_match"
    case postMatch = "post_match"
    case firstLock = "first_lock"
    case nearVictory = "near_victory"
}

// MARK: - Story Chapter

struct StoryChapter: Identifiable, Codable {
    let id: Int
    let title: String
    let subtitle: String
    let opponent: StoryCharacter
    let difficulty: AIDifficulty
    let location: String
    let backgroundImage: String
    let preMatchDialogue: [DialogueEntry]
    let midMatchDialogue: [DialogueEntry]
    let postMatchDialogue: [DialogueEntry]

    var chapterNumber: String {
        "Chapter \(id)"
    }

    var isEpilogue: Bool {
        return id == 9
    }

    /// Each chapter's opponent has a unique AI personality
    var aiPersonality: StoryAIPersonality {
        switch id {
        case 1: return .prodigy      // Luna - Rush aggression, overconfident
        case 2: return .analyst      // Marcus - Predictable, center-focused
        case 3: return .artist       // Yuki - Elegant patterns, no breaks
        case 4: return .veteran      // Viktor - Defensive, counter-attacks
        case 5: return .scholar      // Amara - Adaptive, counters you
        case 6: return .mirrors      // Twins - Chaotic, dual-threat
        case 7: return .ghost        // Elias - Trap master, suffocation
        case 8: return .grandmaster  // Ishara - Perfect play, one mercy
        default: return .grandmaster
        }
    }
}

// MARK: - Story Progress

struct StoryProgress: Codable {
    var completedChapters: Set<Int> = []
    var currentChapter: Int = 1
    var hasSeenEpilogue: Bool = false

    func isChapterUnlocked(_ chapterId: Int) -> Bool {
        if chapterId == 1 { return true }
        return completedChapters.contains(chapterId - 1)
    }

    func isChapterCompleted(_ chapterId: Int) -> Bool {
        return completedChapters.contains(chapterId)
    }

    mutating func completeChapter(_ chapterId: Int) {
        completedChapters.insert(chapterId)
        if chapterId >= currentChapter {
            currentChapter = chapterId + 1
        }
    }
}
