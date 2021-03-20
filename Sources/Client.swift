//
//  File.swift
//  
//
//  Created by Leonard Mehlig on 20.03.21.
//

import Foundation
import Combine

class Client {
    struct Request: Codable {
        let sentAt: Date
        let batch: [EventPayload]
        let apiKey: String
    }
    let host: URL
    let apiKey: String

    private let encoder: JSONEncoder = {
        var encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()


    init(host: URL, apiKey: String) {
        self.host = host
        self.apiKey = apiKey
    }


    /// Sends a batch of requests to the server.
    /// - Parameter requests: All request to be sent.
    /// - Returns: A publisher with a boolean indicating if the request should be retried (true) or discarded (false).
    func send(batch: [EventPayload]) -> AnyPublisher<Bool, Never> {
        var request = URLRequest(url: host.appendingPathComponent("batch"))
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            //TODO: Add gzip compression.
//        request.addValue("gzip", forHTTPHeaderField: "Accept-Encoding")
//        request.addValue("gzip", forHTTPHeaderField: "Content-Encoding")
        request.addValue("posthog-ios/1.0", forHTTPHeaderField: "User-Agent") //TODO: Add real user agent


        do {
            request.httpBody = try self.encoder.encode(Request(sentAt: Date(), batch: batch, apiKey: apiKey))
        } catch {
            print("Error encoding requests: \(error)")
            return Just(false).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .map { response in
                guard let statusCode = (response.response as? HTTPURLResponse)?.statusCode else {
                    return true
                }
                switch statusCode {
                case 0..<300:
                    return false
                case 300..<400:
                    return true
                case 429:
                    return true
                case 400..<500:
                    return false
                default:
                    return true

                }
            }
            .replaceError(with: true)
            .eraseToAnyPublisher()

    }
}
