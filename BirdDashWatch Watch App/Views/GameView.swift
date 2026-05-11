import SwiftUI

struct GameView: View {
    @ObservedObject var engine: GameEngine
    let size: CGSize
    @State private var pulseScale: CGFloat = 1
    @State private var pulseOpacity: Double = 0

    var body: some View {
        ZStack(alignment: .top) {
            backgroundView

            ForEach(engine.obstacles) { obstacle in
                obstacleView(for: obstacle)
            }

            if engine.gameState != .idle {
                birdView
            }

            if engine.gameState == .playing {
                scoreBanner
            }

            scoreFlash

            Color.white
                .opacity(engine.crashFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .clipped()
        .task {
            while !Task.isCancelled {
                await MainActor.run {
                    engine.step()
                }

                try? await Task.sleep(for: .seconds(engine.tickInterval))
            }
        }
        .onChange(of: engine.scorePulse) { _, _ in
            pulseScale = 1.28
            pulseOpacity = 0.9

            withAnimation(.easeOut(duration: 0.24)) {
                pulseScale = 1
            }

            withAnimation(.easeOut(duration: 0.32)) {
                pulseOpacity = 0
            }
        }
    }

    private var backgroundView: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(red: 0.40, green: 0.76, blue: 0.98), Color(red: 0.15, green: 0.52, blue: 0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: size.width * 0.74)
                .blur(radius: 6)
                .offset(x: size.width * 0.18, y: -size.height * 0.28)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(width: size.width * 0.56, height: size.height * 0.12)
                .rotationEffect(.degrees(-12))
                .offset(x: -size.width * 0.16, y: -size.height * 0.18)

            VStack(spacing: 0) {
                Spacer()

                Rectangle()
                    .fill(Color(red: 0.29, green: 0.64, blue: 0.23))
                    .frame(height: 10)

                Rectangle()
                    .fill(Color(red: 0.56, green: 0.41, blue: 0.26))
                    .frame(height: 8)
            }
        }
    }

    private var birdView: some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: engine.bird.size.width, height: engine.bird.size.height)
            .overlay(alignment: .trailing) {
                Circle()
                    .fill(.white)
                    .frame(width: 5, height: 5)
                    .offset(x: -2)
            }
            .overlay(alignment: .bottomLeading) {
                Capsule()
                    .fill(Color.orange)
                    .frame(width: 8, height: 4)
                    .rotationEffect(.degrees(18))
                    .offset(x: 1, y: 3)
            }
            .shadow(color: .black.opacity(0.16), radius: 3, x: 0, y: 2)
            .rotationEffect(.degrees(birdAngle))
            .position(x: engine.bird.x, y: engine.bird.y)
    }

    private var birdAngle: Double {
        let normalized = max(-1, min(1, Double(engine.bird.velocity / 240)))
        return normalized * 24
    }

    private var scoreBanner: some View {
        VStack {
            Text("\(engine.score)")
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.24), Color.white.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.10), lineWidth: 0.8)
                }
                .scaleEffect(pulseScale)

            Spacer()
        }
        .padding(.top, 24)
    }

    private var scoreFlash: some View {
        Text("+1")
            .font(.headline.weight(.bold))
            .foregroundStyle(.yellow)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.16), in: Capsule())
            .opacity(pulseOpacity)
            .scaleEffect(0.92 + (pulseOpacity * 0.24))
            .offset(y: 26 - ((1 - pulseOpacity) * 14))
            .padding(.top, 8)
    }

    @ViewBuilder
    private func obstacleView(for obstacle: Obstacle) -> some View {
        let upper = obstacle.upperFrame(in: size)
        let lower = obstacle.lowerFrame(in: size)

        pipe(frame: upper, capAtBottom: true)
        pipe(frame: lower, capAtBottom: false)
    }

    private func pipe(frame: CGRect, capAtBottom: Bool) -> some View {
        ZStack(alignment: capAtBottom ? .bottom : .top) {
            RoundedRectangle(cornerRadius: 5)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.20, green: 0.70, blue: 0.29), Color(red: 0.14, green: 0.52, blue: 0.21)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 0.33, green: 0.82, blue: 0.35))
                .frame(width: frame.width + 8, height: 10)
                .offset(y: capAtBottom ? 0 : 0)
        }
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
    }
}
