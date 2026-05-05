# Bird Dash Watch

This folder contains a SwiftUI `watchOS` app for `Bird Dash Watch`.

## What is included

- SwiftUI app entry point
- Simple game state flow
- Game engine with tap, gravity, obstacle spawning, scoring, and collision
- Start and game-over overlays
- Best score persistence
- Haptic feedback hooks for flap / score / hit
- Xcode project and XcodeGen spec
- App icon asset catalog

## What is not included yet

- Final art assets
- Sound files
- App Store screenshots

## Recommended next step

Open `BirdDashWatch.xcodeproj`, build the `BirdDashWatch Watch App` scheme, then test on an Apple Watch simulator or device.

## Current gameplay status

- Playable core loop scaffold is in place
- Tap starts the run and also gives upward impulse
- Obstacles spawn, move, score, and collide
- Best score persists locally
- Start and retry overlays are wired for a first playable build

## Xcode steps

1. Open `BirdDashWatch.xcodeproj`
2. Select the `BirdDashWatch Watch App` scheme
3. Build on simulator first, then test on a real Apple Watch
4. After the first run, tune constants in `BirdDashWatch Watch App/Engine/GameEngine.swift`

## Command-line checks

```sh
xcodebuild -project BirdDashWatch.xcodeproj -scheme "BirdDashWatch Watch App" -destination "generic/platform=watchOS" CODE_SIGNING_ALLOWED=NO build
```

For signed device builds and archives, make sure the Apple Developer team has a provisioning profile for `com.water.BirdDashWatch.watchkitapp`.

## First tuning knobs

- `gravity`
- `flapVelocity`
- `obstacleSpeed`
- `obstacleSpacing`
- `minimumGapHeight`
