//
//  File.swift
//  
//
//  Created by Leonard Mehlig on 20.03.21.
//

import Foundation
import Combine
import UIKit

class Queue {
    let maxSize: Int = 1000
    let flushSize: Int = 10
    let flushInterval: TimeInterval = 30
    let maxBatch: Int = 100

    let client: Client
    let application: UIApplication?

    let storage = Storage()

    init(client: Client, application: UIApplication?) {
        self.client = client
        self.application = application
        self.events = self.storage.load()
        Timer.publish(every: flushInterval, on: .main, in: .default)
            .autoconnect()
            .receive(on: queue)
            .sink { _ in
                self.flushBatch()
            }
            .store(in: &cancellables)

    }
    
    private var events: Set<EventPayload> = []
    private var sending: Set<EventPayload> = []

    private let queue = DispatchQueue(label: "posthog_queue", qos: .background)
    private var cancellables: Set<AnyCancellable> = []

    func queue(event: EventPayload) {
        queue.async {
            self.events.insert(event)
            if self.events.count > self.maxSize {
                let remove = self.events.sorted().prefix(self.events.count - self.maxSize)
                self.events.subtract(remove)
            }
            if self.events.count >= self.flushSize {
                self.flushBatch()
            }

            self.storage.save(queue: self.events.union(self.sending))
        }
    }

    func flushAll() {
        queue.async {
            while !self.events.isEmpty {
                self.flushBatch()
            }
        }
    }

    //Only call on queue
    private func flushBatch() {
        guard !self.events.isEmpty else {
            return
        }
        let batch = Array(self.events.sorted().prefix(maxBatch))
        self.events.subtract(batch)
        self.sending.formUnion(batch)
        let task = self.application?.beginBackgroundTask(expirationHandler: nil)
        self.client.send(batch: batch)
            .receive(on: self.queue)
            .sink { [weak self] retry in
                guard let self = self else {
                    return
                }
                self.sending.subtract(batch)
                if retry {
                    self.events.formUnion(batch)
                }
                self.storage.save(queue: self.events.union(self.sending))
                if let task = task {
                    self.application?.endBackgroundTask(task)
                }
            }
            .store(in: &cancellables)
    }
}
