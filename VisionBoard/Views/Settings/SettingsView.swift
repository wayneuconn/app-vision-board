import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.bgPrimary.ignoresSafeArea()

                List {
                    // Premium
                    Section {
                        Button {
                            // TODO: show paywall
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

                    // General
                    Section("通用") {
                        NavigationLink {
                            Text("通知设置")
                        } label: {
                            Label("提醒设置", systemImage: "bell.fill")
                        }

                        NavigationLink {
                            Text("外观设置")
                        } label: {
                            Label("外观", systemImage: "paintbrush.fill")
                        }
                    }

                    // About
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
                            // TODO: restore purchases
                        } label: {
                            Label("恢复购买", systemImage: "arrow.clockwise")
                        }
                    }

                    // Feedback
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
        }
    }
}

import StoreKit
