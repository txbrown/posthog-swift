//
//  File.swift
//  File
//
//  Created by Leo Mehlig on 07.09.21.
//

import Foundation
import OSLog

struct EventLogger {
    private var logger: Any?

    var isEnabled: Bool = false

    init() {
        if #available(iOS 14, macOS 11, *) {
            self.logger = Logger(subsystem: "com.posthog.tracker", category: "PostHog")
        }
    }

    func log(event: Event) {
        if self.isEnabled,
           #available(iOS 14, macOS 11, *),
           let logger = self.logger as? Logger {
            let properties = event.properties
                .mapValues({ AnyCodable($0) })
            if !event.properties.isEmpty,
               let data = try? JSONEncoder().encode(properties),
               let string = String(data: data, encoding: .utf8) {
                logger.info("[PostHog] Captured '\(event.value)'\n\(string)")

            } else {
                logger.info("[PostHog] Captured '\(event.value)'")
            }
        }
    }
}
