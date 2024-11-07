//
//  CallingView.swift
//  CallKitSwiftUI
//
//  Created by Deep Bhupatkar on 30/07/24.
//

import SwiftUI

struct CallingView: View {
    var userNumber: String
    var userName: String

    @EnvironmentObject private var navigationState: NavigationState

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                HStack(alignment: .center) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(userName)
                            .font(.largeTitle)
                            .foregroundColor(.white)

                        Text(userNumber)
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                Text("Calling...")
                    .font(.title2)
                    .foregroundColor(.gray)

                Spacer()

                Button(action: {
                    UserData.shared.UpdateCallAPI(callType: "REJECTED")
                    navigationState.navigateToJoin()
                }) {
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .padding(.bottom, 50)
            }
            .padding(.horizontal, 30)
        }
    }
}
