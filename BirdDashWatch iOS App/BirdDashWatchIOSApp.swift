#if os(iOS)
import SwiftUI
import UIKit

@main
struct BirdDashWatchIOSApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                VStack(spacing: 16) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 42, weight: .regular))
                        .foregroundStyle(.tint)

                    VStack(spacing: 6) {
                        Text("Bird Dash Watch")
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)

                        Text("Install and launch the game on Apple Watch.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Text("This iPhone app exists to package the Watch app for App Store upload and installation.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
    }
}
#endif
