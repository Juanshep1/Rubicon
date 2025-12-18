import SwiftUI
import PhotosUI

// MARK: - Piece Customization Manager

@MainActor
public class PieceCustomizationManager: ObservableObject {
    public static let shared = PieceCustomizationManager()

    // Settings
    @AppStorage("useCustomLightPiece") public var useCustomLightPiece: Bool = false
    @AppStorage("useCustomDarkPiece") public var useCustomDarkPiece: Bool = false
    @AppStorage("lightPieceStyle") public var lightPieceStyle: Int = 0 // 0 = solid, 1 = icon, 2 = custom image
    @AppStorage("darkPieceStyle") public var darkPieceStyle: Int = 0
    @AppStorage("lightPieceIcon") public var lightPieceIcon: String = "circle.fill"
    @AppStorage("darkPieceIcon") public var darkPieceIcon: String = "circle.fill"

    // Cached images
    @Published public var lightPieceImage: UIImage?
    @Published public var darkPieceImage: UIImage?

    // File paths
    private let lightImageFileName = "custom_light_piece.png"
    private let darkImageFileName = "custom_dark_piece.png"

    private init() {
        loadSavedImages()
    }

    // MARK: - Image Storage

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func imageURL(for player: PlayerType) -> URL {
        let fileName = player == .light ? lightImageFileName : darkImageFileName
        return documentsDirectory.appendingPathComponent(fileName)
    }

    public func saveImage(_ image: UIImage, for player: PlayerType) {
        guard let data = image.pngData() else { return }

        let url = imageURL(for: player)
        do {
            try data.write(to: url)
            if player == .light {
                lightPieceImage = image
                useCustomLightPiece = true
                lightPieceStyle = 2
            } else {
                darkPieceImage = image
                useCustomDarkPiece = true
                darkPieceStyle = 2
            }
            objectWillChange.send()
        } catch {
            print("Failed to save custom piece image: \(error)")
        }
    }

    public func loadSavedImages() {
        // Load light piece
        let lightURL = imageURL(for: .light)
        if FileManager.default.fileExists(atPath: lightURL.path),
           let data = try? Data(contentsOf: lightURL),
           let image = UIImage(data: data) {
            lightPieceImage = image
        }

        // Load dark piece
        let darkURL = imageURL(for: .dark)
        if FileManager.default.fileExists(atPath: darkURL.path),
           let data = try? Data(contentsOf: darkURL),
           let image = UIImage(data: data) {
            darkPieceImage = image
        }
    }

    public func removeCustomImage(for player: PlayerType) {
        let url = imageURL(for: player)
        try? FileManager.default.removeItem(at: url)

        if player == .light {
            lightPieceImage = nil
            useCustomLightPiece = false
            lightPieceStyle = 0
        } else {
            darkPieceImage = nil
            useCustomDarkPiece = false
            darkPieceStyle = 0
        }
        objectWillChange.send()
    }

    public func hasCustomImage(for player: PlayerType) -> Bool {
        if player == .light {
            return lightPieceImage != nil
        } else {
            return darkPieceImage != nil
        }
    }

    // MARK: - Icon Options

    public static let availableIcons: [(name: String, icon: String)] = [
        ("Circle", "circle.fill"),
        ("Star", "star.fill"),
        ("Heart", "heart.fill"),
        ("Diamond", "diamond.fill"),
        ("Shield", "shield.fill"),
        ("Crown", "crown.fill"),
        ("Bolt", "bolt.fill"),
        ("Flame", "flame.fill"),
        ("Moon", "moon.fill"),
        ("Sun", "sun.max.fill"),
        ("Leaf", "leaf.fill"),
        ("Drop", "drop.fill"),
        ("Hexagon", "hexagon.fill"),
        ("Pentagon", "pentagon.fill"),
        ("Seal", "seal.fill"),
        ("Person", "person.fill"),
        ("Pawprint", "pawprint.fill"),
        ("Hare", "hare.fill"),
        ("Bird", "bird.fill"),
        ("Fish", "fish.fill"),
    ]
}

// MARK: - Player Type (for customization)

public enum PlayerType: Int, CaseIterable {
    case light = 0
    case dark = 1

    public var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

// MARK: - Piece Style

public enum PieceStyle: Int, CaseIterable {
    case solid = 0      // Default stone appearance
    case icon = 1       // SF Symbol icon
    case customImage = 2 // User uploaded image

    public var displayName: String {
        switch self {
        case .solid: return "Classic Stone"
        case .icon: return "Icon"
        case .customImage: return "Custom Image"
        }
    }
}
