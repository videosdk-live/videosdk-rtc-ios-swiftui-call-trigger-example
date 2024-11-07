//
//  NavigationState.swift
//  CallKitSwiftUI
//
//  Created by Uday Gajera on 04/11/24.
//

import SwiftUI

enum AppScreen: Hashable {
    case join
    case calling(userName: String, userNumber: String)
    case meeting(meetingId: String)
}

class NavigationState: ObservableObject {
    static let shared = NavigationState()
    
    @Published var path = NavigationPath()
    @Published var currentScreen: AppScreen = .join
    
    func navigateToCall(userName: String, userNumber: String) {
        currentScreen = .calling(userName: userName, userNumber: userNumber)
        path.append(AppScreen.calling(userName: userName, userNumber: userNumber))
    }
    
    func navigateToMeeting(meetingId: String) {
        currentScreen = .meeting(meetingId: meetingId)
        path.append(AppScreen.meeting(meetingId: meetingId))
    }
    
    func navigateToJoin() {
        path.removeLast(path.count)
        currentScreen = .join
    }
}
