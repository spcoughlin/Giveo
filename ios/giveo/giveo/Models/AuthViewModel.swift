//
//  AuthViewModel.swift
//  swipeapp
//
//  Created by Alec Agayan on 1/17/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String? = nil
    
    var charitiesManager: CharitiesManager?
    var savedManager: SavedCharitiesManager?
    
    private let db = Firestore.firestore()
    
    // Set your API base URL (adjust as needed)
    private let apiBaseURL = "http://52.70.58.148" // Replace with your API base URL

    init() {
        // Listen to authentication state changes.
        // You can call logOn here if a user is already authenticated.
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.errorMessage = nil
                if let user = user {
                    self?.logOnToAPI(userID: user.uid)
                }
            }
        }
    }
    
    // MARK: - API Call Helper
    
    /// Calls the /logOn endpoint, passing in the authenticated user's id.
    private func logOnToAPI(userID: String) {
        // Construct the URL with the userID query parameter.
        guard let url = URL(string: "\(apiBaseURL)/logOn?userID=\(userID)") else {
            print("Invalid logOn URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Send the request.
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error calling logOn API: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("logOn API response status: \(httpResponse.statusCode)")
            }
            // Optionally, you can parse `data` if your endpoint returns JSON.
        }.resume()
    }
    
    // MARK: - Authentication Methods

    /// Sign In Method
    func signIn(email: String, password: String) {
        self.errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isAuthenticated = false
                } else if let user = result?.user {
                    self.isAuthenticated = true
                    // On successful sign in, call the logOn API with the user id.
                    self.logOnToAPI(userID: user.uid)
                    print("CALLING LOG ON")
                }
            }
        }
    }
    
    /// Sign Up Method
    func signUp(email: String, password: String, name: String) {
        self.errorMessage = nil
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isAuthenticated = false
                    return
                }
                
                guard let user = result?.user else {
                    self.errorMessage = "User data not available."
                    self.isAuthenticated = false
                    return
                }
                
                // Create a new user record in Firestore.
                let newUser = User(
                    id: user.uid,
                    name: name,
                    email: email,
                    phoneNumber: nil, // Default to nil
                    charityID: nil
                )
                
                do {
                    try self.db.collection("users").document(user.uid).setData(from: newUser) { error in
                        if let error = error {
                            self.errorMessage = "Failed to create user data: \(error.localizedDescription)"
                            self.isAuthenticated = false
                        } else {
                            self.isAuthenticated = true
                            // On successful sign up, call the logOn API with the user id.
                            self.logOnToAPI(userID: user.uid)
                        }
                    }
                } catch let encodingError {
                    self.errorMessage = "Failed to encode user data: \(encodingError.localizedDescription)"
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    /// Sign Out Method
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isAuthenticated = false
            
            // Reset global cache if you have one.
            GlobalCache.shared.reset()
            
            // Reset per-user managers.
            charitiesManager?.reset()
            savedManager?.reset()
            
            // Optionally, you could also call a logOff endpoint here.
            // self.logOffFromAPI(userID: currentUserId)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// (Optional) For Apple Sign-In, etc.
    func signInWithApple(credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isAuthenticated = false
                } else if let user = result?.user {
                    self.isAuthenticated = true
                    // Call logOn after successful Apple sign-in.
                    self.logOnToAPI(userID: user.uid)
                }
            }
        }
    }
}
