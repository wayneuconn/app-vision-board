import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VisionBoard.updatedAt, order: .reverse) private var boards: [VisionBoard]
    @State private var showingNewBoard = false
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
                        createAndOpenBoard()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppColor.primary)
                    }
                }
            }
            .fullScreenCover(item: $boardToEdit) { board in
                BoardEditorView(board: board)
            }
        }
    }

    private func createAndOpenBoard() {
        let board = VisionBoard()
        modelContext.insert(board)
        boardToEdit = board
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(AppColor.primary.opacity(0.6))

            Text("开始创建你的愿景板")
                .font(AppFont.titleLarge)
                .foregroundStyle(AppColor.textPrimary)

            Text("把梦想可视化，让目标每天都看得见")
                .font(AppFont.bodyMedium)
                .foregroundStyle(AppColor.textSecondary)

            Button("创建第一个愿景板") {
                createAndOpenBoard()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, AppSpacing.xxxl)
            .padding(.top, AppSpacing.sm)
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
                            modelContext.delete(board)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
        }
    }
}

// MARK: - Board Card

struct BoardCardView: View {
    let board: VisionBoard

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // Preview — always square in list
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: board.backgroundColor),
                                 Color(hex: board.backgroundGradientEnd ?? board.backgroundColor)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if board.items.isEmpty {
                        VStack(spacing: 4) {
                            Image(systemName: board.category.icon)
                                .font(.title2)
                            Text(board.category.rawValue)
                                .font(AppFont.caption1)
                        }
                        .foregroundStyle(.white.opacity(0.8))
                    } else {
                        boardPreview
                    }
                }

            Text(board.title)
                .font(AppFont.titleSmall)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)

            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: board.category.icon)
                    .font(.caption)
                Text(board.category.rawValue)
                    .font(AppFont.caption1)
                Spacer()
                Text(board.updatedAt.formatted(.relative(presentation: .named)))
                    .font(AppFont.caption2)
            }
            .foregroundStyle(AppColor.textTertiary)
        }
        .appCard()
    }

    @ViewBuilder
    private var boardPreview: some View {
        let imageItems = board.items.filter { $0.itemType == .image && $0.imageData != nil }.prefix(4)
        if !imageItems.isEmpty {
            GeometryReader { geo in
                ForEach(Array(imageItems.enumerated()), id: \.element.id) { _, item in
                    if let data = item.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: geo.size.width * item.width,
                                height: geo.size.height * item.height
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .position(
                                x: geo.size.width * item.x,
                                y: geo.size.height * item.y
                            )
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        }
    }
}
