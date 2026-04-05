import SwiftUI
import PhotosUI

struct BoardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var board: VisionBoard
    @State private var editingTextSlotId: Int?
    @State private var editingText = ""
    @State private var activePhotoSlotId: Int?
    @State private var photoSelection: PhotosPickerItem?

    private let gradients: [(String, String, String)] = [
        ("#FDFBF9", "#E8D5E8", "浅紫"),
        ("#F5DDE0", "#E8D5E8", "玫粉"),
        ("#E8D5E8", "#93B7E3", "紫蓝"),
        ("#A3D9C2", "#93B7E3", "蓝绿"),
        ("#F7C59F", "#E8B5BC", "暖橘"),
        ("#2C2C2E", "#4A3A5C", "暗夜"),
        ("#F7F3EF", "#FDFBF9", "纯净"),
        ("#E8B5BC", "#F7C59F", "落日"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bgSecondary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        boardCanvas
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.top, AppSpacing.sm)

                        colorPicker
                            .padding(.horizontal, AppSpacing.lg)

                        Text("点击照片区域添加图片，点击文字直接编辑")
                            .font(AppFont.caption1)
                            .foregroundStyle(AppColor.textTertiary)
                            .padding(.bottom, AppSpacing.xl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(AppColor.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text(board.title)
                        .font(AppFont.titleSmall)
                        .foregroundStyle(AppColor.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        board.updatedAt = Date()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.primary)
                }
            }
            .photosPicker(
                isPresented: Binding(
                    get: { activePhotoSlotId != nil },
                    set: { if !$0 { activePhotoSlotId = nil } }
                ),
                selection: $photoSelection,
                matching: .images
            )
            .onChange(of: photoSelection) { _, newItem in
                Task {
                    if let slotId = activePhotoSlotId,
                       let data = try? await newItem?.loadTransferable(type: Data.self) {
                        board.setPhoto(data: data, forSlot: slotId)
                    }
                    activePhotoSlotId = nil
                    photoSelection = nil
                }
            }
            .alert("编辑文字", isPresented: Binding(
                get: { editingTextSlotId != nil },
                set: { if !$0 { saveText(); editingTextSlotId = nil } }
            )) {
                TextField("", text: $editingText)
                Button("确定") { saveText(); editingTextSlotId = nil }
                Button("取消", role: .cancel) { editingTextSlotId = nil }
            }
        }
    }

    // MARK: - Canvas (uses overlay-based layout instead of .position())

    private var boardCanvas: some View {
        GeometryReader { geo in
            let side = geo.size.width

            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: board.backgroundColor),
                                     Color(hex: board.backgroundGradientEnd ?? board.backgroundColor)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if let template = board.template {
                    // Photo slots — using offset + frame instead of .position()
                    ForEach(template.slots) { slot in
                        photoSlotButton(slot: slot, canvasSize: side)
                            .frame(
                                width: side * slot.width,
                                height: side * slot.height
                            )
                            .offset(
                                x: side * slot.x,
                                y: side * slot.y
                            )
                    }

                    // Text slots
                    ForEach(template.textSlots) { slot in
                        textSlotButton(slot: slot, canvasSize: side)
                            .frame(width: side * slot.width)
                            .offset(
                                x: side * (slot.x - slot.width / 2),
                                y: side * slot.y
                            )
                    }
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Photo Slot Button

    private func photoSlotButton(slot: TemplateSlot, canvasSize: CGFloat) -> some View {
        let hasPhoto = board.photoData(forSlot: slot.id) != nil
        let scaledRadius = slot.cornerRadius * (canvasSize / 400)

        return Button {
            activePhotoSlotId = slot.id
        } label: {
            ZStack {
                if let data = board.photoData(forSlot: slot.id),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.white.opacity(0.2)
                    VStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: canvasSize * 0.05))
                        Text(slot.placeholder)
                            .font(.system(size: max(canvasSize * 0.028, 10)))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: scaledRadius))
            .overlay(
                RoundedRectangle(cornerRadius: scaledRadius)
                    .strokeBorder(
                        hasPhoto ? .clear : .white.opacity(0.3),
                        style: hasPhoto ? StrokeStyle() : StrokeStyle(lineWidth: 1.5, dash: [8, 5])
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Text Slot Button

    private func textSlotButton(slot: TemplateTextSlot, canvasSize: CGFloat) -> some View {
        let content = board.textContent(forSlot: slot.id)
        let displayText = content ?? slot.placeholder
        let isPlaceholder = content == nil
        let scaledFontSize = slot.fontSize * (canvasSize / 400)

        return Button {
            editingText = content ?? ""
            editingTextSlotId = slot.id
        } label: {
            Text(displayText)
                .font(.system(size: scaledFontSize, weight: slot.fontWeight))
                .foregroundStyle(
                    Color(hex: slot.defaultColor)
                        .opacity(isPlaceholder ? 0.5 : 1.0)
                )
                .multilineTextAlignment(slot.alignment)
                .lineLimit(3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Color Picker

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("背景配色")
                .font(AppFont.caption1)
                .foregroundStyle(AppColor.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(gradients, id: \.2) { start, end, name in
                        let isSelected = board.backgroundColor == start
                        Button {
                            withAnimation(AppAnimation.standard) {
                                board.backgroundColor = start
                                board.backgroundGradientEnd = end
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: start), Color(hex: end)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle().stroke(isSelected ? AppColor.primary : .clear, lineWidth: 2.5)
                                            .padding(-2)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                                Text(name)
                                    .font(.system(size: 10))
                                    .foregroundStyle(isSelected ? AppColor.primary : AppColor.textTertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func saveText() {
        if let slotId = editingTextSlotId, !editingText.isEmpty {
            board.setText(content: editingText, forSlot: slotId)
        }
    }
}
