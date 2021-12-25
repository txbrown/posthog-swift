import UIKit
import WatchKit

//TODO: Adjust for other platforms
struct Device {
    static var model: String {
#if targetEnvironment(macCatalyst)
        return ProcessInfo.model
#else
        return Device.modelName
#endif
    }
    
    static var type: String {
#if targetEnvironment(macCatalyst)
        return "Mac"
#elseif os(watchOS)
        return WKInterfaceDevice.current().model
#else
        return UIDevice.current.model
#endif
    }
    
    static var system: String {
#if targetEnvironment(macCatalyst)
        return "macOS"
#elseif os(watchOS)
        return WKInterfaceDevice.current().systemName
        
#else
        return UIDevice.current.systemName
#endif
    }
    
    static var systemVersion: String {
#if targetEnvironment(macCatalyst)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
#elseif os(watchOS)
        return WKInterfaceDevice.current().systemVersion
#else
        return UIDevice.current.systemVersion
#endif
    }
    
    static var screenSize: CGSize {
#if os(macOS)
        return NSScreen.screens.first?.visibleFrame.size ?? .zero
#elseif os(watchOS)
        return WKInterfaceDevice.current().screenBounds.size
#else
        return UIScreen.main.bounds.size
#endif
        
    }
}

#if targetEnvironment(macCatalyst)

import IOKit
import AppKit

extension ProcessInfo {
    static let modelName: String = {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                  IOServiceMatching("IOPlatformExpertDevice"))
        var modelIdentifier: String?
        if let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
            modelIdentifier = String(data: modelData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
        }
        
        IOObjectRelease(service)
        return modelIdentifier ?? "macOS"
    }()
    
    static let model: String = {
        if modelName.hasPrefix("iMacPro") {
            return "iMac Pro"
        } else if modelName.hasPrefix("iMac") {
            return "iMac"
        } else if modelName.hasPrefix("Macmini") {
            return "Mac mini"
        } else if modelName.hasPrefix("MacPro") {
            return "Mac Pro"
        } else if modelName.hasPrefix("MacBookPro") {
            return "MacBook Pro"
        } else if modelName.hasPrefix("MacBookAir") {
            return "MacBook Air"
        } else if modelName.hasPrefix("MacBook") {
            return "MacBook"
        } else {
            return "Mac"
        }
    }()
    
    static let systemName: String = {
        var sysinfo = utsname()
        let result = uname(&sysinfo)
        guard result == EXIT_SUCCESS else { return "macOS (unknown)" }
        let data = Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN))
        guard let identifier = String(bytes: data, encoding: .ascii) else { return "macOS (unknown)" }
        let arch = identifier.trimmingCharacters(in: .controlCharacters)
        switch arch {
        case "arm64": return "macOS (Apple Silicon)"
        case "x86_64": return "macOS (Intel)"
        default: return "macOS (\(arch))"
        }
    }()
}

#else

