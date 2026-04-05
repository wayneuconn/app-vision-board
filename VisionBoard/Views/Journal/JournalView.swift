import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VisionBoard.updatedAt, order: .reverse) private var boards: [VisionBoard]
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var showingEditor = false

    private var todayEntry: JournalEntry? {
        let today = Calendar.current.startOfDay(for: Date())
        return entries.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var streakDays: Int {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: Date())
        for entry in entries {
            let entryDate = calendar.startOfDay(for: entry.date)
            if entryDate == checkDate && entry.hasContent {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if entryDate < checkDate {
                break
            }
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // My vision boards summary
                        if !boards.isEmpty {
                            boardsSummary
                        }

                        // Daily check-in
                        dailyCheckIn

                        // Streak
                        if streakDays > 0 {
                            streakBanner
                        }

                        // Past entries
                        if entries.count > 1 || (entries.count == 1 && todayEntry == nil) {
                            pastSection
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.xs)
                    .padding(.bottom, AppSpacing.xxxl)
                }
            }
            .navigationTitle("今日")
            .sheet(isPresented: $showingEditor) {
                JournalEditorSheet(entry: getOrCreateTodayEntry())
            }
        }
    }

    // MARK: - Boards Summary

    private var boardsSummary: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("我的愿景")
                .font(AppFont.titleSmall)
                .foregroundStyle(AppColor.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(boards.prefix(5)) { board in
                        VStack(spacing: AppSpacing.xxs) {
                            TemplateBoardRenderer(board: board)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                            Text(board.title)
                                .font(AppFont.caption2)
                                .foregroundStyle(AppColor.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(width: 80)
                    }
                }
            }
        }
    }

    // MARK: - Daily Check-in

    private var dailyCheckIn: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Date().formatted(.dateTime.month(.wide).day().weekday(.wide)))
                        .font(AppFont.titleMedium)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("今天过得怎么样？")
                        .font(AppFont.bodySmall)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                if let entry = todayEntry, entry.hasContent {
                    Text(entry.mood.emoji)
                        .font(.largeTitle)
                }
            }

            if let entry = todayEntry, entry.hasContent {
                // Show today's entry
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    if !entry.gratitude1.isEmpty {
                        checkInRow("今天感恩", entry.gratitude1)
                    }
                    if !entry.todayProgress.isEmpty {
                        checkInRow("目标进展", entry.todayProgress)
                    }
                }

                Button("编辑今日记录") {
                    showingEditor = true
                }
                .buttonStyle(SecondaryButtonStyle())
            } else {
                // Prompt to write
                Button("记录今天") {
                    showingEditor = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .appCard()
    }

    private func checkInRow(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AppFont.caption1)
                .foregroundStyle(AppColor.primary)
            Text(text)
                .font(AppFont.bodyMedium)
                .foregroundStyle(AppColor.textPrimary)
        }
    }

    // MARK: - Streak

    private var streakBanner: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(AppColor.warm)
            Text("连续记录 \(streakDays) 天")
                .font(AppFont.titleSmall)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(
            LinearGradient(
                colors: [AppColor.warm.opacity(0.12), AppColor.secondary.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Past Entries

    private var pastSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("历史记录")
                .font(AppFont.titleSmall)
                .foregroundStyle(AppColor.textPrimary)

            ForEach(entries.filter { $0.hasContent && !Calendar.current.isDateInToday($0.date) }.prefix(10)) { entry in
                HStack {
                    Text(entry.mood.emoji)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.date.formatted(.dateTime.month().day()))
                            .font(AppFont.bodySmall)
                            .foregroundStyle(AppColor.textPrimary)
                        Text(entry.gratitude1.isEmpty ? entry.todayProgress : entry.gratitude1)
                            .font(AppFont.caption1)
                            .foregroundStyle(AppColor.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(AppSpacing.sm)
                .background(AppColor.bgSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            }
        }
    }

    // MARK: - Helpers

    private func getOrCreateTodayEntry() -> JournalEntry {
        if let existing = todayEntry { return existing }
        let entry = JournalEntry()
        modelContext.insert(entry)
        return entry
    }
}

// MARK: - Journal Editor (simplified)

struct JournalEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: JournalEntry

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Mood
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("今天的心情")
                                .font(AppFont.titleSmall)
                                .foregroundStyle(AppColor.textPrimary)

                            HStack(spacing: AppSpacing.sm) {
                                ForEach(Mood.allCases, id: \.self) { mood in
                                    Button {
                                        withAnimation(AppAnimation.springSnappy) {
                                            entry.mood = mood
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(mood.emoji)
                                                .font(.title2)
                                            Text(mood.rawValue)
                                                .font(AppFont.caption2)
                                                .foregroundStyle(
                                                    entry.mood == mood ? Color(hex: mood.color) : AppColor.textTertiary
                                                )
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppSpacing.sm)
                                        .background(
                                            entry.mood == mood ? Color(hex: mood.color).opacity(0.12) : AppColor.bgSecondary
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Gratitude (simplified to 1 field)
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("今天感恩的事")
                                .font(AppFont.titleSmall)
                                .foregroundStyle(AppColor.textPrimary)

                            TextField("今天有什么值得感恩的？", text: $entry.gratitude1, axis: .vertical)
                                .font(AppFont.bodyMedium)
                                .padding(AppSpacing.sm)
                                .background(AppColor.bgSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                                .lineLimit(2...5)
                        }

                        // Progress toward goals
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("目标进展")
                                .font(AppFont.titleSmall)
                                .foregroundStyle(AppColor.textPrimary)

                            TextField("今天在愿景板上的目标有什么进展？", text: $entry.todayProgress, axis: .vertical)
                                .font(AppFont.bodyMedium)
                                .padding(AppSpacing.sm)
                                .background(AppColor.bgSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                                .lineLimit(2...5)
                        }

                        // Optional: gratitude 2 & 3
                        DisclosureGroup("记录更多") {
                            VStack(spacing: AppSpacing.sm) {
                                TextField("第二件感恩的事（可选）", text: $entry.gratitude2)
                                    .font(AppFont.bodyMedium)
                                    .padding(AppSpacing.sm)
                                    .background(AppColor.bgSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                                TextField("第三件感恩的事（可选）", text: $entry.gratitude3)
                                    .font(AppFont.bodyMedium)
                                    .padding(AppSpacing.sm)
                                    .background(AppColor.bgSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                            }
                            .padding(.top, AppSpacing.xs)
                        }
                        .tint(AppColor.textSecondary)
                    }
                    .padding(AppSpacing.lg)
                }
            }
            .navigationTitle("今日记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.primary)
                }
            }
        }
    }
}
