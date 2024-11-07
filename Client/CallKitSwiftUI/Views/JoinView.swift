//
//  ContentView.swift
//  CallKitSwiftUI
//
//  Created by Deep Bhupatkar on 30/07/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct JoinView: View {
    
    @EnvironmentObject private var userData: UserData
    @EnvironmentObject private var callKitManager: CallKitManager
    @StateObject private var pushNotificationManager = PushNotificationManager.shared
    @EnvironmentObject private var navigationState: NavigationState
    
    @State public var otherUserID: String = ""
    @State private var userName: String = ""
    @State private var userNumber: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Caller ID")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 10) {
                            Text(userData.callerID)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 2)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Enter call ID of another user")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter ID", text: $otherUserID)
                            .foregroundColor(.black)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 2)
                    
                    Button(action: {
                        userData.initiateCall(otherUserID: otherUserID) { callerInfo, calleeInfo, videoSDKInfo in
                            print("Initiating call to \(calleeInfo?.name ?? "Unknown")")
                            self.userName = calleeInfo?.name ?? "Unknown"
                            self.userNumber = calleeInfo?.callerID ?? "Unknown"
                            navigationState.navigateToCall(userName: self.userName, userNumber: self.userNumber)
                        }
                    }) {
                        HStack {
                            Text("Start Call")
                            Image(systemName: "phone.circle.fill")
                                .imageScale(.large)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.trailing)
                    
                    Spacer()
                    
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.05, green: 0.05, blue: 0.05))
                .edgesIgnoringSafeArea(.all)
                
                if pushNotificationManager.isRegistering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4))
                }
            }
            .onAppear {
                userData.fetchCallerID()
                NotificationCenter.default.addObserver(forName: .callAnswered, object: nil, queue: .main) { _ in
                    if let meetingId = CallingInfo.currentMeetingID {
                        navigationState.navigateToMeeting(meetingId: meetingId)
                    }
                }
            }
        }
    }
}
