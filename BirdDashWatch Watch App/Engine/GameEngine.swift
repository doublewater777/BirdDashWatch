import CoreGraphics
import Foundation
import WatchKit

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

@MainActor
final class GameEngine: ObservableObject {
    @Published private(set) var gameState: GameState = .idle
    @Published private(set) var bird = Bird(x: 0, y: 0, velocity: 0, size: .zero)
    @Published private(set) var obstacles: [Obstacle] = []
    @Published private(set) var score = 0
    @Published private(set) var bestScore = 0
    @Published private(set) var dailyBestScore = 0
    @Published private(set) var isNewBest = false
    @Published private(set) var gameEndReason: GameEndReason = .crash
    @Published private(set) var scorePulse = 0
    @Published private(set) var crashFlashOpacity: Double = 0
    @Published private(set) var isPreviewingScreenshot = false
    @Published private(set) var isDailyChallenge = false
    @Published private(set) var sessionTimeRemaining: Double = 0

    private let scoreStore: ScoreStore
    private let audioManager: AudioManager

    private var playfieldSize: CGSize = .zero
    private var lastTick = Date()
    private var spawnedObstacleCount = 0
    private var autoplayMode: AutoPlayMode = .off
    private let initialObstacleOffset: CGFloat = 28
    private let easyObstacleCount = 3

    private var seededRNG: SeededRandomNumberGenerator?
    private var crownImpulse: CGFloat = 0
    private let crownSensitivity: CGFloat = 0.4
    private let crownUpwardForce: CGFloat = -120
    private let crownDownwardForce: CGFloat = 80
    private let crownDamping: CGFloat = 0.85

    private let hapticProximityThreshold: CGFloat = 30
    private var proximityHapticTriggered: Set<UUID> = []

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
    private let rhythmSessionDuration: Double = 60.0

    var dailyChallengeDuration: Double {
        rhythmSessionDuration
    }

    private var currentGravity: CGFloat {
        isDailyChallenge ? 610 : gravity
    }

    private var currentFlapVelocity: CGFloat {
        isDailyChallenge ? -215 : flapVelocity
    }

    private var currentObstacleSpeed: CGFloat {
        isDailyChallenge ? 60 : obstacleSpeed
    }

    private var currentObstacleSpacing: CGFloat {
        isDailyChallenge ? 126 : obstacleSpacing
    }

    private var currentMinimumGapHeight: CGFloat {
        isDailyChallenge ? 74 : minimumGapHeight
    }

    private var currentEasyObstacleCount: Int {
        isDailyChallenge ? 5 : easyObstacleCount
    }

    enum AutoPlayMode {
        case off
        case normal
        case daily
    }

    init(scoreStore: ScoreStore = ScoreStore(), audioManager: AudioManager = AudioManager()) {
        self.scoreStore = scoreStore
        self.audioManager = audioManager
        self.bestScore = scoreStore.loadBestScore()
        self.dailyBestScore = scoreStore.loadDailyBest()
    }

    func startDailyChallenge() {
        isDailyChallenge = true
        sessionTimeRemaining = rhythmSessionDuration
        let seed = scoreStore.dailySeed()
        seededRNG = SeededRandomNumberGenerator(seed: UInt64(bitPattern: Int64(seed)))
        configure(size: playfieldSize)
    }

    func startNormalGame() {
        isDailyChallenge = false
        seededRNG = nil
        sessionTimeRemaining = 0
        configure(size: playfieldSize)
    }

    func retryCurrentMode() {
        guard playfieldSize != .zero else { return }

        if isDailyChallenge {
            let seed = scoreStore.dailySeed()
            seededRNG = SeededRandomNumberGenerator(seed: UInt64(bitPattern: Int64(seed)))
            sessionTimeRemaining = rhythmSessionDuration
        } else {
            seededRNG = nil
            sessionTimeRemaining = 0
        }

        startGame()
    }

    func returnToHome() {
        obstacles = []
        score = 0
        scorePulse = 0
        crashFlashOpacity = 0
        isNewBest = false
        gameEndReason = .crash
        isDailyChallenge = false
        sessionTimeRemaining = 0
        seededRNG = nil
        spawnedObstacleCount = 0
        crownImpulse = 0
        proximityHapticTriggered = []
        gameState = .idle
        lastTick = Date()

        if playfieldSize != .zero {
            bird = Bird.makeDefault(in: playfieldSize)
        }
    }

    func adjustCrown(delta: CGFloat) {
        guard gameState == .playing else { return }
        crownImpulse = delta * crownSensitivity
    }

    func setAutoplayMode(_ mode: AutoPlayMode) {
        autoplayMode = mode
    }

    func beginAutoplayRunIfNeeded() {
        guard gameState == .idle else { return }

        switch autoplayMode {
        case .off:
            return
        case .normal:
            startNormalGame()
            flap()
        case .daily:
            startDailyChallenge()
            flap()
        }
    }

    func configure(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        playfieldSize = size

        if gameState != .playing, !isPreviewingScreenshot {
            bird = Bird.makeDefault(in: size)
        }
    }

