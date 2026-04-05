import SwiftUI

// MARK: - Template Definition

struct BoardTemplate: Identifiable {
    let id: String
    let name: String
    let description: String
    let previewGradient: (String, String) // start, end hex
    let slots: [TemplateSlot]
    let textSlots: [TemplateTextSlot]
    let isPro: Bool

    var photoSlotCount: Int {
        slots.count
    }
}

struct TemplateSlot: Identifiable {
    let id: Int
    let x: CGFloat       // 0-1 normalized
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let placeholder: String // hint text like "你的梦想旅行"
}

struct TemplateTextSlot: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let alignment: TextAlignment
    let placeholder: String
    let defaultColor: String // hex
}

// MARK: - Built-in Templates

enum BuiltinTemplates {
    static let all: [BoardTemplate] = [classic4, dreamy6, minimal1, goalsList, moodCollage, bigDream, gratitude, horizon]

    static let free: [BoardTemplate] = [classic4, dreamy6, minimal1]

    // 1. 经典四宫格 — 最容易上手
    static let classic4 = BoardTemplate(
        id: "classic4",
        name: "经典四宫格",
        description: "4 张照片 + 中心目标",
        previewGradient: ("#FDFBF9", "#E8D5E8"),
        slots: [
            TemplateSlot(id: 0, x: 0.03, y: 0.03, width: 0.455, height: 0.42, cornerRadius: 16, placeholder: "事业目标"),
            TemplateSlot(id: 1, x: 0.515, y: 0.03, width: 0.455, height: 0.42, cornerRadius: 16, placeholder: "健康目标"),
            TemplateSlot(id: 2, x: 0.03, y: 0.55, width: 0.455, height: 0.42, cornerRadius: 16, placeholder: "感情目标"),
            TemplateSlot(id: 3, x: 0.515, y: 0.55, width: 0.455, height: 0.42, cornerRadius: 16, placeholder: "生活目标"),
        ],
        textSlots: [
            TemplateTextSlot(id: 0, x: 0.5, y: 0.49, width: 0.9, fontSize: 18, fontWeight: .bold, alignment: .center, placeholder: "2026 我的愿景", defaultColor: "#FFFFFF"),
        ],
        isPro: false
    )

    // 2. 梦幻六图 — 错落拼贴
    static let dreamy6 = BoardTemplate(
        id: "dreamy6",
        name: "梦幻拼贴",
        description: "6 张照片错落排列",
        previewGradient: ("#F5DDE0", "#E8D5E8"),
        slots: [
            TemplateSlot(id: 0, x: 0.03, y: 0.03, width: 0.6, height: 0.3, cornerRadius: 16, placeholder: "最大的梦想"),
            TemplateSlot(id: 1, x: 0.66, y: 0.03, width: 0.31, height: 0.3, cornerRadius: 16, placeholder: "旅行"),
            TemplateSlot(id: 2, x: 0.03, y: 0.35, width: 0.31, height: 0.3, cornerRadius: 16, placeholder: "健康"),
            TemplateSlot(id: 3, x: 0.37, y: 0.35, width: 0.6, height: 0.3, cornerRadius: 16, placeholder: "事业"),
            TemplateSlot(id: 4, x: 0.03, y: 0.67, width: 0.455, height: 0.3, cornerRadius: 16, placeholder: "感情"),
            TemplateSlot(id: 5, x: 0.515, y: 0.67, width: 0.455, height: 0.3, cornerRadius: 16, placeholder: "学习成长"),
        ],
        textSlots: [],
        isPro: false
    )

