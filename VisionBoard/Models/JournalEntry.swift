import SwiftData
import Foundation

@Model
final class JournalEntry {
    var date: Date
    var gratitude1: String
    var gratitude2: String
    var gratitude3: String
    var todayProgress: String
    var mood: Mood
    var createdAt: Date

    init(date: Date = .now) {
        self.date = Calendar.current.startOfDay(for: date)
        self.gratitude1 = ""
        self.gratitude2 = ""
        self.gratitude3 = ""
        self.todayProgress = ""
        self.mood = .neutral
        self.createdAt = Date()
    }

    var hasContent: Bool {
        !gratitude1.isEmpty || !gratitude2.isEmpty || !gratitude3.isEmpty || !todayProgress.isEmpty
    }
}

enum Mood: String, Codable, CaseIterable {
    case great = "超棒"
    case good = "不错"
    case neutral = "一般"
    case bad = "不好"
    case terrible = "很差"

    var emoji: String {
        switch self {
        case .great: return "🥰"
        case .good: return "😊"
        case .neutral: return "😐"
        case .bad: return "😔"
        case .terrible: return "😢"
        }
    }

    var color: String {
        switch self {
        case .great: return "#A3D9C2"
        case .good: return "#7FC9A5"
        case .neutral: return "#F0C87A"
        case .bad: return "#F7C59F"
        case .terrible: return "#D87B7B"
        }
    }
}
