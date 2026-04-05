import SwiftUI
import PhotosUI

struct BoardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var board: VisionBoard
    @State private var editingTextSlotId: Int?
    @State private var editingText = ""
    @State private var targetPhotoSlotId: Int = 0
    @State private var showingPhotoPicker = false
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
                        // The board canvas
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
            .photosPicker(isPresented: $showingPhotoPicker, selection: $photoSelection, matching: .images)
            .onChange(of: photoSelection) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        board.setPhoto(data: data, forSlot: targetPhotoSlotId)
                    }
                    photoSelection = nil
                }
            }
            .alert("编辑文字", isPresented: Binding(
                get: { editingTextSlotId != nil },
                set: { if !$0 { editingTextSlotId = nil } }
            )) {
                TextField("", text: $editingText)
                Button("确定") {
                    if let slotId = editingTextSlotId, !editingText.isEmpty {
                        board.setText(content: editingText, forSlot: slotId)
                    }
                    editingTextSlotId = nil
                }
                Button("取消", role: .cancel) { editingTextSlotId = nil }
            }
        }
    }

    // MARK: - Canvas — uses Canvas overlay approach for correct hit testing

    private var boardCanvas: some View {
        GeometryReader { geo in
            let side = geo.size.width

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
                .frame(width: side, height: side)
                .overlay {
                    // Slots rendered as overlays with geometry-based positioning
                    if let template = board.template {
                        slotsOverlay(template: template, side: side)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func slotsOverlay(template: BoardTemplate, side: CGFloat) -> some View {
        // Use a Canvas/GeometryReader approach where each slot is placed
        // using .alignmentGuide or padding to ensure correct hit testing
        GeometryReader { _ in
            // Photo slots
            ForEach(template.slots) { slot in
                Button {
                    targetPhotoSlotId = slot.id
                    showingPhotoPicker = true
                } label: {
                    photoSlotLabel(slot: slot, side: side)
                }
                .buttonStyle(.plain)
                .frame(width: side * slot.width, height: side * slot.height)
                .padding(.leading, side * slot.x)
                .padding(.top, side * slot.y)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            // Text slots
            ForEach(template.textSlots) { slot in
                Button {
                    editingText = board.textContent(forSlot: slot.id) ?? ""
                    editingTextSlotId = slot.id
                } label: {
                    textSlotLabel(slot: slot, side: side)
                }
                .buttonStyle(.plain)
                .frame(width: side * slot.width)
                .padding(.leading, side * (slot.x - slot.width / 2))
                .padding(.top, side * slot.y - slot.fontSize * (side / 400) / 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    // MARK: - Slot Labels

    private func photoSlotLabel(slot: TemplateSlot, side: CGFloat) -> some View {
        let scaledRadius = slot.cornerRadius * (side / 400)

        return ZStack {
            if let data = board.photoData(forSlot: slot.id),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: side * slot.width, height: side * slot.height)
                    .clipped()
            } else {
                Color.white.opacity(0.2)
                VStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: side * 0.05))
                    Text(slot.placeholder)
                        .font(.system(size: max(side * 0.028, 10)))
                }
                .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(width: side * slot.width, height: side * slot.height)
        .clipShape(RoundedRectangle(cornerRadius: scaledRadius))
        .overlay(
            RoundedRectangle(cornerRadius: scaledRadius)
                .strokeBorder(
                    board.photoData(forSlot: slot.id) != nil ? .clear : .white.opacity(0.3),
                    style: board.photoData(forSlot: slot.id) != nil
                        ? StrokeStyle()
                        : StrokeStyle(lineWidth: 1.5, dash: [8, 5])
                )
        )
    }

    private func textSlotLabel(slot: TemplateTextSlot, side: CGFloat) -> some View {
        let content = board.textContent(forSlot: slot.id)
        let displayText = content ?? slot.placeholder
        let isPlaceholder = content == nil
        let scaledFontSize = slot.fontSize * (side / 400)
        // Use adaptive color based on background brightness
        let textColor = board.adaptiveTextColor

        return Text(displayText)
            .font(.system(size: scaledFontSize, weight: slot.fontWeight))
            .foregroundStyle(
                Color(hex: textColor).opacity(isPlaceholder ? 0.45 : 1.0)
            )
            .shadow(color: .black.opacity(board.isBackgroundLight ? 0 : 0.3), radius: 2, x: 0, y: 1)
            .multilineTextAlignment(slot.alignment)
            .lineLimit(3)
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
}
