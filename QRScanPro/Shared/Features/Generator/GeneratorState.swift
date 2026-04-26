import CoreGraphics
import Foundation
import Observation

/// 生成器视图状态；参数变更触发 300ms 防抖，重新构建 BitMatrix + CGImage + PlatformImage。
@MainActor
@Observable
final class GeneratorState {
    var content: String
    var config: GenerateConfig

    private(set) var image: PlatformImage?
    private(set) var bitMatrix: QRCodeBitMatrix?
    private(set) var cgImage: CGImage?
    private(set) var error: String?
    private(set) var isGenerating: Bool = false

    private var debounceTask: Task<Void, Never>?
    private let generator = QRCodeGenerator()

    init(initialContent: String? = nil, initialConfig: GenerateConfig? = nil) {
        self.content = initialContent ?? "https://www.apple.com"
        self.config = initialConfig ?? .default
    }

    // MARK: - Derived

    var contrastRatio: Double {
        ContrastChecker.ratio(
            foregroundHex: config.foregroundHex,
            backgroundHex: config.backgroundHex
        )
    }

    var hasContrastWarning: Bool { contrastRatio < 3.0 }
    var hasLogoRatioWarning: Bool { config.logoRatio > 0.30 }

    // MARK: - Regenerate

    func scheduleRegenerate() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            await self?.regenerate()
        }
    }

    func regenerateImmediately() async {
        debounceTask?.cancel()
        await regenerate()
    }

    private func regenerate() async {
        isGenerating = true
        defer { isGenerating = false }

        do {
            let result = try generator.render(content: content, config: config)
            self.image = result.image
            self.bitMatrix = result.matrix
            self.cgImage = result.cgImage
            self.error = nil
        } catch {
            self.image = nil
            self.bitMatrix = nil
            self.cgImage = nil
            self.error = error.localizedDescription
        }
    }
}
