import Foundation
import SwiftUI

// MARK: - Chapter Phase (for save/resume)

enum SavedChapterPhase: String, Codable {
    case intro
    case preMatch
    case battle
    case postMatch
    case complete
}

// MARK: - In-Progress Chapter State

struct InProgressChapter: Codable {
    var chapterId: Int
    var phase: SavedChapterPhase
    var hasShownMidMatch: Bool
}

// MARK: - Story Progress Manager

class StoryProgressManager: ObservableObject {
    static let shared = StoryProgressManager()

    @Published var progress: StoryProgress {
        didSet {
            saveProgress()
        }
    }

    @Published var inProgressChapter: InProgressChapter? {
        didSet {
            saveInProgressChapter()
        }
    }

    private let progressKey = "storyProgress"
    private let inProgressKey = "storyInProgressChapter"

    private init() {
        // Load completed chapters
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode(StoryProgress.self, from: data) {
            self.progress = decoded
        } else {
            self.progress = StoryProgress()
        }

        // Load in-progress chapter
        if let data = UserDefaults.standard.data(forKey: inProgressKey),
           let decoded = try? JSONDecoder().decode(InProgressChapter.self, from: data) {
            self.inProgressChapter = decoded
        } else {
            self.inProgressChapter = nil
        }
    }

    // MARK: - Progress Management

    func isChapterUnlocked(_ chapterId: Int) -> Bool {
        progress.isChapterUnlocked(chapterId)
    }

    func isChapterCompleted(_ chapterId: Int) -> Bool {
        progress.isChapterCompleted(chapterId)
    }

    func completeChapter(_ chapterId: Int) {
        progress.completeChapter(chapterId)

        // Clear in-progress state for this chapter
        if inProgressChapter?.chapterId == chapterId {
            inProgressChapter = nil
        }

        // Update achievements
        AchievementManager.shared.updateProgress(for: "story_chapter_\(chapterId)")

        // Check for story completion achievement
        if progress.completedChapters.count == 8 {
            AchievementManager.shared.updateProgress(for: "story_complete")
        }
    }

    func resetProgress() {
        progress = StoryProgress()
        inProgressChapter = nil
    }

    // MARK: - In-Progress Chapter Management

    func startChapter(_ chapterId: Int) {
        inProgressChapter = InProgressChapter(
            chapterId: chapterId,
            phase: .intro,
            hasShownMidMatch: false
        )
    }

    func updateChapterPhase(_ phase: SavedChapterPhase) {
        guard var current = inProgressChapter else { return }
        current.phase = phase
        inProgressChapter = current
    }

    func setMidMatchShown() {
        guard var current = inProgressChapter else { return }
        current.hasShownMidMatch = true
        inProgressChapter = current
    }

    func clearInProgressChapter() {
        inProgressChapter = nil
    }

    func hasInProgressChapter(_ chapterId: Int) -> Bool {
        inProgressChapter?.chapterId == chapterId
    }

    func getResumePhase(for chapterId: Int) -> SavedChapterPhase? {
        guard let inProgress = inProgressChapter,
              inProgress.chapterId == chapterId else {
            return nil
        }
        return inProgress.phase
    }

    // MARK: - Persistence

    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
    }

    private func saveInProgressChapter() {
        if let inProgress = inProgressChapter,
           let encoded = try? JSONEncoder().encode(inProgress) {
            UserDefaults.standard.set(encoded, forKey: inProgressKey)
        } else {
            UserDefaults.standard.removeObject(forKey: inProgressKey)
        }
    }

    // MARK: - Computed Properties

    var completedChapterCount: Int {
        progress.completedChapters.count
    }

    var totalChapters: Int {
        8
    }

    var progressPercentage: Double {
        Double(completedChapterCount) / Double(totalChapters)
    }

    var nextUnlockedChapter: StoryChapter? {
        for i in 1...8 {
            if isChapterUnlocked(i) && !isChapterCompleted(i) {
                return StoryContent.chapter(for: i)
            }
        }
        return nil
    }

    var isStoryComplete: Bool {
        completedChapterCount == totalChapters
    }

    var resumableChapter: StoryChapter? {
        guard let inProgress = inProgressChapter else { return nil }
        return StoryContent.chapter(for: inProgress.chapterId)
    }
}
