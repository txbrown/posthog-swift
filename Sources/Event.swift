//
//  File.swift
//  
//
//  Created by Leonard Mehlig on 21.03.21.
//

import Foundation

public struct Event: ExpressibleByStringLiteral {

    let value: String

    let properties: [String: Any]

    public init(_ value: String, properties: [String: Any]) {
        self.value = value
        self.properties = properties
    }

    public init(stringLiteral value: String) {
        self.value = value
        self.properties = [:]
    }
    
    public static func screen(with name: String, properties: [String: Any]) -> Event {
        Event("$screen", properties: ["$screen_name": name].merging(properties, uniquingKeysWith: { $1 }))
    }

    public static func purchaseInitiated(id: String,
                                         currency: String,
                                         productId: String,
                                         quantity: Int = 1,
                                         price: Double,
                                         name: String,
                                         origin: String) -> Event {
        Event("Order Initiated", properties: [
            "orderId" : id,
            "affiliation" : "App Store",
            "currency" : currency,
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
        ])
    }

    public static func purchaseCompleted(id: String,
                                         currency: String,
                                         productId: String,
                                         quantity: Int = 1,
                                         price: Double,
                                         name: String,
                                         origin: String) -> Event {
        Event("Order Completed", properties: [
            "orderId" : id,
            "affiliation" : "App Store",
            "currency" : currency,
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
        ])
    }

    public static func purchaseFailed(error: String,
                                      id: String,
                                      currency: String,
                                      productId: String,
                                      quantity: Int = 1,
                                      price: Double,
                                      name: String,
                                      origin: String) -> Event {
        Event("Order Failed", properties: [
            "orderId" : id,
            "affiliation" : "App Store",
            "currency" : currency,
            "origin": origin,
            "error": error,
            "products" : [
                [
                   "sku" : id,
                   "quantity" : quantity,
                   "productId" : productId,
                   "price" : price,
                   "name" : name,
                ]
            ]
        ])
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

    func payload(id: String) -> EventPayload {
        EventPayload(event: self.value, distinctId: id, properties: properties.mapValues({ AnyCodable($0) }))
    }
}
