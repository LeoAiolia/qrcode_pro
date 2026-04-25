import SwiftUI

struct DebugLogView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if store.logger.entries.isEmpty {
                Text("暂无日志")
                    .foregroundColor(AppTheme.textSecondary)
                    .listRowBackground(AppTheme.surface)
            } else {
                ForEach(store.logger.entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(entry.level.title)
                                .font(.caption.bold())
                                .foregroundColor(color(for: entry.level))

                            Spacer()

                            Text(entry.date.formatted(date: .omitted, time: .standard))
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        Text(entry.message)
                            .font(.footnote.monospaced())
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(AppTheme.surface)
                }
            }
        }
        .hideScrollBackgroundWhenAvailable()
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("调试日志")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button("清空") {
                    store.logger.clear()
                }
            }
        }
    }

    private func color(for level: DebugLogLevel) -> Color {
        switch level {
        case .info:
            return AppTheme.accent
        case .warning:
            return AppTheme.warning
        case .error:
            return AppTheme.danger
        }
    }
}
