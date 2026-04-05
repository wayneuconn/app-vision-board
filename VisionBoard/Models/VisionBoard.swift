import SwiftUI
import SwiftData

@Model
final class VisionBoard {
    var title: String
    var category: BoardCategory
    var createdAt: Date
    var updatedAt: Date
    var backgroundType: BackgroundType
    var backgroundColor: String // hex
    var backgroundGradientEnd: String? // hex
    var backgroundImageData: Data?
    var aspectRatio: AspectRatio
    @Relationship(deleteRule: .cascade) var items: [BoardItem]
    @Relationship(deleteRule: .cascade) var goals: [Goal]

    init(
        title: String = "我的愿景板",
        category: BoardCategory = .general,
        aspectRatio: AspectRatio = .square
    ) {
        self.title = title
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
        self.backgroundType = .gradient
        self.backgroundColor = "#FDFBF9"
        self.backgroundGradientEnd = "#E8D5E8"
        self.aspectRatio = aspectRatio
        self.items = []
        self.goals = []
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

enum BackgroundType: String, Codable {
    case solid
    case gradient
    case image
}

enum AspectRatio: String, Codable, CaseIterable {
    case square = "1:1"
    case portrait = "9:16"

    var value: CGFloat {
        switch self {
        case .square: return 1.0
        case .portrait: return 9.0 / 16.0
        }
    }

    var displayName: String {
        switch self {
        case .square: return "方形"
        case .portrait: return "全屏"
        }
    }
}
