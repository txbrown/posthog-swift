//
//  File.swift
//  
//
//  Created by Leonard Mehlig on 20.03.21.
//

import Foundation

struct EventPayload: Codable, Hashable, Comparable {
    var timestamp: Date = Date()

    var messageId: String = UUID().uuidString

    let distinctId: String

    let event: String

    let properties: [String: AnyCodable]

    init(event: String, distinctId: String, isSensitive: Bool, properties: [String: AnyCodable], featureFlags: [String: AnyCodable]) {
        self.event = event
        if isSensitive {
            self.distinctId = "00000000-0000-0000-00000000000000000"
            self.properties = EventPayload.sensitiveContext.merging(properties, uniquingKeysWith: { $1 })
        } else {
            self.distinctId = distinctId
            self.properties = EventPayload.context
                .merging(featureFlags.map({ ("$feature/\($0.key)", $0.value) }), uniquingKeysWith: { $1 })
                .merging(properties, uniquingKeysWith: { $1 })
        }
    }

    static var context: [String: AnyCodable] {
        var context: [String: AnyCodable] = [:]
        let info = (Bundle.main.infoDictionary ?? [:]).merging(Bundle.main.localizedInfoDictionary ?? [:], uniquingKeysWith: { $1 })
        context["$app_name"] = (info["CFBundleDisplayName"] as? String)?.codable
        context["$app_version"] = (info["CFBundleShortVersionString"] as? String)?.codable
        context["$app_build"] = (info["CFBundleVersion"] as? String)?.codable
        context["$app_namespace"] = Bundle.main.bundleIdentifier?.codable

        context["$device_manufacturer"] = "Apple"
        context["$device_type"] = Device.type.codable
        context["$device_model"] = Device.model.codable
        context["$os_name"] = Device.system.codable
        context["$os_version"] = Device.systemVersion.codable

        context["$screen_width"] = Double(Device.screenSize.width).codable
        context["$screen_height"] = Double(Device.screenSize.height).codable

        context["$lib"] = "posthog-swift"
        context["$lib_version"] = "1.1.0"

        if let lang = Locale.current.languageCode {
            if let country = Locale.current.regionCode {
                context["$local"] = "\(lang)-\(country)".codable
            } else {
                context["$local"] = lang.codable
            }
            context["$language"] = lang.codable
        }
        context["$timezone"] = TimeZone.current.identifier.codable

        //TODO: Add $network_cellular and $network_wifi

        return context
    }

    static var sensitiveContext: [String: AnyCodable] {
        var context: [String: AnyCodable] = [:]
        let info = (Bundle.main.infoDictionary ?? [:]).merging(Bundle.main.localizedInfoDictionary ?? [:], uniquingKeysWith: { $1 })
        context["$app_name"] = (info["CFBundleDisplayName"] as? String)?.codable
        context["$app_version"] = (info["CFBundleShortVersionString"] as? String)?.codable
        context["$app_build"] = (info["CFBundleVersion"] as? String)?.codable
        context["$app_namespace"] = Bundle.main.bundleIdentifier?.codable

        context["$lib"] = "posthog-swift"
        context["$lib_version"] = "1.1.0"

        return context
    }

    static func < (lhs: EventPayload, rhs: EventPayload) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }


    func hash(into hasher: inout Hasher) {
        hasher.combine(messageId)
    }

    static func == (lhs: EventPayload, rhs: EventPayload) -> Bool {
        return lhs.messageId == rhs.messageId
    }

}