    // 3. 极简单图 — 一张大图 + 一句话
    static let minimal1 = BoardTemplate(
        id: "minimal1",
        name: "极简心愿",
        description: "一张照片 + 一句目标",
        previewGradient: ("#FDFBF9", "#F7F3EF"),
        slots: [
            TemplateSlot(id: 0, x: 0.08, y: 0.06, width: 0.84, height: 0.65, cornerRadius: 20, placeholder: "你最想实现的事"),
        ],
        textSlots: [
            TemplateTextSlot(id: 0, x: 0.5, y: 0.80, width: 0.8, fontSize: 22, fontWeight: .semibold, alignment: .center, placeholder: "写下你的目标", defaultColor: "#2C2C2E"),
            TemplateTextSlot(id: 1, x: 0.5, y: 0.88, width: 0.7, fontSize: 14, fontWeight: .regular, alignment: .center, placeholder: "每天看一次，让它成真 ✨", defaultColor: "#6B6B6F"),
        ],
        isPro: false
    )

    // 4. 目标清单 — 左图右文
    static let goalsList = BoardTemplate(
        id: "goalsList",
        name: "目标清单",
        description: "照片 + 多个目标",
        previewGradient: ("#E8D5E8", "#93B7E3"),
        slots: [
            TemplateSlot(id: 0, x: 0.03, y: 0.03, width: 0.94, height: 0.4, cornerRadius: 20, placeholder: "愿景大图"),
        ],
        textSlots: [
            TemplateTextSlot(id: 0, x: 0.5, y: 0.49, width: 0.85, fontSize: 20, fontWeight: .bold, alignment: .center, placeholder: "我的 2026 目标", defaultColor: "#FFFFFF"),
            TemplateTextSlot(id: 1, x: 0.5, y: 0.57, width: 0.85, fontSize: 15, fontWeight: .regular, alignment: .leading, placeholder: "✦ 目标一：健康生活", defaultColor: "#FFFFFF"),
            TemplateTextSlot(id: 2, x: 0.5, y: 0.64, width: 0.85, fontSize: 15, fontWeight: .regular, alignment: .leading, placeholder: "✦ 目标二：事业突破", defaultColor: "#FFFFFF"),
            TemplateTextSlot(id: 3, x: 0.5, y: 0.71, width: 0.85, fontSize: 15, fontWeight: .regular, alignment: .leading, placeholder: "✦ 目标三：学习成长", defaultColor: "#FFFFFF"),
            TemplateTextSlot(id: 4, x: 0.5, y: 0.78, width: 0.85, fontSize: 15, fontWeight: .regular, alignment: .leading, placeholder: "✦ 目标四：享受生活", defaultColor: "#FFFFFF"),
            TemplateTextSlot(id: 5, x: 0.5, y: 0.92, width: 0.7, fontSize: 12, fontWeight: .medium, alignment: .center, placeholder: "相信自己，一切都会实现", defaultColor: "#AEAEB2"),
        ],
        isPro: true
    )

    // 5. 氛围拼贴 — 5 图 Mood Board
    static let moodCollage = BoardTemplate(
        id: "moodCollage",
        name: "氛围感拼贴",
        description: "5 张照片营造氛围",
        previewGradient: ("#A3D9C2", "#93B7E3"),
        slots: [
            TemplateSlot(id: 0, x: 0.03, y: 0.03, width: 0.55, height: 0.55, cornerRadius: 20, placeholder: "核心氛围"),
            TemplateSlot(id: 1, x: 0.61, y: 0.03, width: 0.36, height: 0.27, cornerRadius: 14, placeholder: "细节 1"),
            TemplateSlot(id: 2, x: 0.61, y: 0.32, width: 0.36, height: 0.27, cornerRadius: 14, placeholder: "细节 2"),
            TemplateSlot(id: 3, x: 0.03, y: 0.60, width: 0.36, height: 0.37, cornerRadius: 14, placeholder: "细节 3"),
            TemplateSlot(id: 4, x: 0.42, y: 0.62, width: 0.55, height: 0.35, cornerRadius: 14, placeholder: "细节 4"),
        ],
        textSlots: [],
        isPro: true
    )

