//
//  TokenManager.swift
//  CallKitSwiftUI
//
//  Created by Deep Bhupatkar on 07/08/24.
//

import Foundation

struct CallingInfo {
    static var deviceToken: String?
    static var fcmTokenOfDevice: String?
    static var otherUIDOf: String?
    static var currentMeetingID: String? {
        get {
            return UserDefaults.standard.string(forKey: "currentMeetingID")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "currentMeetingID")
        }
    }
}

