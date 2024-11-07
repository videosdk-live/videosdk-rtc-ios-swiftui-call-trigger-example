////
////  AppDelegate.swift
////  CallKitSwiftUI
////
////  Created by Deep Bhupatkar on 31/07/24.
////

import UIKit
import FirebaseMessaging
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UIApplication.shared.applicationIconBadgeNumber = 0
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
         // Set the APNS token for Firebase Messaging
         Messaging.messaging().apnsToken = deviceToken

         // Convert and log token
         let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
         print("APNS token: \(tokenString)")
         
     }
     
     func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
         print("Failed to register for remote notifications: \(error.localizedDescription)")
     }
}

extension Notification.Name {
    static let callAnswered = Notification.Name("callAnswered")
}
