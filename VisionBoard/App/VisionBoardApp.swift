import SwiftUI
import SwiftData

@main
struct VisionBoardApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [
            VisionBoard.self,
            BoardItem.self,
            Goal.self,
            JournalEntry.self
        ])
    }
}
