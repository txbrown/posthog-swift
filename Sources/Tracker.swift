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

    @Published public var overrideFlags: [String: AnyCodable] = [:]
    
    var sessionID: UUID?

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

        let savedId = self.userDefaults.string(forKey: "posthog.user-id")
        if let id = id {
            self.id = id
        } else if let id = savedId {
            self.id = id
        } else {
            self.id = UUID().uuidString
        }

        if let savedId = savedId, savedId != self.id, self.isEnabled {
            print("Alias from \(savedId) to \(self.id)")
            self.queue.queue(event: EventPayload(event: "$create_alias",
                                                 distinctId: self.id,
                                                 sessionId: self.sessionID?.uuidString,
                                                 type: .alias,
                                                 isSensitive: false,
                                                 properties: [
                                                    "distinct_id": self.id.codable,
                                                    "alias": savedId.codable,
                                                 ],
                                                 featureFlags: [:]))
        }
        print(self.id)
        self.userDefaults.set(self.id, forKey: "posthog.user-id")
        
        self.featureFlags = self.queue.storage.load()
        self.loadFeatureFlags()
    }


    public func capture(event: Event) {
        guard self.isEnabled else {
            return
        }
        self.queue.queue(event: event.payload(id: id, sessionID: self.sessionID?.uuidString, featureFlags: featureFlags))
        self.logger.log(event: event)
    }

    public func screen(name: String, properties: [String: Any] = [:]) {
        self.capture(event: Event.screen(with: name, properties: properties))
    }

    public func launched(properties: [String: Any] = [:]) {
        self.sessionID = UUID()
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
        self.sessionID = nil
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
                self?.featureFlags = featureFlags
                self?.queue.storage.save(featureFlags: featureFlags)
            })
    }

    @discardableResult
    public func override(featureFlag flag: String, with value: AnyCodable?) -> Tracker {
        self.overrideFlags[flag] = value
        return self
    }

    public func variant(for flag: String) -> AnyCodable? {
        self.overrideFlags[flag] ?? self.featureFlags[flag]
    }

    public func variant(for flag: String, default: Bool) -> Bool {
        self.variant(for: flag)?.value as? Bool ?? `default`
    }

    public func variant(for flag: String, default: String) -> String {
        self.variant(for: flag)?.value as? String ?? `default`
    }
}
