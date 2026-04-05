import SwiftData
import Foundation

@Model
final class Goal {
    var title: String
    var targetValue: Double?
    var currentValue: Double
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date
    var sortOrder: Int

    @Relationship(inverse: \VisionBoard.goals) var board: VisionBoard?

    init(title: String, targetValue: Double? = nil, sortOrder: Int = 0) {
        self.title = title
        self.targetValue = targetValue
        self.currentValue = 0
        self.isCompleted = false
        self.completedAt = nil
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }

    var progress: Double {
        guard let target = targetValue, target > 0 else {
            return isCompleted ? 1.0 : 0.0
        }
        return min(currentValue / target, 1.0)
    }
}