extension Device {
    //Source: https://github.com/devicekit/DeviceKit/blob/master/Source/Device.generated.swift
    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
#if os(iOS)
            switch identifier {
            case "iPod5,1": return "iPod touch (5th generation)"
            case "iPod7,1": return "iPod touch (6th generation)"
            case "iPod9,1": return "iPod touch (7th generation)"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3": return "iPhone 4"
            case "iPhone4,1": return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2": return "iPhone 5"
            case "iPhone5,3", "iPhone5,4": return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2": return "iPhone 5s"
            case "iPhone7,2": return "iPhone 6"
            case "iPhone7,1": return "iPhone 6 Plus"
            case "iPhone8,1": return "iPhone 6s"
            case "iPhone8,2": return "iPhone 6s Plus"
            case "iPhone8,4": return "iPhone SE"
            case "iPhone9,1", "iPhone9,3": return "iPhone 7"
            case "iPhone9,2", "iPhone9,4": return "iPhone 7 Plus"
            case "iPhone10,1", "iPhone10,4": return "iPhone 8"
            case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6": return "iPhone X"
            case "iPhone11,2": return "iPhone XS"
            case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
            case "iPhone11,8": return "iPhone XR"
            case "iPhone12,1": return "iPhone 11"
            case "iPhone12,3": return "iPhone 11 Pro"
            case "iPhone12,5": return "iPhone 11 Pro Max"
            case "iPhone12,8": return "iPhone SE (2nd generation)"
            case "iPhone13,1": return "iPhone 12 mini"
            case "iPhone13,2": return "iPhone 12"
            case "iPhone13,3": return "iPhone 12 Pro"
            case "iPhone13,4": return "iPhone 12 Pro Max"
            case "iPhone14,5": return "iPhone 13"
            case "iPhone14,4": return "iPhone 13 mini"
            case "iPhone14,2": return "iPhone 13 Pro"
            case "iPhone14,3": return "iPhone 13 Pro Max"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3": return "iPad (3rd generation)"
            case "iPad3,4", "iPad3,5", "iPad3,6": return "iPad (4th generation)"
            case "iPad6,11", "iPad6,12": return "iPad (5th generation)"
            case "iPad7,5", "iPad7,6": return "iPad (6th generation)"
            case "iPad7,11", "iPad7,12": return "iPad (7th generation)"
            case "iPad11,6", "iPad11,7": return "iPad (8th generation)"
            case "iPad4,1", "iPad4,2", "iPad4,3": return "iPad Air"
            case "iPad5,3", "iPad5,4": return "iPad Air 2"
            case "iPad11,3", "iPad11,4": return "iPad Air (3rd generation)"
            case "iPad13,1", "iPad13,2": return "iPad Air (4th generation)"
            case "iPad2,5", "iPad2,6", "iPad2,7": return "iPad mini"
            case "iPad4,4", "iPad4,5", "iPad4,6": return "iPad mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9": return "iPad mini 3"
            case "iPad5,1", "iPad5,2": return "iPad mini 4"
            case "iPad11,1", "iPad11,2": return "iPad mini (5th generation)"
            case "iPad6,3", "iPad6,4": return "iPad Pro (9.7-inch)"
            case "iPad7,3", "iPad7,4": return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": return "iPad Pro (11-inch) (1st generation)"
            case "iPad8,9", "iPad8,10": return "iPad Pro (11-inch) (2nd generation)"
            case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7" : return "iPad Pro (11-inch) (3rd generation)"
            case "iPad6,7", "iPad6,8": return "iPad Pro (12.9-inch) (1st generation)"
            case "iPad7,1", "iPad7,2": return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8": return "iPad Pro (12.9-inch) (3rd generation)"
            case "iPad8,11", "iPad8,12": return "iPad Pro (12.9-inch) (4th generation)"
            case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro (12.9-inch) (5th generation)"
            case "AppleTV5,3": return "Apple TV"
            case "AppleTV6,2": return "Apple TV 4K"
            case "AudioAccessory1,1": return "HomePod"
            case "i386", "x86_64":
                let device = mapToDevice(identifier: ProcessInfo()
                                            .environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS")
                return "Simulator \(device)"
            default: return identifier
            }
#elseif os(watchOS)
            switch identifier {
            case "Watch1,1", "Watch1,2": return "Apple Watch (1st generation)"
            case "Watch2,6", "Watch2,7": return "Apple Watch Series 1"
            case "Watch2,3", "Watch2,4": return "Apple Watch Series 2"
            case "Watch3,1", "Watch3,2", "Watch3,3", "Watch3,4": return "Apple Watch Series 3"
            case "Watch4,1", "Watch4,2", "Watch4,3", "Watch4,4": return "Apple Watch Series 4"
            case "Watch5,1", "Watch5,2", "Watch5,3", "Watch5,4": return "Apple Watch Series 5"
            case "Watch5,10", "Watch5,11", "Watch5,12": return "Apple Watch SE"
            case "Watch6,1", "Watch6,2", "Watch6,3", "Watch6,4": return "Apple Watch Series 6"
            case "i386", "x86_64":
                let device = mapToDevice(identifier: ProcessInfo()
                                            .environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS")
                return "Simulator \(device)"
            default: return identifier
            }
#elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "AppleTV11,1": return "Apple TV 4K (2nd generation)"
            case "i386", "x86_64":
                let device = mapToDevice(identifier: ProcessInfo()
                                            .environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS")
                return "Simulator \(device)"
            default: return identifier
            }
#endif
        }
        
        return mapToDevice(identifier: identifier)
    }()
}
#endif

