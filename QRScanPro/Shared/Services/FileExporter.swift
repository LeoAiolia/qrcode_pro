import Foundation

#if os(macOS)
import AppKit
#endif

enum FileExporterError: LocalizedError {
    case userCancelled
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return L10n.t("已取消导出")
        case .writeFailed(let message):
            return String(format: L10n.t("写入失败：%@"), message)
        }
    }
}

/// 跨平台文件导出工具。CSV 序列化对外可用，UI 弹窗仅 macOS 实现。
enum FileExporter {
    /// 把识别结果序列化为 RFC 4180 兼容的 CSV。
    static func csv(from codes: [RecognizedCode], includeHeader: Bool = true) -> String {
        var lines: [String] = []
        if includeHeader {
            lines.append(L10n.t("码制,来源,内容"))
        }
        for code in codes {
            let row = [
                code.kind.displayName,
                L10n.t(code.source.displayName),
                code.value
            ].map(escapeCSVField).joined(separator: ",")
            lines.append(row)
        }
        return lines.joined(separator: "\r\n")
    }

    private static func escapeCSVField(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r")
        guard needsQuoting else { return field }
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    #if os(macOS)
    /// 弹 NSSavePanel 让用户选择保存位置；返回写入后的 URL。
    @MainActor
    static func saveCSV(
        _ csv: String,
        suggestedFilename: String = "QRScanPro-Recognized.csv"
    ) throws -> URL {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = suggestedFilename

        switch panel.runModal() {
        case .OK:
            guard let url = panel.url else {
                throw FileExporterError.userCancelled
            }
            do {
                try csv.write(to: url, atomically: true, encoding: .utf8)
                return url
            } catch {
                throw FileExporterError.writeFailed(error.localizedDescription)
            }
        case .cancel, .abort, .continue, .stop:
            throw FileExporterError.userCancelled
        default:
            throw FileExporterError.userCancelled
        }
    }
    #endif
}
