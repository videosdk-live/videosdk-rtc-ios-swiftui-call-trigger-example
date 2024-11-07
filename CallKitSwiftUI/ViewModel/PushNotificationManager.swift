//
//  PushKitManager.swift
//  CallKitSwiftUI
//
//  Created by Uday Gajera on 29/10/24.
//

import Foundation
import UserNotifications
import FirebaseMessaging
import PushKit
import UIKit
import SwiftUI

class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()
    
    @Published var fcmToken: String?
    private var voipRegistry: PKPushRegistry?
    private var deviceToken: String?
    private var isFcmTokenAvailable: Bool = false
    private var isDeviceTokenAvailable: Bool = false
    @Published var isRegistering: Bool = false
    private var callStatus: String?
    
    override private init() {
        super.init()
        setupNotifications()
        setupVoIP()
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func setupVoIP() {
        voipRegistry = PKPushRegistry(queue: .main)
        voipRegistry?.delegate = self
        voipRegistry?.desiredPushTypes = [.voIP]
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        if let callStatus = userInfo["type"] as? String {
            self.callStatus = callStatus
        }
        
        handleFcmNotification()
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Notification received with userInfo: \(userInfo)")
        
        handleFcmNotification()
        completionHandler()
    }
    
    private func handleFcmNotification() {
        if callStatus == "ACCEPTED" {
            DispatchQueue.main.async {
                      if let meetingId = CallingInfo.currentMeetingID {
                          NavigationState.shared.navigateToMeeting(meetingId: meetingId)
                      }
            }
        } else {
            DispatchQueue.main.async {
                CallKitManager.shared.endCall()
                NavigationState.shared.navigateToJoin()
            }
        }
    }
    
}

// MARK: - MessagingDelegate
extension PushNotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.fcmToken = fcmToken
        CallingInfo.fcmTokenOfDevice = fcmToken
        self.isFcmTokenAvailable = true
        
        self.isRegistering = true
        // Register user if both tokens are available
        if self.isDeviceTokenAvailable && self.isFcmTokenAvailable {
            guard let deviceToken = deviceToken,
                  let fcmToken = fcmToken else { return }
            registerUser(deviceToken: deviceToken, fcmToken: fcmToken)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                guard let self = self,
                      let deviceToken = deviceToken,
                      let fcmToken = fcmToken else { return }
                
                if self.isDeviceTokenAvailable && self.isFcmTokenAvailable {
                    self.registerUser(deviceToken: deviceToken, fcmToken: fcmToken)
                } else {
                    self.isRegistering = false
                }
            }
        }
    }
}

// MARK: - PKPushRegistryDelegate
extension PushNotificationManager: PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        CallingInfo.deviceToken = token
        self.deviceToken = token
        self.isDeviceTokenAvailable = true
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("Push token invalidated for type: \(type)")
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        // Handle VoIP push notification
        handleVoIPPushPayload(payload)
        completion()
    }
    
    private func handleVoIPPushPayload(_ payload: PKPushPayload) {
        let payloadDict = payload.dictionaryPayload
        guard let callerInfo = payloadDict["callerInfo"] as? [String: Any],
              let callerName = callerInfo["name"] as? String,
              let callerID = callerInfo["callerID"] as? String,
              let videoSDKInfo = payloadDict["videoSDKInfo"] as? [String: Any],
              let meetingId = videoSDKInfo["meetingId"] as? String else {
            return
        }
        
        CallingInfo.otherUIDOf = callerID
        CallingInfo.currentMeetingID = meetingId
        
        CallKitManager.shared.reportIncomingCall(callerName: callerName, meetingId: meetingId)
    }
}

extension PushNotificationManager {
    
    private func registerUser(deviceToken: String, fcmToken: String) {
        let name = UIDevice.current.name
        UserData.shared.registerUser(name: name, deviceToken: deviceToken, fcmToken: fcmToken) { success in
            if success {
                print("user stored")
                self.isRegistering = false
            }
        }
    }
}