    // 6. 大梦想 — 一图全屏 + 标题
    static let bigDream = BoardTemplate(
        id: "bigDream",
        name: "大梦想",
        description: "全屏照片 + 大标题",
        previewGradient: ("#2C2C2E", "#4A3A5C"),
        slots: [
            TemplateSlot(id: 0, x: 0.0, y: 0.0, width: 1.0, height: 1.0, cornerRadius: 0, placeholder: "你的大梦想"),
        ],
        textSlots: [
            TemplateTextSlot(id: 0, x: 0.5, y: 0.82, width: 0.85, fontSize: 28, fontWeight: .bold, alignment: .center, placeholder: "敢想，就能实现", defaultColor: "#FFFFFF"),
            TemplateTextSlot(id: 1, x: 0.5, y: 0.90, width: 0.7, fontSize: 14, fontWeight: .regular, alignment: .center, placeholder: "2026 · 我的愿景", defaultColor: "#FFFFFF"),
        ],
        isPro: true
    )

    // 7. 感恩版 — 3 图 + 感恩文字
    static let gratitude = BoardTemplate(
        id: "gratitude",
        name: "感恩三件事",
        description: "3 张照片 + 感恩记录",
        previewGradient: ("#F7C59F", "#E8B5BC"),
        slots: [
            TemplateSlot(id: 0, x: 0.03, y: 0.03, width: 0.305, height: 0.38, cornerRadius: 14, placeholder: "感恩 1"),
            TemplateSlot(id: 1, x: 0.348, y: 0.03, width: 0.305, height: 0.38, cornerRadius: 14, placeholder: "感恩 2"),
            TemplateSlot(id: 2, x: 0.665, y: 0.03, width: 0.305, height: 0.38, cornerRadius: 14, placeholder: "感恩 3"),
        ],
        textSlots: [
            TemplateTextSlot(id: 0, x: 0.5, y: 0.50, width: 0.85, fontSize: 20, fontWeight: .bold, alignment: .center, placeholder: "我感恩的三件事", defaultColor: "#FFFFFF"),
            TemplateTextSlot(id: 1, x: 0.5, y: 0.60, width: 0.85, fontSize: 15, fontWeight: .regular, alignment: .center, placeholder: "1. 健康的身体", defaultColor: "#FFFFFF"),
            TemplateTextSlot(id: 2, x: 0.5, y: 0.68, width: 0.85, fontSize: 15, fontWeight: .regular, alignment: .center, placeholder: "2. 爱我的家人", defaultColor: "#FFFFFF"),
            TemplateTextSlot(id: 3, x: 0.5, y: 0.76, width: 0.85, fontSize: 15, fontWeight: .regular, alignment: .center, placeholder: "3. 正在进步的自己", defaultColor: "#FFFFFF"),
        ],
        isPro: true
    )

    // 8. 地平线 — 上图下文
    static let horizon = BoardTemplate(
        id: "horizon",
        name: "地平线",
        description: "上半大图，下半文字",
        previewGradient: ("#FDFBF9", "#E8D5E8"),
        slots: [
            TemplateSlot(id: 0, x: 0.0, y: 0.0, width: 1.0, height: 0.5, cornerRadius: 0, placeholder: "最向往的画面"),
        ],
        textSlots: [
            TemplateTextSlot(id: 0, x: 0.5, y: 0.58, width: 0.8, fontSize: 24, fontWeight: .bold, alignment: .center, placeholder: "我想要的生活", defaultColor: "#2C2C2E"),
            TemplateTextSlot(id: 1, x: 0.5, y: 0.68, width: 0.8, fontSize: 14, fontWeight: .regular, alignment: .center, placeholder: "写下对未来的期待...", defaultColor: "#6B6B6F"),
            TemplateTextSlot(id: 2, x: 0.5, y: 0.85, width: 0.5, fontSize: 11, fontWeight: .medium, alignment: .center, placeholder: "2026 愿景板", defaultColor: "#AEAEB2"),
        ],
        isPro: false
    )
}
