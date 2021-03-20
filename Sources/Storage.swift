//
//  File.swift
//  
//
//  Created by Leonard Mehlig on 20.03.21.
//

import Foundation


struct Storage {
    var url: URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent((Bundle.main.bundleIdentifier ?? "") + "-postog.queue.json")
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func save(queue: Set<EventPayload>) {
        guard let url = url,
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
        guard let url = url,
              let data = try? Data(contentsOf: url)else {
            return []
        }

        return (try? self.decoder.decode(Set<EventPayload>.self, from: data)) ?? []
    }
}