    func flap() {
        guard playfieldSize != .zero, !isPreviewingScreenshot else { return }

        if gameState != .playing {
            if isDailyChallenge && seededRNG == nil {
                startDailyChallenge()
            } else if !isDailyChallenge {
                startNormalGame()
            }
            startGame()
        }

        bird.velocity = currentFlapVelocity
        audioManager.playFlap()
    }

    func step() {
        guard gameState == .playing, playfieldSize != .zero, !isPreviewingScreenshot else { return }

        let now = Date()
        let deltaTime = min(max(now.timeIntervalSince(lastTick), 0.008), 0.05)
        lastTick = now

        performAutoplayIfNeeded()

        if isDailyChallenge {
            sessionTimeRemaining -= deltaTime
            if sessionTimeRemaining <= 0 {
                triggerSessionComplete()
                return
            }
        }

        updateBird(deltaTime: deltaTime)
        updateObstacles(deltaTime: deltaTime)
        spawnObstacleIfNeeded()
        updateScoreIfNeeded()
        checkCollisions()
        updateHapticFeedback()
    }

    func configureScreenshotScenario(_ name: String, size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        playfieldSize = size
        isPreviewingScreenshot = true
        bestScore = max(bestScore, 33)
        scorePulse = 0
        crashFlashOpacity = 0
        isNewBest = false
        isDailyChallenge = false
        sessionTimeRemaining = 0
        gameEndReason = .crash

        switch name.lowercased() {
        case "start":
            gameState = .idle
            score = 0
            bird = Bird.makeDefault(in: size)
            obstacles = []

        case "gameplay":
            gameState = .playing
            score = 6
            bird = Bird(
                x: size.width * 0.34,
                y: size.height * 0.45,
                velocity: -36,
                size: CGSize(width: 18, height: 18)
            )
            obstacles = [
                Obstacle(
                    x: size.width * 0.60,
                    gapCenterY: size.height * 0.43,
                    gapHeight: 92,
                    width: obstacleWidth,
                    hasScored: false
                ),
                Obstacle(
                    x: size.width * 0.96,
                    gapCenterY: size.height * 0.58,
                    gapHeight: 84,
                    width: obstacleWidth,
                    hasScored: false
                )
            ]

        case "dailygameplay":
            gameState = .playing
            isDailyChallenge = true
            sessionTimeRemaining = 41
            score = 9
            bird = Bird(
                x: size.width * 0.34,
                y: size.height * 0.48,
                velocity: -28,
                size: CGSize(width: 18, height: 18)
            )
            obstacles = [
                Obstacle(
                    x: size.width * 0.55,
                    gapCenterY: size.height * 0.47,
                    gapHeight: 92,
                    width: obstacleWidth,
                    hasScored: true
                ),
                Obstacle(
                    x: size.width * 0.90,
                    gapCenterY: size.height * 0.58,
                    gapHeight: 84,
                    width: obstacleWidth,
                    hasScored: false
                )
            ]

        case "gameover":
            gameState = .gameOver
            score = 12
            bird = Bird(
                x: size.width * 0.34,
                y: size.height * 0.62,
                velocity: 120,
                size: CGSize(width: 18, height: 18)
            )
            obstacles = [
                Obstacle(
                    x: size.width * 0.76,
                    gapCenterY: size.height * 0.44,
                    gapHeight: 88,
                    width: obstacleWidth,
                    hasScored: true
                )
            ]

        case "dailycomplete":
            gameState = .gameOver
            isDailyChallenge = true
            gameEndReason = .sessionComplete
            score = 18
            bestScore = max(bestScore, 36)
            dailyBestScore = max(dailyBestScore, 18)
            bird = Bird(
                x: size.width * 0.32,
                y: size.height * 0.58,
                velocity: -10,
                size: CGSize(width: 18, height: 18)
            )
            obstacles = [
                Obstacle(
                    x: size.width * 0.80,
                    gapCenterY: size.height * 0.46,
                    gapHeight: 90,
                    width: obstacleWidth,
                    hasScored: true
                )
            ]

        default:
            isPreviewingScreenshot = false
            configure(size: size)
        }
    }

    private func startGame() {
        bird = Bird.makeDefault(in: playfieldSize)
        obstacles = []
        score = 0
        scorePulse = 0
        crashFlashOpacity = 0
        isNewBest = false
        gameEndReason = .crash
        spawnedObstacleCount = 0
        crownImpulse = 0
        proximityHapticTriggered = []
        gameState = .playing
        lastTick = Date()
        sessionTimeRemaining = rhythmSessionDuration
        spawnObstacleIfNeeded(force: true)
    }

    private func updateBird(deltaTime: TimeInterval) {
        bird.velocity += currentGravity * CGFloat(deltaTime)

        if crownImpulse != 0 {
            let crownForce: CGFloat = crownImpulse > 0 ? crownUpwardForce : crownDownwardForce
            bird.velocity += crownForce * CGFloat(deltaTime)
            crownImpulse *= crownDamping
            if abs(crownImpulse) < 0.5 {
                crownImpulse = 0
            }
        }

        bird.y += bird.velocity * CGFloat(deltaTime)
    }

