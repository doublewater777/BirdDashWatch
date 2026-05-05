import CoreGraphics
import Foundation

@MainActor
final class GameEngine: ObservableObject {
    @Published private(set) var gameState: GameState = .idle
    @Published private(set) var bird = Bird(x: 0, y: 0, velocity: 0, size: .zero)
    @Published private(set) var obstacles: [Obstacle] = []
    @Published private(set) var score = 0
    @Published private(set) var bestScore = 0
    @Published private(set) var isNewBest = false
    @Published private(set) var scorePulse = 0
    @Published private(set) var crashFlashOpacity: Double = 0

    private let scoreStore: ScoreStore
    private let audioManager: AudioManager

    private var playfieldSize: CGSize = .zero
    private var lastTick = Date()
    private var spawnedObstacleCount = 0
    private let initialObstacleOffset: CGFloat = 28
    private let easyObstacleCount = 3

    let tickInterval: TimeInterval = 1.0 / 30.0
    private let gravity: CGFloat = 650
    private let flapVelocity: CGFloat = -225
    private let obstacleSpeed: CGFloat = 68
    private let obstacleSpacing: CGFloat = 118
    private let obstacleWidth: CGFloat = 22
    private let minimumGapHeight: CGFloat = 68
    private let topPadding: CGFloat = 10
    private let bottomPadding: CGFloat = 10
    private let crashPauseDuration: UInt64 = 140_000_000

    init(scoreStore: ScoreStore = ScoreStore(), audioManager: AudioManager = AudioManager()) {
        self.scoreStore = scoreStore
        self.audioManager = audioManager
        self.bestScore = scoreStore.loadBestScore()
    }

    func configure(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        playfieldSize = size

        if gameState != .playing {
            bird = Bird.makeDefault(in: size)
        }
    }

    func flap() {
        guard playfieldSize != .zero else { return }

        if gameState != .playing {
            startGame()
        }

        bird.velocity = flapVelocity
        audioManager.playFlap()
    }

    func step() {
        guard gameState == .playing, playfieldSize != .zero else { return }

        let now = Date()
        let deltaTime = min(max(now.timeIntervalSince(lastTick), 0.008), 0.05)
        lastTick = now

        updateBird(deltaTime: deltaTime)
        updateObstacles(deltaTime: deltaTime)
        spawnObstacleIfNeeded()
        updateScoreIfNeeded()
        checkCollisions()
    }

    private func startGame() {
        bird = Bird.makeDefault(in: playfieldSize)
        obstacles = []
        score = 0
        scorePulse = 0
        crashFlashOpacity = 0
        isNewBest = false
        spawnedObstacleCount = 0
        gameState = .playing
        lastTick = Date()
        spawnObstacleIfNeeded(force: true)
    }

    private func updateBird(deltaTime: TimeInterval) {
        bird.velocity += gravity * CGFloat(deltaTime)
        bird.y += bird.velocity * CGFloat(deltaTime)
    }

    private func updateObstacles(deltaTime: TimeInterval) {
        for index in obstacles.indices {
            obstacles[index].x -= obstacleSpeed * CGFloat(deltaTime)
        }

        obstacles.removeAll { $0.x + $0.width < 0 }
    }

    private func spawnObstacleIfNeeded(force: Bool = false) {
        if force || obstacles.isEmpty {
            obstacles.append(makeObstacle(x: playfieldSize.width + initialObstacleOffset))
            return
        }

        guard let lastObstacle = obstacles.last else { return }

        if lastObstacle.x < playfieldSize.width - obstacleSpacing {
            obstacles.append(makeObstacle(x: playfieldSize.width + initialObstacleOffset))
        }
    }

    private func makeObstacle(x: CGFloat) -> Obstacle {
        let isEasyOpeningObstacle = spawnedObstacleCount < easyObstacleCount
        let gapHeight = obstacleGapHeight(isEasyOpeningObstacle: isEasyOpeningObstacle)
        let gapCenter = obstacleGapCenter(gapHeight: gapHeight, isEasyOpeningObstacle: isEasyOpeningObstacle)
        spawnedObstacleCount += 1

        return Obstacle(
            x: x,
            gapCenterY: gapCenter,
            gapHeight: gapHeight,
            width: obstacleWidth
        )
    }

    private func obstacleGapHeight(isEasyOpeningObstacle: Bool) -> CGFloat {
        let baseHeight = min(max(minimumGapHeight, playfieldSize.height * 0.42), playfieldSize.height * 0.56)
        let bonusHeight: CGFloat = isEasyOpeningObstacle ? 8 : 0
        return min(playfieldSize.height * 0.68, baseHeight + bonusHeight)
    }

    private func obstacleGapCenter(gapHeight: CGFloat, isEasyOpeningObstacle: Bool) -> CGFloat {
        let minGapCenter = topPadding + gapHeight / 2
        let maxGapCenter = playfieldSize.height - bottomPadding - gapHeight / 2
        let centerY = playfieldSize.height * 0.5

        guard isEasyOpeningObstacle else {
            return CGFloat.random(in: minGapCenter...maxGapCenter)
        }

        let openingRange = min(playfieldSize.height * 0.08, max(4, (maxGapCenter - minGapCenter) * 0.5))
        let easyMin = max(minGapCenter, centerY - openingRange)
        let easyMax = min(maxGapCenter, centerY + openingRange)

        return CGFloat.random(in: easyMin...easyMax)
    }

    private func updateScoreIfNeeded() {
        for index in obstacles.indices {
            if !obstacles[index].hasScored && obstacles[index].x + obstacles[index].width < bird.x {
                obstacles[index].hasScored = true
                score += 1
                scorePulse += 1
                audioManager.playScore()
            }
        }
    }

    private func checkCollisions() {
        if Collision.isOutOfBounds(bird: bird, in: playfieldSize) {
            triggerCrash()
            return
        }

        if obstacles.contains(where: { Collision.hits(bird: bird, obstacle: $0, in: playfieldSize) }) {
            triggerCrash()
        }
    }

    private func triggerCrash() {
        guard gameState == .playing else { return }

        gameState = .gameOver
        crashFlashOpacity = 0.9
        audioManager.playHit()

        if score > bestScore {
            bestScore = score
            isNewBest = true
            scoreStore.save(bestScore: score)
        } else {
            isNewBest = false
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: crashPauseDuration)
            crashFlashOpacity = 0
        }
    }
}
