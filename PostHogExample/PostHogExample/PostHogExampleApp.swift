import SwiftUI
import PostHog

@main
struct PostHogExampleApp: App {

    @StateObject var tracker = PostHog(apiKey: "3ySFxM8aQovRF6GGOgcENolSZDARC2HCIds3AuPh1Io", host: URL(string: "https://posthog.structured.today")!, application: .shared)
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tracker)
                .onChange(of: scenePhase, perform: { value in
                    switch value {
                    case .active:
                        tracker.launch()
                    case .background:
                        tracker.background()
                    default:
                        break
                    }
                })
                .onAppear {
                    tracker.launch()
                }
        }
    }
}
