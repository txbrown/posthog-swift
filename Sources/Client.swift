//
//  File.swift
//  
//
//  Created by Leonard Mehlig on 20.03.21.
//

import Foundation
import Combine

class Client {
    private struct BatchRequest: Codable {
        let sentAt: Date
        let batch: [EventPayload]
        let apiKey: String
    }

    private struct DecideRequest: Codable {
        let apiKey: String
        let distinctId: String
    }

    private struct DecideResponse: Codable {
        let featureFlags: [String: AnyCodable]
    }

    let host: URL
    let apiKey: String

    private let encoder: JSONEncoder = {
        var encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()


    private let decoder: JSONDecoder = {
        var decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
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
        request.addValue("posthog-ios/1.1", forHTTPHeaderField: "User-Agent") //TODO: Add real user agent


        do {
            request.httpBody = try self.encoder.encode(BatchRequest(sentAt: Date(), batch: batch, apiKey: apiKey))
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

    func decide(for user: String) -> AnyPublisher<[String: AnyCodable], Error> {
        let url = host.appendingPathComponent("decide")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [.init(name: "v", value: "2")]
        var request = URLRequest(url: components?.url ?? url)

        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("posthog-ios/1.1", forHTTPHeaderField: "User-Agent") //TODO: Add real user agent


        do {
            request.httpBody = try self.encoder.encode(DecideRequest(apiKey: apiKey, distinctId: user))
        } catch {
            print("Error encoding requests: \(error)")
            return Fail(error: error).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: DecideResponse.self, decoder: decoder)
            .map(\.featureFlags)
            .eraseToAnyPublisher()
    }
}
