import Combine
import Foundation

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
                backgroundHandler: BackgroundTaskHandler? = nil)
    {
        self.apiKey = apiKey
        self.host = host
        self.isEnabled = isEnabled
        queue = Queue(client: Client(host: host, apiKey: apiKey), background: backgroundHandler)

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
            queue.queue(event: EventPayload(event: "$create_alias",
                                            distinctId: self.id,
                                            sessionId: sessionID?.uuidString,
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

        featureFlags = queue.storage.load()
        loadFeatureFlags()
    }

    public func capture(event: Event) {
        guard isEnabled else {
            return
        }
        queue.queue(event: event.payload(id: id, sessionID: sessionID?.uuidString, featureFlags: featureFlags))
        logger.log(event: event)
    }

    public func screen(name: String, properties: [String: Any] = [:]) {
        capture(event: Event.screen(with: name, properties: properties))
    }

    public func launched(properties: [String: Any] = [:]) {
        sessionID = UUID()
        let previousVersion = userDefaults.string(forKey: "posthog.version")
        let previousBuild = userDefaults.string(forKey: "posthog.build")

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

        userDefaults.setValue(version, forKey: "posthog.version")
        userDefaults.setValue(build, forKey: "posthog.build")

        if previousBuild == nil {
            capture(event: .installed(version: version, build: build))
        } else if build != previousBuild {
            capture(event: .updated(version: version,
                                    build: build,
                                    previousVersion: previousVersion ?? "",
                                    previousBuild: previousBuild ?? ""))
        }
        capture(event: .opened(fromBackground: isLaunched,
                               version: version,
                               build: build,
                               properties: properties))

        isLaunched = true
    }

    public func backgrounded(properties: [String: Any] = [:]) {
        capture(event: .backgrounded(properties: properties))
        queue.flushAll()
        sessionID = nil
    }

    public func logger(isEnabled: Bool) -> Tracker {
        logger.isEnabled = isEnabled
        return self
    }

    public func loadFeatureFlags() {
        featureFlagCancellable?.cancel()
        featureFlagCancellable = queue.client.decide(for: id)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] featureFlags in
                      self?.featureFlags = featureFlags
                      self?.queue.storage.save(featureFlags: featureFlags)
                  })
    }

    @discardableResult
    public func override(featureFlag flag: String, with value: AnyCodable?) -> Tracker {
        overrideFlags[flag] = value
        return self
    }

    public func variant(for flag: String) -> AnyCodable? {
        overrideFlags[flag] ?? featureFlags[flag]
    }

    public func variant(for flag: String, default: Bool) -> Bool {
        variant(for: flag)?.value as? Bool ?? `default`
    }

    public func variant(for flag: String, default: String) -> String {
        variant(for: flag)?.value as? String ?? `default`
    }

    public func identify(distinctId id: String, userProperties: [String: Any], properties: [String: Any] = [:]) {
        guard isEnabled else {
            return
        }

        let event = Event("$identify", properties: properties.merging(["$set": userProperties], uniquingKeysWith: { $1 }))
        queue.queue(event: event.payload(id: id, sessionID: sessionID?.uuidString, featureFlags: featureFlags))
        logger.log(event: event)
    }
}
