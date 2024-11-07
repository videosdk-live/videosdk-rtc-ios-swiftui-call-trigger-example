//
//  InitiateCallInfo.swift
//  CallKitSwiftUI
//
//  Created by Deep Bhupatkar on 31/07/24.
//

import Foundation

// USER A : the user who Initiate the call to other user (USER B)
struct CallerInfo: Codable {
    let id: String
    let name: String
    let callerID: String
    let deviceToken : String
    let fcmToken : String

}

// USER B : the user who going to recive call from (USER A)
struct CalleeInfo: Codable {
    let id: String
    let name: String
    let callerID: String
    let deviceToken : String
    let fcmToken : String
}

//Meeting Info Can Be Static
struct VideoSDKInfo: Codable {
    var meetingId: String = CallingInfo.currentMeetingID ?? "null"
    var name: String = "VideoSDKExample"
    var callerID: String = "12341241"
    var deviceToken : String = "123412413423"

}

// It Combines all three and sends the information to server.
struct CallRequest: Codable {
    let callerInfo: CallerInfo
    let calleeInfo: CalleeInfo
    let videoSDKInfo: VideoSDKInfo
}



