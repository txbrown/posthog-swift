
public protocol BackgroundTaskHandler {
    func beginBackgroundTask() -> Any
    func endBackgroundTask(with id: Any)
}

#if os(iOS)

import UIKit
extension UIApplication: BackgroundTaskHandler {
    public func beginBackgroundTask() -> Any {
        return self.beginBackgroundTask(expirationHandler: nil)
    }

    public func endBackgroundTask(with id: Any) {
        if let id = id as? UIBackgroundTaskIdentifier {
            self.endBackgroundTask(id)
        }
    }
}

#endif
