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
                        Text("ios_title")
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)

                        Text("ios_install_message")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Text("ios_packaging_message")
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
