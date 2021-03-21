import Foundation
import UIKit

public class Tracker: ObservableObject {

    public let apiKey: String
    public let host: URL
    public var id: String

    private let queue: Queue


    private let userDefaults: UserDefaults

    private var isLaunched = false

    public init(apiKey: String,
                host: URL,
                id: String? = nil,
                userDefaults: UserDefaults = .standard,
                application: UIApplication? = nil) {
        self.apiKey = apiKey
        self.host = host

        self.queue = Queue(client: Client(host: host, apiKey: apiKey), application: application)

        self.userDefaults = userDefaults

        if let id = id {
            self.id = id
        } else if let id = self.userDefaults.string(forKey: "posthog.user-id") {
            self.id = id
        } else {
            self.id = UUID().uuidString
            self.userDefaults.setValue(id, forKey: "posthog.user-id")
        }
    }


    public func capture(event: Event, properties: [String: Any] = [:]) {
        self.queue.queue(event: .capture(event: event, distinctId: id, properties: properties.mapValues(AnyCodable.init)))
    }

    public func screen(name: String, properties: [String: Any] = [:]) {
        self.queue.queue(event: .screen(name: name, distinctId: id, properties: properties.mapValues(AnyCodable.init)))
    }

    public func launch(properties: [String: Any] = [:]) {
        let previousVersion = self.userDefaults.string(forKey: "posthog.version")
        let previousBuild = self.userDefaults.string(forKey: "posthog.build")

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

        self.userDefaults.setValue(version, forKey: "posthog.version")
        self.userDefaults.setValue(build, forKey: "posthog.build")

        if previousBuild == nil {
            self.capture(event: "Application Installed", properties: [
                "version": version.codable,
                "build": build.codable
            ])
        } else if build != previousBuild {
            self.capture(event: "Application Updated", properties: [
                "previous_version" : previousVersion?.codable ?? "",
                "previous_build" : previousBuild?.codable ?? "",
                "version" : version.codable,
                "build" : build.codable,
            ])
        }

        self.capture(event: "Application Opened",
                     properties: [
                        "from_background" : isLaunched.codable,
                        "version" : version.codable,
                        "build" : build.codable,
                     ].merging(properties.mapValues(AnyCodable.init), uniquingKeysWith: { $1 }))

        self.isLaunched = true
    }

    public func background(properties: [String: Any] = [:]) {
        self.capture(event: "Application Backgrounded", properties: properties.mapValues(AnyCodable.init))
        self.queue.flushAll()
    }
}
