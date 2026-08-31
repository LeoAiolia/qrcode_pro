import SwiftUI

struct DebugLogView: View {
    @ObservedObject private var logger = DebugLogger.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if logger.entries.isEmpty {
                Text("暂无日志")
                    .foregroundColor(AppColor.textSecondary)
                    .listRowBackground(AppColor.surface)
            } else {
                ForEach(logger.entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(LocalizedStringKey(entry.level.title))
                                .font(AppFont.caption.bold())
                                .foregroundColor(color(for: entry.level))

                            Spacer()

                            Text(entry.date.formatted(date: .omitted, time: .standard))
                                .font(AppFont.caption)
                                .foregroundColor(AppColor.textSecondary)
                        }

                        Text(entry.message)
                            .font(AppFont.mono)
                            .foregroundColor(AppColor.textPrimary)
                    }
                    .padding(.vertical, Spacing.xs)
                    .listRowBackground(AppColor.surface)
                }
            }
        }
        .hideScrollBackgroundWhenAvailable()
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("调试日志")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button("清空") {
                    logger.clear()
                }
            }
        }
    }

    private func color(for level: DebugLogLevel) -> Color {
        switch level {
        case .info:
            return AppColor.accent
        case .warning:
            return AppColor.warning
        case .error:
            return AppColor.danger
        }
    }
}
