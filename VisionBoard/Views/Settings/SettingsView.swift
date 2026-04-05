import SwiftUI
import StoreKit

struct SettingsView: View {
    @State private var showingPaywall = false
    @State private var store = StoreKitManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bgPrimary.ignoresSafeArea()

                List {
                    // Premium
                    if !store.isPro {
                        Section {
                            Button {
                                showingPaywall = true
                            } label: {
                                HStack(spacing: AppSpacing.md) {
                                    Image(systemName: "crown.fill")
                                        .font(.title2)
                                        .foregroundStyle(AppColor.warm)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("升级 PRO")
                                            .font(AppFont.titleSmall)
                                            .foregroundStyle(AppColor.textPrimary)
                                        Text("解锁无限愿景板、全部模板和更多功能")
                                            .font(AppFont.bodySmall)
                                            .foregroundStyle(AppColor.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(AppColor.textTertiary)
                                }
                                .padding(.vertical, AppSpacing.xs)
                            }
                        }
                    } else {
                        Section {
                            HStack(spacing: AppSpacing.md) {
                                Image(systemName: "crown.fill")
                                    .font(.title2)
                                    .foregroundStyle(AppColor.warm)
                                Text("PRO 会员")
                                    .font(AppFont.titleSmall)
                                    .foregroundStyle(AppColor.textPrimary)
                                Spacer()
                                Text("已激活")
                                    .font(AppFont.bodySmall)
                                    .foregroundStyle(AppColor.success)
                            }
                        }
                    }

                    Section("关于") {
                        HStack {
                            Label("版本", systemImage: "info.circle")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(AppColor.textTertiary)
                        }

                        Link(destination: URL(string: "https://wayneuconn.github.io/app-vision-board/privacy")!) {
                            Label("隐私政策", systemImage: "hand.raised.fill")
                        }

                        Link(destination: URL(string: "https://wayneuconn.github.io/app-vision-board/terms")!) {
                            Label("使用条款", systemImage: "doc.text.fill")
                        }

                        Button {
                            Task { await store.restorePurchases() }
                        } label: {
                            Label("恢复购买", systemImage: "arrow.clockwise")
                        }
                    }

                    Section {
                        Button {
                            let email = "wayneuconn@gmail.com"
                            if let url = URL(string: "mailto:\(email)?subject=愿景板反馈") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("反馈建议", systemImage: "envelope.fill")
                        }

                        Button {
                            if let scene = UIApplication.shared.connectedScenes.first(where: {
                                $0.activationState == .foregroundActive
                            }) as? UIWindowScene {
                                SKStoreReviewController.requestReview(in: scene)
                            }
                        } label: {
                            Label("给个好评", systemImage: "star.fill")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("设置")
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
}
