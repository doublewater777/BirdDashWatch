import WatchKit

struct AudioManager {
    func playFlap() {
        WKInterfaceDevice.current().play(.click)
    }

    func playScore() {
        WKInterfaceDevice.current().play(.success)
    }

    func playHit() {
        WKInterfaceDevice.current().play(.failure)
    }
}
