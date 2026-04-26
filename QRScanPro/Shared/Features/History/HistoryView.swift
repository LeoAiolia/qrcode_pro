import SwiftUI

/// M1 占位实现；M4 将基于 SwiftData @Query 重写：分段、筛选、批量删除。
struct HistoryView: View {
    var body: some View {
        PlaceholderScreen(
            systemImage: "clock",
            title: "历史",
            subtitle: "M4 将上线扫码 / 生成分段、筛选、缩略图与批量删除。"
        )
        .navigationTitle("历史记录")
    }
}
