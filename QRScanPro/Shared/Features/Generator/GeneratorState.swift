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
    private var generationID = UUID()

    init(initialContent: String? = nil, initialConfig: GenerateConfig? = nil) {
        self.content = initialContent ?? ""
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
            await self?.regenerate(priority: .userInitiated)
        }
    }

    func regenerateImmediately(priority: TaskPriority = .userInitiated) async {
        debounceTask?.cancel()
        await regenerate(priority: priority)
    }

    private func regenerate(priority: TaskPriority) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            image = nil
            bitMatrix = nil
            cgImage = nil
            error = nil
            isGenerating = false
            return
        }

        let currentID = UUID()
        generationID = currentID
        let content = content
        let config = config

        isGenerating = true

        do {
            let result = try await Task.detached(priority: priority) {
                let generator = QRCodeGenerator()
                let output = try generator.renderCGImage(content: content, config: config)
                try Task.checkCancellation()
                return output
            }.value

            guard generationID == currentID else { return }
            self.image = PlatformImage.from(cgImage: result.cgImage)
            self.bitMatrix = result.matrix
            self.cgImage = result.cgImage
            self.error = nil
        } catch is CancellationError {
            guard generationID == currentID else { return }
        } catch {
            guard generationID == currentID else { return }
            self.image = nil
            self.bitMatrix = nil
            self.cgImage = nil
            self.error = error.localizedDescription
        }

        if generationID == currentID {
            isGenerating = false
        }
    }
}
