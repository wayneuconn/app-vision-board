import SwiftUI
import SwiftData

struct BoardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var board: VisionBoard
    @State private var showingEditor = false
    @State private var showingShareOptions = false
    @State private var showingGoalSheet = false

    var body: some View {
        ZStack {
            AppColor.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Board rendered preview
                    TemplateBoardRenderer(board: board)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
                        .padding(.horizontal, AppSpacing.lg)
                        .onTapGesture { showingEditor = true }

                    // Actions
                    HStack(spacing: AppSpacing.sm) {
                        Button {
                            showingEditor = true
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button {
                            showingShareOptions = true
                        } label: {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Goals
                    goalsSection
                }
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .navigationTitle(board.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEditor = true } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    Button { showingShareOptions = true } label: {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                    Divider()
                    Button(role: .destructive) {
                        modelContext.delete(board)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .fullScreenCover(isPresented: $showingEditor) {
            BoardEditorView(board: board)
        }
        .sheet(isPresented: $showingGoalSheet) {
            AddGoalSheet(board: board)
        }
        .confirmationDialog("选择分享格式", isPresented: $showingShareOptions) {
            Button("方形 1:1（小红书）") {
                ExportService.shareBoard(board, size: CGSize(width: 1080, height: 1080), from: nil)
            }
            Button("竖屏 9:16（壁纸/抖音）") {
                ExportService.shareBoard(board, size: CGSize(width: 1080, height: 1920), from: nil)
            }
            Button("取消", role: .cancel) {}
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("目标追踪")
                    .font(AppFont.titleMedium)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Button { showingGoalSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppColor.primary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)

            if board.goals.isEmpty {
                Text("添加目标来追踪你的愿景实现进度")
                    .font(AppFont.bodySmall)
                    .foregroundStyle(AppColor.textTertiary)
                    .padding(.horizontal, AppSpacing.lg)
            } else {
                ForEach(board.goals.sorted(by: { $0.sortOrder < $1.sortOrder })) { goal in
                    GoalRowView(goal: goal)
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }
}

// MARK: - Goal Row

struct GoalRowView: View {
    @Bindable var goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Button {
                    withAnimation(AppAnimation.springGentle) {
                        goal.isCompleted.toggle()
                        goal.completedAt = goal.isCompleted ? Date() : nil
                    }
                } label: {
                    Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(goal.isCompleted ? AppColor.success : AppColor.textTertiary)
                }
                Text(goal.title)
                    .font(AppFont.bodyLarge)
                    .foregroundStyle(goal.isCompleted ? AppColor.textTertiary : AppColor.textPrimary)
                    .strikethrough(goal.isCompleted)
                Spacer()
                if let target = goal.targetValue {
                    Text("\(Int(goal.currentValue))/\(Int(target))")
                        .font(AppFont.caption1)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            if goal.targetValue != nil {
                ProgressView(value: goal.progress)
                    .tint(AppColor.primary)
            }
        }
        .appCard()
    }
}

// MARK: - Add Goal Sheet

struct AddGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var board: VisionBoard
    @State private var title = ""
    @State private var hasTarget = false
    @State private var targetValue = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bgPrimary.ignoresSafeArea()
                VStack(spacing: AppSpacing.xl) {
                    TextField("目标内容", text: $title)
                        .font(AppFont.bodyLarge)
                        .padding(AppSpacing.sm)
                        .background(AppColor.bgSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                    Toggle("设定数值目标", isOn: $hasTarget)
                        .tint(AppColor.primary)

                    if hasTarget {
                        TextField("目标数值（如 10000）", text: $targetValue)
                            .font(AppFont.bodyLarge)
                            .keyboardType(.numberPad)
                            .padding(AppSpacing.sm)
                            .background(AppColor.bgSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                    }
                    Spacer()
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("添加目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        let goal = Goal(title: title, targetValue: hasTarget ? Double(targetValue) : nil, sortOrder: board.goals.count)
                        board.goals.append(goal)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                    .tint(AppColor.primary)
                }
            }
        }
    }
}
