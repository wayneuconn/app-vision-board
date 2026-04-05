import SwiftUI
import SwiftData

@Model
final class VisionBoard {
    var title: String
    var category: BoardCategory
    var templateId: String
    var createdAt: Date
    var updatedAt: Date
    var backgroundColor: String
    var backgroundGradientEnd: String?
    @Relationship(deleteRule: .cascade) var photoSlots: [PhotoSlotData]
    @Relationship(deleteRule: .cascade) var textSlots: [TextSlotData]
    @Relationship(deleteRule: .cascade) var goals: [Goal]

    init(templateId: String = "classic4", title: String = "我的愿景板", category: BoardCategory = .general) {
        self.templateId = templateId
        self.title = title
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
        // Set gradient from template
        let template = BuiltinTemplates.all.first { $0.id == templateId }
        self.backgroundColor = template?.previewGradient.0 ?? "#FDFBF9"
        self.backgroundGradientEnd = template?.previewGradient.1 ?? "#E8D5E8"
        self.photoSlots = []
        self.textSlots = []
        self.goals = []
    }

    var template: BoardTemplate? {
        BuiltinTemplates.all.first { $0.id == templateId }
    }

    func photoData(forSlot slotId: Int) -> Data? {
        photoSlots.first { $0.slotId == slotId }?.imageData
    }

    func textContent(forSlot slotId: Int) -> String? {
        textSlots.first { $0.slotId == slotId }?.content
    }

    func setPhoto(data: Data, forSlot slotId: Int) {
        if let existing = photoSlots.first(where: { $0.slotId == slotId }) {
            existing.imageData = data
        } else {
            let slot = PhotoSlotData(slotId: slotId, imageData: data)
            photoSlots.append(slot)
        }
        updatedAt = Date()
    }

    func setText(content: String, forSlot slotId: Int) {
        if let existing = textSlots.first(where: { $0.slotId == slotId }) {
            existing.content = content
        } else {
            let slot = TextSlotData(slotId: slotId, content: content)
            textSlots.append(slot)
        }
        updatedAt = Date()
    }
}

@Model
final class PhotoSlotData {
    var slotId: Int
    var imageData: Data
    @Relationship(inverse: \VisionBoard.photoSlots) var board: VisionBoard?

    init(slotId: Int, imageData: Data) {
        self.slotId = slotId
        self.imageData = imageData
    }
}

@Model
final class TextSlotData {
    var slotId: Int
    var content: String
    @Relationship(inverse: \VisionBoard.textSlots) var board: VisionBoard?

    init(slotId: Int, content: String) {
        self.slotId = slotId
        self.content = content
    }
}

enum BoardCategory: String, Codable, CaseIterable {
    case general = "综合"
    case career = "事业"
    case wealth = "财富"
    case health = "健康"
    case relationship = "感情"
    case travel = "旅行"
    case study = "学业"
    case lifestyle = "生活"

    var icon: String {
        switch self {
        case .general: return "sparkles"
        case .career: return "briefcase.fill"
        case .wealth: return "yensign.circle.fill"
        case .health: return "heart.fill"
        case .relationship: return "heart.text.square.fill"
        case .travel: return "airplane"
        case .study: return "book.fill"
        case .lifestyle: return "sun.max.fill"
        }
    }

    var color: Color {
        switch self {
        case .general: return AppColor.primary
        case .career: return AppColor.accentDark
        case .wealth: return AppColor.warmDark
        case .health: return AppColor.error
        case .relationship: return AppColor.secondary
        case .travel: return AppColor.accent
        case .study: return Color(hex: "#93B7E3")
        case .lifestyle: return AppColor.warm
        }
    }
}

enum AspectRatio: String, Codable, CaseIterable {
    case square = "1:1"
    case portrait = "9:16"

    var displayName: String {
        switch self {
        case .square: return "方形"
        case .portrait: return "全屏"
        }
    }
}
