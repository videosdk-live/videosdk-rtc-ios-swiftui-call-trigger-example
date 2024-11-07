//
//  UserData.swift
//  CallKitSwiftUI
//
//  Created by Deep Bhupatkar on 30/07/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseMessaging


class UserData: ObservableObject {
    @Published var callerID: String = "" // Store the caller ID
    @Published public var otherUserID: String = ""
    static let shared = UserData()
    private let callerIDKey = "callerIDKey" // Key for UserDefaults
    let TOKEN_STRING = ""
    
    init() {
        self.callerID = UserDefaults.standard.string(forKey: callerIDKey) ?? ""
    }
    
    // MARK: Generating Unqiue CallerID
    func generateUniqueCallerID() -> String {
        let randomNumber = Int.random(in: 10000...99999)
        print("caller id", randomNumber)
        return String(randomNumber)
    }
    
    // MARK: Check and Register User if Required
    func registerUser(name: String, deviceToken: String, fcmToken: String, completion: @escaping (Bool) -> Void) {
        // First check if user exists with this FCM token
        Firestore.firestore().collection("users")
            .whereField("fcmToken", isEqualTo: fcmToken)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error checking for existing user: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                // If documents exist with this FCM token
                if let snapshot = snapshot, !snapshot.isEmpty {
                    print("User already exists")
                    PushNotificationManager.shared.isRegistering = false
                    completion(false)
                    return
                }
                
                // If no existing user found, create new user
                let callerID = self?.generateUniqueCallerID() ?? ""
                
                DispatchQueue.main.async {
                    self?.callerID = callerID
                    UserDefaults.standard.set(callerID, forKey: self?.callerIDKey ?? "")
                }
                
                Firestore.firestore().collection("users").addDocument(data: [
                    "name": name,
                    "callerID": callerID,
                    "deviceToken": deviceToken,
                    "fcmToken": fcmToken
                ]) { [weak self] error in
                    if let error = error {
                        print("Error adding document: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Document added successfully")
                        self?.storeCallerID(callerID)
                        completion(true)
                    }
                }
            }
    }
    
    // MARK: Fetch CallerID From Defaults
    
    func fetchCallerID() -> String? {
        // Retrieve the caller ID from UserDefaults
        if callerID.isEmpty {
            return UserDefaults.standard.string(forKey: callerIDKey)
        }
        return callerID
    }
    
    // MARK: Store CallerID In Defaults
    
    func storeCallerID(_ callerID: String) {
        // Save the caller ID to UserDefaults
        UserDefaults.standard.set(callerID, forKey: callerIDKey)
        self.callerID = callerID
    }
    
    // MARK: FETCH CALLER INFO
    func fetchCallerInfo(completion: @escaping (CallerInfo?) -> Void) {
        // Get callerID from UserDefaults
        guard let callerIDDevice = UserDefaults.standard.string(forKey: callerIDKey) else {
            print("Caller ID not found in UserDefaults")
            completion(nil)
            return
        }
        print("Retrieved Caller ID from UserDefaults: \(callerIDDevice)")
        // Fetch data from Firestore using the callerID field
        Firestore.firestore().collection("users")
            .whereField("callerID", isEqualTo: callerIDDevice)
            .getDocuments { snapshot, error in
                self.handleFirestoreResponse(snapshot: snapshot, error: error, completion: completion)
            }
    }
    
    
    
    // MARK: FETCH CALLEEEINFO
    func fetchCalleeInfo(callerID: String, completion: @escaping (CalleeInfo?) -> Void) {
        Firestore.firestore().collection("users")
            .whereField("callerID", isEqualTo: callerID)
            .getDocuments { snapshot, error in
                self.handleFirestoreResponse(snapshot: snapshot, error: error, completion: completion)
            }
        
    }
    
    func initiateCall(otherUserID: String, completion: @escaping (CallerInfo?, CalleeInfo?, VideoSDKInfo?) -> Void) {
        fetchCallerInfo { callerInfo in
            guard let callerInfo = callerInfo else {
                print("Error fetching caller info")
                completion(nil, nil, nil)
                return
            }
            
            self.fetchCalleeInfo(callerID: otherUserID) { calleeInfo in
                guard let calleeInfo = calleeInfo else {
                    print("Error fetching callee info")
                    completion(nil, nil, nil)
                    return
                }
                
                // Create meeting before creating VideoSDKInfo
                self.createMeeting(token: "YOUR_VIDEOSDK_TOKEN") { result in
                    switch result {
                    case .success(let roomID):
                        print("Meeting created successfully with Room ID: \(roomID)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            let videoSDKInfo = VideoSDKInfo()
                            
                            // Proceed with the remaining code
                            completion(callerInfo, calleeInfo, videoSDKInfo)
                            
                            // Create a CallRequest
                            let callRequest = CallRequest(callerInfo: callerInfo, calleeInfo: calleeInfo, videoSDKInfo: videoSDKInfo)
                            self.sendCallRequest(callRequest) { result in
                                switch result {
                                case .success(let data):
                                    // Handle successful response
                                    print("Call request successful: \(String(describing: data))")
                                case .failure(let error):
                                    // Handle error
                                    print("Error sending call request: \(error)")
                                }
                            }
                        }
                        
                    case .failure(let error):
                        print("Error creating meeting: \(error)")
                        completion(nil, nil, nil)
                    }
                }
            }
        }
    }
    
    /// MARK: APIs Calls
    
    //MARK:  API Calling For Initiate Call
    public func sendCallRequest(_ request: CallRequest, completion: @escaping (Result<Data?, Error>) -> Void) {
        guard let url = URL(string: "YOUR_SERVER_URL/initiate-call") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                } else if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    completion(.success(data))
                } else {
                    let error = NSError(domain: "API Error", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: nil)
                    completion(.failure(error))
                }
            }
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    public func UpdateCallAPI(callType: String) {
        let storedCallerID = CallingInfo.otherUIDOf ?? "nono"
        print(storedCallerID)
        
        fetchCalleeInfo(callerID: storedCallerID) { calleeInfo in
            guard let calleeInfo = calleeInfo else {
                return
            }
            
            guard let url = URL(string: "YOUR_SERVER_URL/update-call") else {
                print("Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let callerInfoDict: [String: Any] = [
                "id": calleeInfo.id,
                "name": calleeInfo.name,
                "callerID": calleeInfo.callerID,
                "deviceToken": calleeInfo.deviceToken,
                "fcmToken": calleeInfo.fcmToken
            ]
            
            let body: [String: Any] = ["callerInfo": callerInfoDict, "type": callType]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch {
                print("Error encoding request body: \(error)")
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("API call error: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Invalid response")
                    return
                }
                
                if let data = data {
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "")")
                }
            }.resume()
        }
    }
    
    func createMeeting(token: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://api.videosdk.live/v2/rooms")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(token, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let data = data {
                    do {
                        let dataArray = try JSONDecoder().decode(RoomsStruct.self, from: data)
                        let roomID = dataArray.roomID ?? ""
                        // Store the meeting ID
                        CallingInfo.currentMeetingID = roomID
                        completion(.success(roomID))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    let noDataError = NSError(domain: "No data", code: 500, userInfo: nil)
                    completion(.failure(noDataError))
                }
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    
    /// Handles the response from Firestore queries
    private func handleFirestoreResponse<T: Codable>(snapshot: QuerySnapshot?, error: Error?, completion: @escaping (T?) -> Void) {
        if let error = error {
            print("Error fetching documents: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        guard let snapshot = snapshot, !snapshot.isEmpty, let document = snapshot.documents.first else {
            print("No documents found for the given caller ID")
            completion(nil)
            return
        }
        
        let data = document.data()
        let name = data["name"] as? String ?? ""
        let deviceToken = data["deviceToken"] as? String ?? ""
        let callerID = data["callerID"] as? String ?? ""
        let fcmToken = data["fcmToken"] as? String ?? ""
        
        let info = T.self == CallerInfo.self ?
        CallerInfo(id: document.documentID, name: name, callerID: callerID, deviceToken: deviceToken, fcmToken: fcmToken) as? T :
        CalleeInfo(id: document.documentID, name: name, callerID: callerID, deviceToken: deviceToken, fcmToken: fcmToken) as? T
        
        completion(info)
    }
}
