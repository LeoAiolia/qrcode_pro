#if os(macOS)
import Foundation

/// macOS 默认导出目录的 Security-Scoped Bookmark 编解码。
/// 使用方式：选目录后 `encode(_:)` → 写入 SettingsStore；导出前 `resolve(_:)` 拿 URL，配合
/// `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`。
enum ExportDirectoryBookmark {
    static func encode(_ url: URL) -> Data? {
        try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    static func resolve(_ data: Data) -> URL? {
        var isStale = false
        let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return url
    }
}
#endif
