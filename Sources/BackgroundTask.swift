
public protocol BackgroundTaskHandler {
    func beginBackgroundTask() -> Any
    func endBackgroundTask(with id: Any)
}

#if os(iOS)

import UIKit
public extension UIApplication: BackgroundTask {
    func beginBackgroundTask() -> Any {
        return self.beginBackgroundTask(expirationHandler: nil)
    }

    func endBackgroundTask(with id: Any) {
        if let id = id as? UIBackgroundTaskIdentifier {
            self.endBackgroundTask(id)
        }
    }
}

#endif
