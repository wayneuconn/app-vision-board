import SwiftUI
import SwiftData

struct BoardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var board: VisionBoard
    @State private var showingEditor = false
    @State private var showingGoalSheet = false
    @State private var showingShareOptions = false

    var body: some View {
        ZStack {
            AppColor.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    boardCanvas
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
                    Button {
                        showingEditor = true
                    } label: {
                        Label("编辑愿景板", systemImage: "pencil")
                    }
                    Button {
                        showingShareOptions = true
                    } label: {
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
            Button("方形 (1:1) — 适合小红书") {
                shareBoard(ratio: .square)
            }
            Button("全屏 (9:16) — 适合壁纸/抖音") {
                shareBoard(ratio: .portrait)
            }
            Button("取消", role: .cancel) {}
        }
    }

    private func shareBoard(ratio: AspectRatio) {
        let size: CGSize
        switch ratio {
        case .square: size = CGSize(width: 1080, height: 1080)
        case .portrait: size = CGSize(width: 1080, height: 1920)
        }
        ExportService.shareBoard(board, size: size, from: nil)
    }

    // Canvas — always square in detail view
    private var boardCanvas: some View {
        GeometryReader { geo in
            let width = geo.size.width - AppSpacing.lg * 2
            let size = CGSize(width: width, height: width) // Always square

            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: board.backgroundColor),
                                     Color(hex: board.backgroundGradientEnd ?? board.backgroundColor)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                ForEach(board.items.sorted(by: { $0.zIndex < $1.zIndex })) { item in
                    BoardItemView(item: item, canvasSize: size)
                }

                if board.items.isEmpty {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "plus.circle.dashed")
                            .font(.system(size: 40))
                        Text("点击开始编辑")
                            .font(AppFont.bodyMedium)
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(width: width, height: width)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
            .frame(maxWidth: .infinity)
        }
        .frame(height: UIScreen.main.bounds.width - AppSpacing.lg * 2)
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Goals

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("目标追踪")
                    .font(AppFont.titleMedium)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Button {
                    showingGoalSheet = true
                } label: {
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

// MARK: - Board Item View

struct BoardItemView: View {
    let item: BoardItem
    let canvasSize: CGSize

    var body: some View {
        Group {
            switch item.itemType {
            case .image:
                if let data = item.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
            case .text:
                Text(item.text ?? "")
                    .font(.system(size: item.fontSize, weight: fontWeight))
                    .foregroundStyle(Color(hex: item.textColor))
                    .multilineTextAlignment(.center)
            case .sticker:
                if let name = item.stickerName {
                    Image(systemName: name)
                        .font(.system(size: item.fontSize))
                        .foregroundStyle(Color(hex: item.textColor))
                }
            }
        }
        .frame(
            width: canvasSize.width * item.width,
            height: canvasSize.height * item.height
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .rotationEffect(.degrees(item.rotation))
        .position(
            x: canvasSize.width * item.x,
            y: canvasSize.height * item.y
        )
    }

    private var fontWeight: Font.Weight {
        switch item.fontWeight {
        case "bold": return .bold
        case "semibold": return .semibold
        case "medium": return .medium
        default: return .regular
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
                        let goal = Goal(
                            title: title,
                            targetValue: hasTarget ? Double(targetValue) : nil,
                            sortOrder: board.goals.count
                        )
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