    private func performAutoplayIfNeeded() {
        guard autoplayMode != .off, gameState == .playing else { return }

        let targetY: CGFloat

        if let obstacle = obstacles.first(where: { $0.x + $0.width >= bird.x - 6 }) {
            let dangerX = obstacle.x - bird.x
            let gapBias: CGFloat = dangerX < 28 ? 8 : 2
            targetY = obstacle.gapCenterY + gapBias

            if bird.y > obstacle.gapCenterY + (obstacle.gapHeight * 0.22) || (dangerX < 18 && bird.velocity > 18) {
                flap()
                return
            }
        } else {
            targetY = playfieldSize.height * 0.55
        }

        if bird.y > targetY && bird.velocity > -60 {
            flap()
        }
    }

    private func updateObstacles(deltaTime: TimeInterval) {
        for index in obstacles.indices {
            obstacles[index].x -= currentObstacleSpeed * CGFloat(deltaTime)
        }

        obstacles.removeAll { $0.x + $0.width < 0 }
    }

    private func spawnObstacleIfNeeded(force: Bool = false) {
        if force || obstacles.isEmpty {
            obstacles.append(makeObstacle(x: playfieldSize.width + initialObstacleOffset))
            return
        }

        guard let lastObstacle = obstacles.last else { return }

        if lastObstacle.x < playfieldSize.width - currentObstacleSpacing {
            obstacles.append(makeObstacle(x: playfieldSize.width + initialObstacleOffset))
        }
    }

    private func makeObstacle(x: CGFloat) -> Obstacle {
        let isEasyOpeningObstacle = spawnedObstacleCount < currentEasyObstacleCount
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
        let baseHeight = min(max(currentMinimumGapHeight, playfieldSize.height * 0.42), playfieldSize.height * 0.56)
        let bonusHeight: CGFloat

        if isEasyOpeningObstacle {
            bonusHeight = isDailyChallenge ? 12 : 8
        } else {
            bonusHeight = isDailyChallenge ? 4 : 0
        }

        return min(playfieldSize.height * 0.68, baseHeight + bonusHeight)
    }

    private func obstacleGapCenter(gapHeight: CGFloat, isEasyOpeningObstacle: Bool) -> CGFloat {
        let minGapCenter = topPadding + gapHeight / 2
        let maxGapCenter = playfieldSize.height - bottomPadding - gapHeight / 2
        let centerY = playfieldSize.height * 0.5

        guard isEasyOpeningObstacle else {
            if var rng = seededRNG {
                let value = CGFloat.random(in: minGapCenter...maxGapCenter, using: &rng)
                seededRNG = rng
                return value
            }
            return CGFloat.random(in: minGapCenter...maxGapCenter)
        }

        let openingRange = min(playfieldSize.height * 0.08, max(4, (maxGapCenter - minGapCenter) * 0.5))
        let easyMin = max(minGapCenter, centerY - openingRange)
        let easyMax = min(maxGapCenter, centerY + openingRange)

        if var rng = seededRNG {
            let value = CGFloat.random(in: easyMin...easyMax, using: &rng)
            seededRNG = rng
            return value
        }
        return CGFloat.random(in: easyMin...easyMax)
    }

    private func updateScoreIfNeeded() {
        for index in obstacles.indices {
            if !obstacles[index].hasScored && obstacles[index].x + obstacles[index].width < bird.x {
                obstacles[index].hasScored = true
                WKInterfaceDevice.current().play(.success)
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
        gameEndReason = .crash
        crashFlashOpacity = 0.9
        audioManager.playHit()
        WKInterfaceDevice.current().play(.failure)

        if isDailyChallenge {
            scoreStore.saveDailyBest(score)
            dailyBestScore = scoreStore.loadDailyBest()
        }

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

    private func triggerSessionComplete() {
        guard gameState == .playing else { return }

        gameState = .gameOver
        gameEndReason = .sessionComplete
        crashFlashOpacity = 0.0
        WKInterfaceDevice.current().play(.success)

        scoreStore.saveDailyBest(score)
        dailyBestScore = scoreStore.loadDailyBest()

        if score > bestScore {
            bestScore = score
            isNewBest = true
            scoreStore.save(bestScore: score)
        } else {
            isNewBest = false
        }
    }

    private func updateHapticFeedback() {
        for obstacle in obstacles {
            let proximity = obstacle.x - bird.x
            if proximity > 0 && proximity < hapticProximityThreshold && !proximityHapticTriggered.contains(obstacle.id) {
                WKInterfaceDevice.current().play(.click)
                proximityHapticTriggered.insert(obstacle.id)
            }
        }

        let activeObstacleIds = Set(obstacles.map(\.id))
        proximityHapticTriggered = proximityHapticTriggered.intersection(activeObstacleIds)
    }
}
