#if os(iOS)
import SwiftUI

struct SplashView: View {
    @Binding var isVisible: Bool

    var body: some View {
        ZStack {
            splashBackground
            content
        }
        .ignoresSafeArea()
        .onAppear {
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation(.easeOut(duration: 0.35)) {
                    isVisible = false
                }
            }
        }
    }

    // MARK: - Background

    private var splashBackground: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            // Blue glow — top leading
            RadialGradient(
                colors: [Color(red: 0.039, green: 0.518, blue: 1.0).opacity(0.40), .clear],
                center: UnitPoint(x: 0.30, y: 0.20),
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()
            // Indigo glow — bottom trailing
            RadialGradient(
                colors: [Color(red: 0.369, green: 0.361, blue: 0.902).opacity(0.30), .clear],
                center: UnitPoint(x: 0.70, y: 0.72),
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {
            Spacer()
            appIcon
                .padding(.bottom, 20)
            Text("QRScan Pro")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .tracking(-0.4)
            Text("扫码 · 识别 · 生成")
                .font(.caption)
                .foregroundColor(.white.opacity(0.60))
                .padding(.top, 6)
            Spacer()
            Text("由 Vision 框架驱动")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.35))
                .tracking(1.2)
                .textCase(.uppercase)
                .padding(.bottom, 48)
        }
    }

    // MARK: - App icon

    private var appIcon: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color(red: 0.102, green: 0.561, blue: 1.000),
                    Color(red: 0.039, green: 0.518, blue: 1.000),
                    Color(red: 0.000, green: 0.400, blue: 0.800)
                ],
                center: UnitPoint(x: 0.30, y: 0.30),
                startRadius: 0,
                endRadius: 72
            )
            QRGlyphShape()
                .frame(width: 96 * 0.66, height: 96 * 0.66)
                .foregroundColor(.white)
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color(red: 0.039, green: 0.518, blue: 1.0).opacity(0.50), radius: 24, y: 8)
    }
}

// MARK: - QR brand glyph (matches qr-glyph.svg)

private struct QRGlyphShape: View {
    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 100

            func rr(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
                Path(roundedRect: CGRect(x: x * s, y: y * s, width: w * s, height: h * s),
                     cornerRadius: r * s, style: .continuous)
            }

            // Three finder patterns (outer ring + center dot via even-odd mask)
            let outers:  [(CGFloat, CGFloat)] = [(6, 6), (64, 6), (6, 64)]
            let cuts:    [(CGFloat, CGFloat)] = [(11, 11), (69, 11), (11, 69)]
            let centers: [(CGFloat, CGFloat)] = [(15, 15), (73, 15), (15, 73)]

            for i in 0..<3 {
                var ring = rr(outers[i].0,  outers[i].1,  30, 30, 5)
                ring.addPath(rr(cuts[i].0,   cuts[i].1,   20, 20, 3))
                ctx.fill(ring, with: .foreground, style: FillStyle(eoFill: true))
                ctx.fill(rr(centers[i].0, centers[i].1, 12, 12, 2), with: .foreground)
            }

            // Accent block — bottom-right
            ctx.fill(rr(68, 68, 22, 22, 4), with: .foreground)
        }
    }
}
#endif
