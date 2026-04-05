import SwiftUI

struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedId: String? = nil
    var onCreate: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Text("选择一个模板开始创作")
                            .font(AppFont.bodyMedium)
                            .foregroundStyle(AppColor.textSecondary)
                            .padding(.horizontal, AppSpacing.lg)

                        // Free templates
                        sectionHeader("免费模板")

                        LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                            ForEach(BuiltinTemplates.free) { template in
                                templateCard(template)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        // Pro templates
                        sectionHeader("PRO 模板")

                        LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                            ForEach(BuiltinTemplates.all.filter { $0.isPro }) { template in
                                templateCard(template)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, 100)
                    }
                    .padding(.top, AppSpacing.sm)
                }

                // Bottom CTA
                VStack {
                    Spacer()
                    if let selectedId {
                        Button {
                            onCreate(selectedId)
                            dismiss()
                        } label: {
                            Text("使用这个模板")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(AppColor.primary)
                                .clipShape(Capsule())
                                .shadow(color: AppColor.primary.opacity(0.3), radius: 16, x: 0, y: 6)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.lg)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(AppAnimation.springGentle, value: selectedId)
            }
            .navigationTitle("选择模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppFont.titleSmall)
            .foregroundStyle(AppColor.textPrimary)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
    }

    private func templateCard(_ template: BoardTemplate) -> some View {
        let isSelected = selectedId == template.id

        return Button {
            withAnimation(AppAnimation.springSnappy) {
                selectedId = template.id
            }
        } label: {
            VStack(spacing: AppSpacing.xs) {
                // Template preview
                TemplatePreviewView(template: template)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(isSelected ? AppColor.primary : .clear, lineWidth: 3)
                    )
                    .overlay(alignment: .topTrailing) {
                        if template.isPro && !StoreKitManager.shared.isPro {
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColor.warm)
                                .clipShape(Capsule())
                                .padding(8)
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(AppColor.primary)
                                .background(Circle().fill(.white))
                                .padding(8)
                        }
                    }

                Text(template.name)
                    .font(AppFont.bodySmall)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColor.textPrimary)

                Text(template.description)
                    .font(AppFont.caption2)
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Preview (shows layout with placeholder slots)

struct TemplatePreviewView: View {
    let template: BoardTemplate

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: template.previewGradient.0),
                             Color(hex: template.previewGradient.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Photo slot placeholders
                ForEach(template.slots) { slot in
                    RoundedRectangle(cornerRadius: slot.cornerRadius * (geo.size.width / 400))
                        .fill(.white.opacity(0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: slot.cornerRadius * (geo.size.width / 400))
                                .strokeBorder(.white.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        )
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: geo.size.width * 0.06))
                                .foregroundStyle(.white.opacity(0.5))
                        )
                        .frame(
                            width: geo.size.width * slot.width,
                            height: geo.size.height * slot.height
                        )
                        .position(
                            x: geo.size.width * (slot.x + slot.width / 2),
                            y: geo.size.height * (slot.y + slot.height / 2)
                        )
                }

                // Text slot placeholders
                ForEach(template.textSlots) { slot in
                    Text(slot.placeholder)
                        .font(.system(size: slot.fontSize * (geo.size.width / 400), weight: slot.fontWeight))
                        .foregroundStyle(Color(hex: slot.defaultColor).opacity(0.7))
                        .multilineTextAlignment(slot.alignment)
                        .frame(width: geo.size.width * slot.width)
                        .position(
                            x: geo.size.width * slot.x,
                            y: geo.size.height * slot.y
                        )
                }
            }
        }
    }
}
