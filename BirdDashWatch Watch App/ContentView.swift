import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var engine = GameEngine()
    private let screenSize = WKInterfaceDevice.current().screenBounds.size
    @State private var crownAccumulator: CGFloat = 0

    var body: some View {
        ZStack {
            GameView(engine: engine, size: screenSize)

            switch engine.gameState {
            case .idle:
                StartView(bestScore: engine.bestScore, dailyBest: engine.dailyBestScore, onDailyChallenge: {
                    engine.startDailyChallenge()
                    engine.flap()
                }, onNormalGame: {
                    engine.startNormalGame()
                    engine.flap()
                })

            case .playing:
                if engine.isDailyChallenge {
                    dailyChallengeHUD
                }

            case .gameOver:
                GameOverView(
                    score: engine.score,
                    bestScore: engine.bestScore,
                    isNewBest: engine.isNewBest,
                    endReason: engine.gameEndReason,
                    isDailyChallenge: engine.isDailyChallenge,
                    onRetry: {
                        engine.retryCurrentMode()
                    },
                    onBackHome: {
                        engine.returnToHome()
                    }
                )
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .contentShape(Rectangle())
        .ignoresSafeArea()
        .onTapGesture {
            guard engine.gameState != .idle else { return }
            engine.flap()
        }
        .onAppear {
            engine.configure(size: screenSize)

            let environment = ProcessInfo.processInfo.environment
            if let scenario = environment["BIRDDASH_SCREENSHOT_SCENARIO"], !scenario.isEmpty {
                engine.configureScreenshotScenario(scenario, size: screenSize)
            }
            if let autoplay = environment["BIRDDASH_AUTOPLAY"], !autoplay.isEmpty {
                engine.setAutoplayMode(autoplay == "daily" ? .daily : .normal)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    engine.beginAutoplayRunIfNeeded()
                }
            }
        }
        .overlay(crownGesture)
    }

    private var dailyChallengeHUD: some View {
        VStack {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 10, weight: .bold))
                Text(String(format: "%.0fs", max(0, engine.sessionTimeRemaining)))
                    .font(.caption2.monospacedDigit().weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.42), Color.blue.opacity(0.30)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.14), lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.16), radius: 2, x: 0, y: 1)
            .padding(.top, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.leading, 6)
        .allowsHitTesting(false)
    }

    private var crownGesture: some View {
        Color.clear
            .focusable()
            .digitalCrownRotation(
                $crownAccumulator,
                from: -100,
                through: 100,
                by: 0.5,
                sensitivity: .medium,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .onChange(of: crownAccumulator) { _, newValue in
                engine.adjustCrown(delta: newValue)
                crownAccumulator = 0
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}