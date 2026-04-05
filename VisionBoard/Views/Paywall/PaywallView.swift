import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = StoreKitManager.shared
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [AppColor.bgPrimary, AppColor.primaryLight.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Hero
                        heroSection

                        // Features
                        featuresSection

                        // Plans
                        plansSection

                        // CTA
                        ctaButton

                        // Footer
                        footerSection
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxxl)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppColor.textTertiary)
                    }
                }
            }
        }
        .onAppear {
            // Default select yearly
            if let yearly = store.products.first(where: { $0.id == StoreKitManager.yearlyID }) {
                selectedProduct = yearly
            } else {
                selectedProduct = store.products.first
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColor.primary, AppColor.warm],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, AppSpacing.xxl)

            Text("解锁全部功能")
                .font(AppFont.displayMedium)
                .foregroundStyle(AppColor.textPrimary)

            Text("让你的愿景更清晰，目标更容易实现")
                .font(AppFont.bodyMedium)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: AppSpacing.sm) {
            featureRow(icon: "infinity", text: "无限愿景板")
            featureRow(icon: "rectangle.grid.2x2.fill", text: "全部精美模板")
            featureRow(icon: "square.text.square.fill", text: "200+ 贴纸素材")
            featureRow(icon: "widget.large", text: "全尺寸桌面小组件")
            featureRow(icon: "arrow.down.doc.fill", text: "无水印高清导出")
            featureRow(icon: "nosign", text: "无广告体验")
        }
        .padding(AppSpacing.md)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(AppColor.accent)
                .frame(width: 28)
            Text(text)
                .font(AppFont.bodyMedium)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundStyle(AppColor.accentDark)
        }
        .padding(.vertical, AppSpacing.xxs)
    }

    // MARK: - Plans

    private var plansSection: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(store.products) { product in
                planCard(product: product)
            }
        }
    }

    private func planCard(product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id
        let isYearly = product.id == StoreKitManager.yearlyID

        return Button {
            withAnimation(AppAnimation.standard) {
                selectedProduct = product
            }
        } label: {
            VStack(spacing: AppSpacing.xs) {
                if isYearly {
                    Text("最受欢迎")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColor.accent)
                        .clipShape(Capsule())
                } else {
                    Spacer().frame(height: 20)
                }

                Text(product.displayPrice)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? AppColor.textPrimary : AppColor.textSecondary)

                Text("/\(product.periodLabel)")
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.textSecondary)

                if let monthly = product.monthlyEquivalent {
                    Text(monthly)
                        .font(AppFont.caption2)
                        .foregroundStyle(AppColor.textTertiary)
                } else {
                    Spacer().frame(height: 14)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(isSelected ? AppColor.primaryLight.opacity(0.3) : AppColor.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(isSelected ? AppColor.primary : AppColor.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            Task { await purchase() }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(ctaText)
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppColor.primary)
            .clipShape(Capsule())
            .shadow(color: AppColor.primary.opacity(0.3), radius: 16, x: 0, y: 6)
        }
        .disabled(isPurchasing || selectedProduct == nil)
        .alert("购买失败", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("请稍后重试")
        }
    }

    private var ctaText: String {
        guard let product = selectedProduct else { return "选择方案" }
        if product.subscription != nil {
            return "免费试用 3 天，然后 \(product.displayPrice)/\(product.periodLabel)"
        }
        return "一次买断 \(product.displayPrice)"
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("随时取消 · 无风险试用")
                .font(AppFont.caption1)
                .foregroundStyle(AppColor.textTertiary)

            HStack(spacing: AppSpacing.md) {
                Button("恢复购买") {
                    Task { await store.restorePurchases() }
                }
                Text("·")
                Button("隐私政策") {}
                Text("·")
                Button("使用条款") {}
            }
            .font(AppFont.caption2)
            .foregroundStyle(AppColor.textTertiary)
        }
    }

    // MARK: - Purchase

    private func purchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        do {
            _ = try await store.purchase(product)
            if store.isPro {
                dismiss()
            }
        } catch {
            showError = true
        }
        isPurchasing = false
    }
}
