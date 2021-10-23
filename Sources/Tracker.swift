import Foundation
import Combine

public class Tracker: ObservableObject {

    public let apiKey: String
    public let host: URL
    public var id: String

    public var isEnabled: Bool

    private let queue: Queue


    private let userDefaults: UserDefaults

    private var isLaunched = false

    private var featureFlagCancellable: AnyCancellable?

    var logger = EventLogger()

    @Published public var featureFlags: [String: AnyCodable] = [:]


    public init(apiKey: String,
                host: URL,
                isEnabled: Bool = true,
                id: String? = nil,
                userDefaults: UserDefaults = .standard,
                backgroundHandler: BackgroundTaskHandler? = nil) {
        self.apiKey = apiKey
        self.host = host
        self.isEnabled = isEnabled
        self.queue = Queue(client: Client(host: host, apiKey: apiKey), background: backgroundHandler)

        self.userDefaults = userDefaults

        if let id = id {
            self.id = id
        } else if let id = self.userDefaults.string(forKey: "posthog.user-id") {
            self.id = id
        } else {
            self.id = UUID().uuidString
            self.userDefaults.set(self.id, forKey: "posthog.user-id")
        }

        print(self.id)
        
        self.featureFlags = self.queue.storage.load()
        self.loadFeatureFlags()
    }


    public func capture(event: Event) {
        guard self.isEnabled else {
            return
        }
        self.queue.queue(event: event.payload(id: id))
        self.logger.log(event: event)
    }

    public func screen(name: String, properties: [String: Any] = [:]) {
        self.capture(event: Event.screen(with: name, properties: properties))
    }

    public func launched(properties: [String: Any] = [:]) {
        let previousVersion = self.userDefaults.string(forKey: "posthog.version")
        let previousBuild = self.userDefaults.string(forKey: "posthog.build")

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

        self.userDefaults.setValue(version, forKey: "posthog.version")
        self.userDefaults.setValue(build, forKey: "posthog.build")

        if previousBuild == nil {
            self.capture(event: .installed(version: version, build: build))
        } else if build != previousBuild {
            self.capture(event: .updated(version: version,
                                         build: build,
                                         previousVersion: previousVersion ?? "",
                                         previousBuild: previousBuild ?? ""))
        }
        self.capture(event: .opened(fromBackground: isLaunched,
                                    version: version,
                                    build: build,
                                    properties: properties))

        self.isLaunched = true
    }

    public func backgrounded(properties: [String: Any] = [:]) {
        self.capture(event: .backgrounded(properties: properties))
        self.queue.flushAll()
    }

    public func logger(isEnabled: Bool) -> Tracker {
        self.logger.isEnabled = isEnabled
        return self
    }

    public func loadFeatureFlags() {
        self.featureFlagCancellable?.cancel()
        self.featureFlagCancellable = self.queue.client.decide(for: self.id)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] featureFlags in
                print(featureFlags)
                self?.featureFlags = featureFlags
                self?.queue.storage.save(featureFlags: featureFlags)
            })
    }
}
