//
//  File.swift
//  
//
//  Created by Leonard Mehlig on 20.03.21.
//

import Foundation


struct Storage {
    var queueUrl: URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent((Bundle.main.bundleIdentifier ?? "") + "-postog.queue.json")
    }

    var featureFlagsUrl: URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent((Bundle.main.bundleIdentifier ?? "") + "-postog.feature-flags.json")
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func save(queue: Set<EventPayload>) {
        guard let url = queueUrl,
              let data = try? encoder.encode(queue) else {
            return
        }

        do {
            try data.write(to: url)
        } catch {
            print("Failed saving queue:", error)
        }
    }

    func load() -> Set<EventPayload> {
        guard let url = queueUrl,
              let data = try? Data(contentsOf: url) else {
            return []
        }

        return (try? self.decoder.decode(Set<EventPayload>.self, from: data)) ?? []
    }

    func save(featureFlags: [String: AnyCodable]) {
        guard let url = featureFlagsUrl,
              let data = try? encoder.encode(featureFlags) else {
            return
        }

        do {
            try data.write(to: url)
        } catch {
            print("Failed saving queue:", error)
        }
    }

    func load() -> [String: AnyCodable] {
        guard let url = featureFlagsUrl,
              let data = try? Data(contentsOf: url) else {
                  return [:]
        }

        return (try? self.decoder.decode([String: AnyCodable].self, from: data)) ?? [:]
    }
}
