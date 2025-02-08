//
//  AuthViewModel.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/8/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String? = nil
    
//    var charitiesManager: CharitiesManager?
//    var savedManager: SavedCharitiesManager?
    
    private let db = Firestore.firestore()
    
    init() {
        // Listen to authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.errorMessage = nil
            }
        }
    }
    
    /// Sign In Method
    func signIn(email: String, password: String) {
        self.errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isAuthenticated = false
                } else {
                    self.isAuthenticated = true
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
                
                // Create a new user record in Firestore
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
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// (Optional) For Apple Sign-In, etc.
    func signInWithApple(credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { [weak self] _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isAuthenticated = false
                } else {
                    self.isAuthenticated = true
                }
            }
        }
    }
}
