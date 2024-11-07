//
//  CallKitSwiftUIApp.swift
//  CallKitSwiftUI
//
//  Created by Deep Bhupatkar on 30/07/24.
//

import SwiftUI
import FirebaseCore

@main
struct CallKitSwiftUIApp: App {
    @StateObject private var userData = UserData.shared
    @StateObject private var callKitManager = CallKitManager.shared
    @StateObject private var navigationState = NavigationState.shared
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationState.path) {
                JoinView()
                    .navigationDestination(for: AppScreen.self) { screen in
                        switch screen {
                        case .join:
                            JoinView()
                        case .calling(let userName, let userNumber):
                            CallingView(userNumber: userNumber, userName: userName)
                        case .meeting(let meetingId):
                            MeetingView(meetingId: meetingId)
                        }
                    }
            }
            .environmentObject(userData)
            .environmentObject(callKitManager)
            .environmentObject(navigationState)
        }
    }
}

