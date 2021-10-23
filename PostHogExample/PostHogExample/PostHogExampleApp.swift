import SwiftUI
import PostHog

@main
struct PostHogExampleApp: App {

    @StateObject var tracker = Tracker(apiKey: "61ICqPkNhFJEx_a69ImxM4G3IG_M0w9JjkmjtoRRLsQ", host: URL(string: "https://posthog.structured.today")!, id: "6633EED1-6784-4091-9781-03159966A80C", backgroundHandler: UIApplication.shared).logger(isEnabled: true)
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tracker)
                .onChange(of: scenePhase, perform: { value in
                    switch value {
                    case .active:
                        tracker.launched()
                    case .background:
                        tracker.backgrounded()
                    default:
                        break
                    }
                })
                .onAppear {
//                    tracker.launch
                }
        }
    }
}
