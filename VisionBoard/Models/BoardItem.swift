import SwiftUI
import SwiftData

@Model
final class BoardItem {
    var itemType: ItemType
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var rotation: Double
    var zIndex: Int
    var imageData: Data?
    var text: String?
    var fontSize: Double
    var fontWeight: String
    var textColor: String // hex
    var stickerName: String?
    var createdAt: Date

    @Relationship(inverse: \VisionBoard.items) var board: VisionBoard?

    init(
        itemType: ItemType,
        x: Double = 0.5,
        y: Double = 0.5,
        width: Double = 0.3,
        height: Double = 0.3,
        zIndex: Int = 0
    ) {
        self.itemType = itemType
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rotation = 0
        self.zIndex = zIndex
        self.imageData = nil
        self.text = nil
        self.fontSize = 20
        self.fontWeight = "semibold"
        self.textColor = "#2C2C2E"
        self.stickerName = nil
        self.createdAt = Date()
    }
}

enum ItemType: String, Codable {
    case image
    case text
    case sticker
}
