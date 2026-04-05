import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var showingEditor = false
    @State private var selectedEntry: JournalEntry?

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
                        // Today's card
                        todayCard

                        // Streak
                        if streakDays > 0 {
                            streakBanner
                        }

                        // Past entries
                        if !entries.isEmpty {
                            pastEntries
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                }
            }
            .navigationTitle("显化日记")
            .sheet(isPresented: $showingEditor) {
                if let entry = selectedEntry {
                    JournalEditorSheet(entry: entry)
                }
            }
        }
    }

    private var todayCard: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今天")
                        .font(AppFont.titleLarge)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(Date().formatted(.dateTime.month(.wide).day()))
                        .font(AppFont.bodySmall)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()

                if let entry = todayEntry, entry.hasContent {
                    Text(entry.mood.emoji)
                        .font(.title)
                }
            }

            if let entry = todayEntry, entry.hasContent {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    if !entry.gratitude1.isEmpty {
                        gratitudeRow(number: 1, text: entry.gratitude1)
                    }
                    if !entry.gratitude2.isEmpty {
                        gratitudeRow(number: 2, text: entry.gratitude2)
                    }
                    if !entry.gratitude3.isEmpty {
                        gratitudeRow(number: 3, text: entry.gratitude3)
                    }
                }

                Button("编辑今日日记") {
                    selectedEntry = entry
                    showingEditor = true
                }
                .buttonStyle(SecondaryButtonStyle())
            } else {
                Text("记录今天的感恩与进展，让显化更有力量 ✨")
                    .font(AppFont.bodyMedium)
                    .foregroundStyle(AppColor.textSecondary)

                Button("写今日日记") {
                    let entry = todayEntry ?? JournalEntry()
                    if todayEntry == nil {
                        modelContext.insert(entry)
                    }
                    selectedEntry = entry
                    showingEditor = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .appCard()
    }

    private func gratitudeRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            Text("\(number).")
                .font(AppFont.bodySmall)
                .foregroundStyle(AppColor.primary)
                .frame(width: 20)
            Text(text)
                .font(AppFont.bodyMedium)
                .foregroundStyle(AppColor.textPrimary)
        }
    }

    private var streakBanner: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(AppColor.warm)
            Text("已连续记录 \(streakDays) 天")
                .font(AppFont.titleSmall)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(
            LinearGradient(
                colors: [AppColor.warm.opacity(0.15), AppColor.secondary.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private var pastEntries: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("历史记录")
                .font(AppFont.titleMedium)
                .foregroundStyle(AppColor.textPrimary)

            ForEach(entries.filter { $0.hasContent }) { entry in
                Button {
                    selectedEntry = entry
                    showingEditor = true
                } label: {
                    HStack {
                        Text(entry.mood.emoji)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.date.formatted(.dateTime.month().day().weekday(.wide)))
                                .font(AppFont.bodyMedium)
                                .foregroundStyle(AppColor.textPrimary)
                            Text(entry.gratitude1.isEmpty ? "—" : entry.gratitude1)
                                .font(AppFont.bodySmall)
                                .foregroundStyle(AppColor.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColor.textTertiary)
                    }
                    .appCard()
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Journal Editor

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
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("今天心情如何？")
                                .font(AppFont.titleSmall)
                                .foregroundStyle(AppColor.textPrimary)

                            HStack(spacing: AppSpacing.sm) {
                                ForEach(Mood.allCases, id: \.self) { mood in
                                    Button {
                                        entry.mood = mood
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
                                        .padding(.vertical, AppSpacing.xs)
                                        .background(
                                            entry.mood == mood ? Color(hex: mood.color).opacity(0.15) : AppColor.bgSecondary
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Gratitude
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("今天感恩的 3 件事")
                                .font(AppFont.titleSmall)
                                .foregroundStyle(AppColor.textPrimary)

                            gratitudeField(number: 1, text: $entry.gratitude1)
                            gratitudeField(number: 2, text: $entry.gratitude2)
                            gratitudeField(number: 3, text: $entry.gratitude3)
                        }

                        // Progress
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("今日目标进展")
                                .font(AppFont.titleSmall)
                                .foregroundStyle(AppColor.textPrimary)

                            TextField("今天在哪些目标上有进展？", text: $entry.todayProgress, axis: .vertical)
                                .font(AppFont.bodyMedium)
                                .padding(AppSpacing.sm)
                                .background(AppColor.bgSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                                .lineLimit(2...6)
                        }
                    }
                    .padding(AppSpacing.lg)
                }
            }
            .navigationTitle("显化日记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { dismiss() }
                        .fontWeight(.semibold)
                        .tint(AppColor.primary)
                }
            }
        }
    }

    private func gratitudeField(number: Int, text: Binding<String>) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            Text("\(number).")
                .font(AppFont.bodyMedium)
                .foregroundStyle(AppColor.primary)
                .frame(width: 24)
                .padding(.top, AppSpacing.sm)
            TextField("感恩...", text: text)
                .font(AppFont.bodyMedium)
                .padding(AppSpacing.sm)
                .background(AppColor.bgSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        }
    }
}
