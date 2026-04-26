import SwiftData
import SwiftUI

struct ScanResultView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let record: ScanRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                metaRow

                rawValueCard

                if let url = record.url {
                    urlCard(url)
                }

                actionGrid
            }
            .padding(Spacing.l)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("扫描结果")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var metaRow: some View {
        HStack(spacing: Spacing.s) {
            tag(record.kind.displayName, color: AppColor.accent)
            tag(record.source.displayName, color: AppColor.textSecondary)
            tag(record.createdAt.formatted(date: .abbreviated, time: .shortened), color: AppColor.textSecondary)
        }
        .font(AppFont.caption)
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .background(color.opacity(0.18))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    private var rawValueCard: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("原始内容")
                .font(AppFont.headline)
                .foregroundColor(AppColor.textPrimary)

            Text(record.value)
                .font(AppFont.mono)
                .foregroundColor(AppColor.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.l)
        .cardBackground()
    }

    @ViewBuilder
    private func urlCard(_ url: URL) -> some View {
        #if os(iOS)
        NavigationLink {
            InAppBrowserView(url: url)
        } label: {
            urlRow(url, accessory: "chevron.right")
        }
        .buttonStyle(.plain)
        #else
        Button {
            NSWorkspace.shared.open(url)
        } label: {
            urlRow(url, accessory: "arrow.up.right.square")
        }
        .buttonStyle(.plain)
        #endif
    }

    private func urlRow(_ url: URL, accessory: String) -> some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "safari")
                .foregroundColor(AppColor.accent)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text("检测到网页链接")
                    .font(AppFont.headline)
                    .foregroundColor(AppColor.textPrimary)
                Text(url.host ?? url.absoluteString)
                    .font(AppFont.footnote)
                    .foregroundColor(AppColor.textSecondary)
            }

            Spacer()

            Image(systemName: accessory)
                .foregroundColor(AppColor.textSecondary)
        }
        .padding(Spacing.l)
        .cardBackground()
    }

    private var actionGrid: some View {
        VStack(spacing: Spacing.m) {
            Button {
                ClipboardService.copy(record.value)
                DebugLogger.shared.info("复制扫描结果")
            } label: {
                Label("复制内容", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            #if os(iOS)
            if let url = record.url {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    Label("在浏览器中打开", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            #endif

            Button(role: .destructive) {
                modelContext.delete(record)
                try? modelContext.save()
                dismiss()
            } label: {
                Label("删除记录", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}
