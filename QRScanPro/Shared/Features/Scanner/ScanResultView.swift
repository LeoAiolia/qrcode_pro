import SwiftUI

/// M1 占位实现；M2 将重写为完整的扫描结果详情（含 InAppBrowser）。
struct ScanResultView: View {
    let record: ScanRecord

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(record.kind.displayName)
                .font(AppFont.caption)
                .foregroundColor(AppColor.accent)

            Text(record.value)
                .font(AppFont.mono)
                .foregroundColor(AppColor.textPrimary)
                .textSelection(.enabled)

            Spacer()
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("扫描结果")
    }
}
