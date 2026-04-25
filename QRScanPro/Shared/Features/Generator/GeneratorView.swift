import SwiftUI

struct GeneratorView: View {
    @EnvironmentObject private var store: AppStore
    @State private var content = "https://www.apple.com"
    @State private var correctionLevel: QRErrorCorrectionLevel = .medium
    @State private var outputSize = 512.0
    @State private var generatedImage: PlatformImage?
    @State private var errorMessage: String?

    private let generator = QRCodeGenerator()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                preview
                contentSection
                styleSection
                exportSection

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(AppTheme.warning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("生成二维码")
        .onAppear {
            regenerate()
        }
        .onChange(of: content) { _ in
            regenerate()
        }
        .onChange(of: correctionLevel) { _ in
            regenerate()
        }
        .onChange(of: outputSize) { _ in
            regenerate()
        }
    }

    private var preview: some View {
        VStack(spacing: 12) {
            if let generatedImage {
                PlatformImageView(image: generatedImage)
                    .frame(width: 220, height: 220)
                    .padding(18)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 220, height: 220)
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .cardBackground()
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("内容")
                .font(.headline)
                .foregroundColor(.white)

            TextEditor(text: $content)
                .frame(minHeight: 110)
                .hideScrollBackgroundWhenAvailable()
                .padding(8)
                .background(AppTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundColor(.white)
        }
        .padding(16)
        .cardBackground()
    }

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("样式参数")
                .font(.headline)
                .foregroundColor(.white)

            Picker("纠错级别", selection: $correctionLevel) {
                ForEach(QRErrorCorrectionLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text("输出尺寸：\(Int(outputSize)) px")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                Slider(value: $outputSize, in: 256...1024, step: 64)
            }
        }
        .padding(16)
        .cardBackground()
    }

    private var exportSection: some View {
        VStack(spacing: 10) {
            Button {
                regenerate()
            } label: {
                Label("生成二维码", systemImage: "qrcode")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if let generatedImage {
                ShareImageButton(image: generatedImage)
            }
        }
    }

    private func regenerate() {
        do {
            generatedImage = try generator.generate(
                content: content,
                correctionLevel: correctionLevel,
                size: outputSize
            )
            errorMessage = nil
            store.logger.info("二维码预览已刷新")
        } catch {
            generatedImage = nil
            errorMessage = error.localizedDescription
            store.logger.error(error.localizedDescription)
        }
    }
}
