//
//  CallKitManager.swift
//  CallKitSwiftUI
//
//  Created by Uday Gajera on 29/10/24.
//

import CallKit
import AVFoundation

class CallKitManager: NSObject, ObservableObject, CXProviderDelegate {
    
    static let shared = CallKitManager()
    
    private var provider: CXProvider
    private var callController: CXCallController
    @Published var callerIDs: [UUID: String] = [:]
    @Published var meetingIDs = [UUID: String]()
    
    override private init() {
        provider = CXProvider(configuration: CXProviderConfiguration(localizedName: "In CallKitSwiftUI"))
        callController = CXCallController()
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    func reportIncomingCall(callerName: String, meetingId: String) {
        let uuid = UUID()
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callerName)
        update.localizedCallerName = callerName
        
        callerIDs[uuid] = callerName
        meetingIDs[uuid] = meetingId
        
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print("Error reporting incoming call: \(error)")
            }
        }
    }
    
    func endCall() {
        // End all active calls
        for (uuid, _) in callerIDs {
            let endCallAction = CXEndCallAction(call: uuid)
            let transaction = CXTransaction(action: endCallAction)
            
            callController.request(transaction) { error in
                if let error = error {
                    print("Error ending call: \(error.localizedDescription)")
                } else {
                    print("Call ended successfully")
                }
            }
        }
    }
    
    // CXProviderDelegate methods
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        configureAudioSession()
        let update = CXCallUpdate()
        update.remoteHandle = action.handle
        update.localizedCallerName = action.handle.value
        provider.reportCall(with: action.callUUID, updated: update)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        configureAudioSession()
        if let callerID = callerIDs[action.callUUID] {
            print("Establishing call connection with caller ID: \(callerID)")
        }
        NotificationCenter.default.post(name: .callAnswered, object: nil)
        UserData.shared.UpdateCallAPI(callType: "ACCEPTED")
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        callerIDs.removeValue(forKey: action.callUUID)
        let meetingViewController = MeetingViewController()
        meetingViewController.onMeetingLeft()
        action.fulfill()
        UserData.shared.UpdateCallAPI(callType: "REJECTED")
        DispatchQueue.main.async {
            NavigationState.shared.navigateToJoin()
        }
    }
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: .allowBluetooth)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func providerDidReset(_ provider: CXProvider) {
        callerIDs.removeAll()
    }
}
