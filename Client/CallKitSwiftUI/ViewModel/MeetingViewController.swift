//
//  MeetingViewController.swift
//  CallKitSwiftUI
//
//  Created by Deep Bhupatkar on 02/08/24.
//

import Foundation
import VideoSDKRTC
import WebRTC

class MeetingViewController: ObservableObject {
    
    var token = "YOUR_VIDEOSDK_TOKEN"
    var meetingId: String = ""
    var name: String = ""
    
    @Published var meeting: Meeting? = nil
    @Published var localParticipantView: VideoView? = nil
    @Published var videoTrack: RTCVideoTrack?
    @Published var participants: [Participant] = []
    @Published var meetingID: String = ""
    
    func initializeMeeting(meetingId: String, userName: String) {
        
        meeting = VideoSDK.initMeeting(
            meetingId: CallingInfo.currentMeetingID!,
            participantName: "iPhone",
            micEnabled: true,
            webcamEnabled: true
        )
        
        meeting?.addEventListener(self)
        meeting?.join()
    }
}

extension MeetingViewController: MeetingEventListener {
    
    func onMeetingJoined() {
        
        guard let localParticipant = self.meeting?.localParticipant else { return }
        
        // add to list
        participants.append(localParticipant)
        
        // add event listener
        localParticipant.addEventListener(self)
        
        localParticipant.setQuality(.high)
    }
    
    func onParticipantJoined(_ participant: Participant) {
        
        participants.append(participant)
        
        // add listener
        participant.addEventListener(self)
        
        participant.setQuality(.high)
    }
    
    func onParticipantLeft(_ participant: Participant) {
        participants = participants.filter({ $0.id != participant.id })
    }
    
    func onMeetingLeft() {
        meeting?.localParticipant.removeEventListener(self)
        meeting?.removeEventListener(self)
        NavigationState.shared.navigateToJoin()
        CallKitManager.shared.endCall()
    }
    
    func onMeetingStateChanged(meetingState: MeetingState) {
        switch meetingState {
            
        case .CLOSED:
            participants.removeAll()
            
        default:
            print("")
        }
    }
}

extension MeetingViewController: ParticipantEventListener {
    func onStreamEnabled(_ stream: MediaStream, forParticipant participant: Participant) {
        
        if participant.isLocal {
            if let track = stream.track as? RTCVideoTrack {
                DispatchQueue.main.async {
                    self.videoTrack = track
                }
            }
        } else {
            if let track = stream.track as? RTCVideoTrack {
                DispatchQueue.main.async {
                    self.videoTrack = track
                }
            }
        }
    }
    
    func onStreamDisabled(_ stream: MediaStream, forParticipant participant: Participant) {
        
        if participant.isLocal {
            if let _ = stream.track as? RTCVideoTrack {
                DispatchQueue.main.async {
                    self.videoTrack = nil
                }
            }
        } else {
            self.videoTrack = nil
        }
    }
}

extension MeetingViewController {
    
    // initialise a meeting with give meeting id (either new or existing)
    func joinMeeting(meetingId: String, userName: String) {
        
        if !token.isEmpty {
            // use provided token for the meeting
            self.meetingID = meetingId
            self.initializeMeeting(meetingId: meetingId, userName: userName)
        }
        else {
            print("Auth token required")
        }
    }
}
