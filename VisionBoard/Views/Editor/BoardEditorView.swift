import SwiftUI
import PhotosUI

struct BoardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var board: VisionBoard
    @State private var selectedItem: BoardItem?
    @State private var showingPhotoPicker = false
    @State private var showingTextInput = false
    @State private var showingStickerPicker = false
    @State private var photoSelection: PhotosPickerItem?
    @State private var dragOffset: CGSize = .zero
    @State private var activeItemId: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Canvas
                    canvasView
                        .padding(AppSpacing.md)

                    // Toolbar
                    editorToolbar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        board.updatedAt = Date()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .principal) {
                    Text(board.title)
                        .foregroundStyle(.white)
                        .font(AppFont.titleSmall)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .photosPicker(isPresented: $showingPhotoPicker, selection: $photoSelection, matching: .images)
            .onChange(of: photoSelection) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        addImageItem(data: data)
                    }
                }
            }
            .sheet(isPresented: $showingTextInput) {
                TextInputSheet { text, color in
                    addTextItem(text: text, color: color)
                }
            }
            .sheet(isPresented: $showingStickerPicker) {
                StickerPickerSheet { stickerName in
                    addStickerItem(name: stickerName)
                }
            }
        }
    }

    private var canvasView: some View {
        GeometryReader { geo in
            let size = canvasSize(in: geo.size)

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
                    .frame(width: size.width, height: size.height)

                // Items
                ForEach(board.items.sorted(by: { $0.zIndex < $1.zIndex })) { item in
                    itemView(item: item, canvasSize: size)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func canvasSize(in containerSize: CGSize) -> CGSize {
        let maxWidth = containerSize.width
        let maxHeight = containerSize.height
        let ratio = board.aspectRatio.value

        let width = min(maxWidth, maxHeight * ratio)
        let height = width / ratio
        return CGSize(width: width, height: min(height, maxHeight))
    }

    @ViewBuilder
    private func itemView(item: BoardItem, canvasSize: CGSize) -> some View {
        let isSelected = selectedItem?.id == item.id

        BoardItemView(item: item, canvasSize: canvasSize)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColor.primary, lineWidth: 2)
                        .frame(
                            width: canvasSize.width * item.width + 4,
                            height: canvasSize.height * item.height + 4
                        )
                        .position(
                            x: canvasSize.width * item.x,
                            y: canvasSize.height * item.y
                        )
                }
            }
            .onTapGesture {
                withAnimation(AppAnimation.fast) {
                    selectedItem = item
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        item.x = max(0.05, min(0.95, item.x + value.translation.width / canvasSize.width))
                        item.y = max(0.05, min(0.95, item.y + value.translation.height / canvasSize.height))
                    }
            )
    }

    private var editorToolbar: some View {
        VStack(spacing: 0) {
            // Selected item actions
            if selectedItem != nil {
                selectedItemActions
            }

            // Main tools
            HStack(spacing: AppSpacing.xxl) {
                toolButton(icon: "photo.fill", label: "图片") {
                    showingPhotoPicker = true
                }
                toolButton(icon: "textformat", label: "文字") {
                    showingTextInput = true
                }
                toolButton(icon: "star.fill", label: "贴纸") {
                    showingStickerPicker = true
                }
                toolButton(icon: "paintpalette.fill", label: "背景") {
                    cycleBackground()
                }
            }
            .padding(.vertical, AppSpacing.lg)
            .padding(.bottom, AppSpacing.md)
        }
        .background(.ultraThinMaterial)
    }

    private var selectedItemActions: some View {
        HStack(spacing: AppSpacing.xl) {
            Button {
                if let item = selectedItem {
                    item.zIndex += 1
                }
            } label: {
                Label("上移", systemImage: "square.2.layers.3d.top.filled")
                    .font(AppFont.caption1)
            }

            Button {
                if let item = selectedItem {
                    item.width = min(0.9, item.width * 1.1)
                    item.height = min(0.9, item.height * 1.1)
                }
            } label: {
                Label("放大", systemImage: "plus.magnifyingglass")
                    .font(AppFont.caption1)
            }

            Button {
                if let item = selectedItem {
                    item.width = max(0.05, item.width * 0.9)
                    item.height = max(0.05, item.height * 0.9)
                }
            } label: {
                Label("缩小", systemImage: "minus.magnifyingglass")
                    .font(AppFont.caption1)
            }

            Button(role: .destructive) {
                if let item = selectedItem {
                    board.items.removeAll { $0.id == item.id }
                    modelContext.delete(item)
                    selectedItem = nil
                }
            } label: {
                Label("删除", systemImage: "trash")
                    .font(AppFont.caption1)
            }
        }
        .foregroundStyle(.white)
        .padding(.vertical, AppSpacing.sm)
    }

    private func toolButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(AppFont.caption2)
            }
            .foregroundStyle(.white)
        }
    }

    // MARK: - Actions

    private func addImageItem(data: Data) {
        let item = BoardItem(itemType: .image, zIndex: board.items.count)
        item.imageData = data
        board.items.append(item)
    }

    private func addTextItem(text: String, color: String) {
        let item = BoardItem(itemType: .text, width: 0.6, height: 0.1, zIndex: board.items.count)
        item.text = text
        item.textColor = color
        item.fontSize = 24
        board.items.append(item)
    }

    private func addStickerItem(name: String) {
        let item = BoardItem(itemType: .sticker, width: 0.15, height: 0.15, zIndex: board.items.count)
        item.stickerName = name
        item.fontSize = 40
        item.textColor = "#C8A2C8"
        board.items.append(item)
    }

    private func cycleBackground() {
        let gradients: [(String, String)] = [
            ("#FDFBF9", "#E8D5E8"),
            ("#F5DDE0", "#E8D5E8"),
            ("#E8D5E8", "#93B7E3"),
            ("#A3D9C2", "#93B7E3"),
            ("#F7C59F", "#E8B5BC"),
            ("#2C2C2E", "#4A3A5C"),
        ]
        let current = gradients.firstIndex { $0.0 == board.backgroundColor } ?? -1
        let next = (current + 1) % gradients.count
        board.backgroundColor = gradients[next].0
        board.backgroundGradientEnd = gradients[next].1
    }
}

