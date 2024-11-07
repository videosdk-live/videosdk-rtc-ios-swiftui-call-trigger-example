//
//  MeetingView.swift
//  CallKitSwiftUI
//
//  Created by Deep Bhupatkar on 02/08/24.
//

import SwiftUI
import VideoSDKRTC
import WebRTC

struct MeetingView: View{
    
    @ObservedObject var meetingViewController = MeetingViewController()
    
    // Variables for keeping the state of various controls
    @State var meetingId: String?
    @State var userName: String? = "Demo"
    @State var isUnMute: Bool = true
    @State var camEnabled: Bool = true
    @State var isScreenShare: Bool = false
    
    var userData = UserData()
    
    var body: some View {
        
        VStack {
            if meetingViewController.participants.count == 0 {
                Text("Meeting Initializing")
            } else {
                VStack {
                    VStack(spacing: 20) {
                        Text("Meeting ID: \(CallingInfo.currentMeetingID!)")
                            .padding(.vertical)
                        
                        List {
                            ForEach(meetingViewController.participants.indices, id: \.self) { index in
                                Text("Participant Name: \(meetingViewController.participants[index].displayName)")
                                ZStack {
                                    ParticipantView(track: meetingViewController.participants[index].streams.first(where: { $1.kind == .state(value: .video) })?.value.track as? RTCVideoTrack).frame(height: 250)
                                    if meetingViewController.participants[index].streams.first(where: { $1.kind == .state(value: .video) }) == nil {
                                        Color.white.opacity(1.0).frame(width: UIScreen.main.bounds.width, height: 250)
                                        Text("No media")
                                    }
                                }
                            }
                        }
                    }
                    
                    VStack {
                        HStack(spacing: 15) {
                            // mic button
                            Button {
                                if isUnMute {
                                    isUnMute = false
                                    meetingViewController.meeting?.muteMic()
                                }
                                else {
                                    isUnMute = true
                                    meetingViewController.meeting?.unmuteMic()
                                }
                            } label: {
                                Text("Toggle Mic")
                                    .foregroundStyle(Color.white)
                                    .font(.caption)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.blue))
                            }
                            // camera button
                            Button {
                                if camEnabled {
                                    camEnabled = false
                                    meetingViewController.meeting?.disableWebcam()
                                }
                                else {
                                    camEnabled = true
                                    meetingViewController.meeting?.enableWebcam()
                                }
                            } label: {
                                Text("Toggle WebCam")
                                    .foregroundStyle(Color.white)
                                    .font(.caption)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.blue))
                            }
                        }
                        HStack{
                            // screenshare button (OPTIONAL)
                            Button {
                                if isScreenShare {
                                    isScreenShare = false
                                    Task {
                                        await meetingViewController.meeting?.disableScreenShare()
                                    }
                                }
                                else {
                                    isScreenShare = true
                                    Task {
                                        await meetingViewController.meeting?.enableScreenShare()
                                    }
                                }
                            } label: {
                                Text("Toggle ScreenShare")
                                    .foregroundStyle(Color.white)
                                    .font(.caption)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.blue))
                            }
                            
                            // end meeting button
                            Button {
                                meetingViewController.meeting?.end()
                                NavigationState.shared.navigateToJoin()
                                CallKitManager.shared.endCall()
                                
                            } label: {
                                Text("End Call")
                                    .foregroundStyle(Color.white)
                                    .font(.caption)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.red))
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }
        }.onAppear()
        {
            /// MARK :- configuring the videoSDK
            VideoSDK.config(token: meetingViewController.token)
            if meetingId?.isEmpty == false {
                // join an existing meeting with provided meeting Id
                meetingViewController.joinMeeting(meetingId: meetingId!, userName: userName!)
            }
            else {
            }
        }
    }    

}

/// VideoView for participant's video
class VideoView: UIView {
    
    var videoView: RTCMTLVideoView = {
        let view = RTCMTLVideoView()
        view.videoContentMode = .scaleAspectFill
        view.backgroundColor = UIColor.black
        view.clipsToBounds = true
        view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 250)
        
        return view
    }()
    
    init(track: RTCVideoTrack?) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 250))
        backgroundColor = .clear
        DispatchQueue.main.async {
            self.addSubview(self.videoView)
            self.bringSubviewToFront(self.videoView)
            track?.add(self.videoView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// ParticipantView for showing and hiding VideoView
struct ParticipantView: UIViewRepresentable {
    var track: RTCVideoTrack?
    
    func makeUIView(context: Context) -> VideoView {
        let view = VideoView(track: track)
        view.frame = CGRect(x: 0, y: 0, width: 250, height: 250)
        return view
    }
    
    func updateUIView(_ uiView: VideoView, context: Context) {
        if track != nil {
            track?.add(uiView.videoView)
        } else {
            track?.remove(uiView.videoView)
        }
    }
}
