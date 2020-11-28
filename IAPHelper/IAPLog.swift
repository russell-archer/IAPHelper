//
//  IAPLog.swift
//  IAPHelper
//
//  Created by Russell Archer on 25/06/2020.
//

import Foundation
import os.log

/// We use Apple's unified logging system to log errors, notifications and general messages.
/// This system works on simulators and real devices for both debug and release builds.
/// You can view the logs in the Console app by selecting the test device in the left console pane.
/// If running on the simulator, select the machine the simulator is running on. Type your app's
/// bundle identifier into the search field and then narrow the results by selecting "SUBSYSTEM"
/// from the search field's filter. Logs also appear in Xcode's console in the same manner as
/// print statements.
///
/// When running the app on a real device that's not attached to the Xcode debugger,
/// dynamic strings (i.e. the error, event or message parameter you send to the event() function)
/// will not be publicly viewable. They're automatically redacted with the word "private" in the
/// console. This prevents the accidental logging of potentially sensistive user data. Because
/// we know in advance that the IAPReceiptError and IAPNotificaton enums do NOT contain
/// sensitive information, we let the unified logging system know it's OK to log these strings
/// through the use of the "%{public}s" keyword. However, we don't know what the event(message:)
/// function will be used to display, so its logs will be redacted.
public struct IAPLog {
    private static let iapLog = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "IAP")
    
    /// Logs an IAPNotification. Note that the text (shortDescription) of the log entry will be
    /// publically available in the Console app.
    /// - Parameter event: An IAPNotification.
    public static func event(_ event: IAPNotification) {
        #if DEBUG
        print(event.shortDescription())
        #else
        os_log("%{public}s", log: iapLog, type: .default, event.shortDescription())
        #endif
    }
    
    /// Logs an IAPNotification. Note that the text (shortDescription) and the productId for the
    /// log entry will be publically available in the Console app.
    /// - Parameters:
    ///   - event:      An IAPNotification.
    ///   - productId:  A ProductId associated with the event.
    public static func event(_ event: IAPNotification, productId: ProductId) {
        #if DEBUG
        print("\(event.shortDescription()) for product \(productId)")
        #else
        os_log("%{public}s for product %{public}s", log: iapLog, type: .default, event.shortDescription(), productId)
        #endif
    }
    
    /// Logs a message.
    /// - Parameter message: The message to log.
    public static func event(_ message: String) {
        #if DEBUG
        print(message)
        #else
        os_log("%s", log: iapLog, type: .info, message)
        #endif
    }
}

