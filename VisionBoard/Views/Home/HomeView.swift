import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VisionBoard.updatedAt, order: .reverse) private var boards: [VisionBoard]
    @State private var showingTemplatePicker = false
    @State private var boardToEdit: VisionBoard?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bgPrimary.ignoresSafeArea()

                if boards.isEmpty {
                    emptyState
                } else {
                    boardList
                }
            }
            .navigationTitle("我的愿景板")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingTemplatePicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppColor.primary)
                    }
                }
            }
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerView { templateId in
                    let board = VisionBoard(templateId: templateId)
                    modelContext.insert(board)
                    boardToEdit = board
                }
            }
            .fullScreenCover(item: $boardToEdit) { board in
                BoardEditorView(board: board)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColor.primary, AppColor.warm],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: AppSpacing.xs) {
                Text("创建你的愿景板")
                    .font(AppFont.titleLarge)
                    .foregroundStyle(AppColor.textPrimary)

                Text("选一个喜欢的模板，填入你的梦想")
                    .font(AppFont.bodyMedium)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Button("选择模板开始") {
                showingTemplatePicker = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 60)

            Spacer()
            Spacer()
        }
        .padding()
    }

    private var boardList: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: AppSpacing.md),
                          GridItem(.flexible(), spacing: AppSpacing.md)],
                spacing: AppSpacing.md
            ) {
                ForEach(boards) { board in
                    NavigationLink(destination: BoardDetailView(board: board)) {
                        BoardCardView(board: board)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            boardToEdit = board
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            withAnimation { modelContext.delete(board) }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.xs)
        }
    }
}

// MARK: - Board Card (shows template-rendered preview)

struct BoardCardView: View {
    let board: VisionBoard

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // Render actual template preview
            TemplateBoardRenderer(board: board)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            Text(board.title)
                .font(AppFont.titleSmall)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)

            HStack(spacing: AppSpacing.xxs) {
                Text(board.template?.name ?? "")
                    .font(AppFont.caption2)
                Spacer()
                Text(board.updatedAt.formatted(.relative(presentation: .named)))
                    .font(AppFont.caption2)
            }
            .foregroundStyle(AppColor.textTertiary)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}
