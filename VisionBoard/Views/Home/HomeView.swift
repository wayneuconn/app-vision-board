import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VisionBoard.updatedAt, order: .reverse) private var boards: [VisionBoard]
    @State private var showingNewBoard = false

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
                        showingNewBoard = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppColor.primary)
                    }
                }
            }
            .sheet(isPresented: $showingNewBoard) {
                NewBoardSheet { board in
                    modelContext.insert(board)
                }
            }
        }
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
                showingNewBoard = true
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
            // Preview
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

            // Title & meta
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
        // Show thumbnails of images on the board
        let imageItems = board.items.filter { $0.itemType == .image && $0.imageData != nil }.prefix(4)
        if !imageItems.isEmpty {
            GeometryReader { geo in
                ForEach(Array(imageItems.enumerated()), id: \.element.id) { index, item in
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

// MARK: - New Board Sheet

struct NewBoardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var category: BoardCategory = .general
    @State private var aspectRatio: AspectRatio = .square
    var onCreate: (VisionBoard) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Title
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("愿景板名称")
                                .font(AppFont.titleSmall)
                                .foregroundStyle(AppColor.textPrimary)
                            TextField("给你的愿景板起个名字", text: $title)
                                .font(AppFont.bodyLarge)
                                .padding(AppSpacing.sm)
                                .background(AppColor.bgSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        }

                        // Category
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("分类")
                                .font(AppFont.titleSmall)
                                .foregroundStyle(AppColor.textPrimary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AppSpacing.xs) {
                                ForEach(BoardCategory.allCases, id: \.self) { cat in
                                    Button {
                                        category = cat
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: cat.icon)
                                                .font(.title3)
                                            Text(cat.rawValue)
                                                .font(AppFont.caption1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppSpacing.sm)
                                        .background(
                                            category == cat ? cat.color.opacity(0.15) : AppColor.bgSecondary
                                        )
                                        .foregroundStyle(
                                            category == cat ? cat.color : AppColor.textSecondary
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                                .stroke(category == cat ? cat.color : .clear, lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Aspect ratio
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("比例")
                                .font(AppFont.titleSmall)
                                .foregroundStyle(AppColor.textPrimary)
                            HStack(spacing: AppSpacing.sm) {
                                ForEach(AspectRatio.allCases, id: \.self) { ratio in
                                    Button {
                                        aspectRatio = ratio
                                    } label: {
                                        VStack(spacing: 4) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(
                                                    aspectRatio == ratio ? AppColor.primary : AppColor.textTertiary,
                                                    lineWidth: 1.5
                                                )
                                                .aspectRatio(ratio.value, contentMode: .fit)
                                                .frame(height: 40)
                                            Text(ratio.displayName)
                                                .font(AppFont.caption1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(AppSpacing.sm)
                                        .background(
                                            aspectRatio == ratio ? AppColor.primaryLight.opacity(0.3) : AppColor.bgSecondary
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.lg)
                }
            }
            .navigationTitle("新建愿景板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        let board = VisionBoard(
                            title: title.isEmpty ? "我的愿景板" : title,
                            category: category,
                            aspectRatio: aspectRatio
                        )
                        onCreate(board)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(AppColor.primary)
                }
            }
        }
    }
}