// MARK: - Text Input Sheet

struct TextInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var selectedColor = "#2C2C2E"
    var onAdd: (String, String) -> Void

    private let colors = ["#2C2C2E", "#FFFFFF", "#C8A2C8", "#E8B5BC",
                          "#A3D9C2", "#F7C59F", "#93B7E3", "#D87B7B"]

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                TextField("输入文字", text: $text, axis: .vertical)
                    .font(AppFont.titleLarge)
                    .foregroundStyle(Color(hex: selectedColor))
                    .padding()
                    .background(AppColor.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .lineLimit(1...5)

                HStack(spacing: AppSpacing.sm) {
                    ForEach(colors, id: \.self) { color in
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? AppColor.primary : .clear, lineWidth: 2)
                                    .padding(-2)
                            )
                            .onTapGesture { selectedColor = color }
                    }
                }

                Spacer()
            }
            .padding(AppSpacing.lg)
            .navigationTitle("添加文字")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        onAdd(text, selectedColor)
                        dismiss()
                    }
                    .disabled(text.isEmpty)
                    .fontWeight(.semibold)
                    .tint(AppColor.primary)
                }
            }
        }
    }
}

// MARK: - Sticker Picker

struct StickerPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSelect: (String) -> Void

    private let stickers = [
        "star.fill", "heart.fill", "sparkles", "moon.fill", "sun.max.fill",
        "flame.fill", "bolt.fill", "leaf.fill", "crown.fill", "trophy.fill",
        "gift.fill", "airplane", "car.fill", "house.fill", "building.2.fill",
        "graduationcap.fill", "book.fill", "pencil", "paintbrush.fill", "camera.fill",
        "music.note", "heart.text.square.fill", "figure.run", "dumbbell.fill",
        "cup.and.saucer.fill", "fork.knife", "cart.fill", "creditcard.fill",
        "dollarsign.circle.fill", "chart.line.uptrend.xyaxis",
        "person.2.fill", "hand.thumbsup.fill", "globe.americas.fill", "cloud.sun.fill",
        "rainbow", "butterfly.fill", "pawprint.fill", "hare.fill",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: AppSpacing.md) {
                    ForEach(stickers, id: \.self) { sticker in
                        Button {
                            onSelect(sticker)
                            dismiss()
                        } label: {
                            Image(systemName: sticker)
                                .font(.title2)
                                .foregroundStyle(AppColor.primary)
                                .frame(width: 50, height: 50)
                                .background(AppColor.bgSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("选择贴纸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}
