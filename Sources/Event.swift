//
//  File.swift
//  
//
//  Created by Leonard Mehlig on 21.03.21.
//

import Foundation
import StoreKit

public struct Event: ExpressibleByStringLiteral {

    let value: String

    let properties: [String: Any]

    let isSensitive: Bool

    public init(_ value: String, isSensitive: Bool = false, properties: [String: Any]) {
        self.value = value
        self.isSensitive = isSensitive
        self.properties = properties
    }

    public init(stringLiteral value: String) {
        self.value = value
        self.isSensitive = false
        self.properties = [:]
    }
    
    public static func screen(with name: String, properties: [String: Any]) -> Event {
        Event("$screen", properties: ["$screen_name": name].merging(properties, uniquingKeysWith: { $1 }))
    }

    public static func purchaseInitiated(currency: String,
                                         productId: String,
                                         quantity: Int = 1,
                                         price: Double,
                                         name: String,
                                         origin: String) -> Event {
        Event("Order Initiated", properties: [
            "affiliation" : "App Store",
            "currency" : currency,
            "origin": origin,
            "products" : [
                [
                   "quantity" : quantity,
                   "productId" : productId,
                   "price" : price,
                   "name" : name,
                ]
            ]
        ])
    }

    public static func purchaseCompleted(id: String,
                                         currency: String,
                                         productId: String,
                                         quantity: Int = 1,
                                         price: Double,
                                         name: String,
                                         origin: String,
                                         properties: [String: Any] = [:]) -> Event {
        Event("Order Completed", properties: [
            "orderId" : id,
            "affiliation" : "App Store",
            "currency" : currency,
            "amount": price,
            "origin": origin,
            "products" : [
                [
                    "sku" : id,
                    "quantity" : quantity,
                    "productId" : productId,
                    "price" : price,
                    "name" : name,
                ]
            ]
        ].merging(properties, uniquingKeysWith: { $1 }))
    }

    public static func purchaseRestored(id: String,
                                         currency: String,
                                         productId: String,
                                         quantity: Int = 1,
                                         price: Double,
                                         name: String,
                                         origin: String,
                                         properties: [String: Any] = [:]) -> Event {
        Event("Order Restored", properties: [
            "orderId" : id,
            "affiliation" : "App Store",
            "currency" : currency,
            "amount": price,
            "origin": origin,
            "products" : [
                [
                    "sku" : id,
                    "quantity" : quantity,
                    "productId" : productId,
                    "price" : price,
                    "name" : name,
                ]
            ]
        ].merging(properties, uniquingKeysWith: { $1 }))
    }

    @available(watchOS 6.2, *)
    public static func purchaseFailed(error: Error?,
                                      id: String,
                                      currency: String,
                                      productId: String,
                                      quantity: Int = 1,
                                      price: Double,
                                      name: String,
                                      origin: String,
                                      properties: [String: Any] = [:]) -> Event {

        let code = (error as? SKError)?.code ?? .unknown
        guard code != .paymentCancelled else {
            return Event.purchaseCancelled(id: id,
                                           currency: currency,
                                           productId: productId,
                                           price: price,
                                           name: name,
                                           origin: origin,
                                           properties: properties)
        }
        return Event("Order Failed", properties: [
            "orderId" : id,
            "affiliation" : "App Store",
            "currency" : currency,
            "amount": price,
            "origin": origin,
            "error_code": code.rawValue,
            "products" : [
                [
                   "sku" : id,
                   "quantity" : quantity,
                   "productId" : productId,
                   "price" : price,
                   "name" : name,
                ]
            ]
        ].merging(properties, uniquingKeysWith: { $1 }))
    }

    public static func purchaseCancelled(id: String,
                                         currency: String,
                                         productId: String,
                                         quantity: Int = 1,
                                         price: Double,
                                         name: String,
                                         origin: String,
                                         properties: [String: Any] = [:]) -> Event {
        Event("Order Cancelled", properties: [
            "orderId" : id,
            "affiliation" : "App Store",
            "currency" : currency,
            "amount": price,
            "origin": origin,
            "products" : [
                [
                   "sku" : id,
                   "quantity" : quantity,
                   "productId" : productId,
                   "price" : price,
                   "name" : name,
                ]
            ]
        ].merging(properties, uniquingKeysWith: { $1 }))
    }

    static func installed(version: String, build: String) -> Event {
        Event("Application Installed", properties: [
            "version": version,
            "build": build
        ])
    }

    static func updated(version: String, build: String, previousVersion: String, previousBuild: String) -> Event {
        Event("Application Updated", properties: [
            "previous_version" : previousVersion,
            "previous_build" : previousBuild,
            "version" : version,
            "build" : build,
        ])
    }

    static func opened(fromBackground: Bool, version: String, build: String, properties: [String: Any] = [:]) -> Event {
        Event("Application Opened",
              properties: [
                 "from_background" : fromBackground,
                 "version" : version,
                 "build" : build,
              ].merging(properties, uniquingKeysWith: { $1 }))
    }

    static func backgrounded(properties: [String: Any] = [:]) -> Event {
        Event("Application Backgrounded", properties: properties)
    }

    func payload(id: String, featureFlags: [String: AnyCodable]) -> EventPayload {
        EventPayload(event: self.value, distinctId: id, isSensitive: isSensitive, properties: properties.mapValues({ AnyCodable($0) }), featureFlags: featureFlags)
    }
}
