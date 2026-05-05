import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var engine = GameEngine()
    private let screenSize = WKInterfaceDevice.current().screenBounds.size

    var body: some View {
        ZStack {
            GameView(engine: engine, size: screenSize)

            switch engine.gameState {
            case .idle:
                StartView(bestScore: engine.bestScore)

            case .playing:
                EmptyView()

            case .gameOver:
                GameOverView(score: engine.score, bestScore: engine.bestScore, isNewBest: engine.isNewBest)
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .contentShape(Rectangle())
        .ignoresSafeArea()
        .onTapGesture {
            engine.flap()
        }
        .onAppear {
            engine.configure(size: screenSize)

            let environment = ProcessInfo.processInfo.environment
            if let scenario = environment["BIRDDASH_SCREENSHOT_SCENARIO"], !scenario.isEmpty {
                engine.configureScreenshotScenario(scenario, size: screenSize)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
