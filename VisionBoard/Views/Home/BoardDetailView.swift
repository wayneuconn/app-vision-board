import SwiftUI
import SwiftData

struct BoardDetailView: View {
    @Bindable var board: VisionBoard
    @State private var showingEditor = false
    @State private var showingGoalSheet = false

    var body: some View {
        ZStack {
            AppColor.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Board preview
                    boardCanvas
                        .onTapGesture { showingEditor = true }

                    // Quick actions
                    HStack(spacing: AppSpacing.sm) {
                        Button {
                            showingEditor = true
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button {
                            // TODO: export
                        } label: {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Goals section
                    goalsSection
                }
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .navigationTitle(board.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingEditor) {
            BoardEditorView(board: board)
        }
        .sheet(isPresented: $showingGoalSheet) {
            AddGoalSheet(board: board)
        }
    }

    private var boardCanvas: some View {
        GeometryReader { geo in
            let width = geo.size.width - AppSpacing.lg * 2
            let height = width / board.aspectRatio.value

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: board.backgroundColor),
                                     Color(hex: board.backgroundGradientEnd ?? board.backgroundColor)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Items
                ForEach(board.items.sorted(by: { $0.zIndex < $1.zIndex })) { item in
                    BoardItemView(item: item, canvasSize: CGSize(width: width, height: height))
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
            .frame(width: width, height: min(height, 500))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
            .frame(maxWidth: .infinity)
        }
        .frame(height: min((UIScreen.main.bounds.width - AppSpacing.lg * 2) / board.aspectRatio.value, 500))
        .padding(.horizontal, AppSpacing.lg)
    }

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
                        if goal.isCompleted {
                            goal.completedAt = Date()
                        } else {
                            goal.completedAt = nil
                        }
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
