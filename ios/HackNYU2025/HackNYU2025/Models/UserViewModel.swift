//
//  UserViewModel.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class UserViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var savedCharities: [Charity] = []
    @Published var error: IdentifiableError? = nil
    @Published var isUploadingImage: Bool = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private var listener: ListenerRegistration?

    init() {
        // Observe authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                print("User signed in, fetching data for: \(user.uid)")
                self?.fetchUserData(uid: user.uid)
                print("User signed in, fetched data")
                print("User data: \(String(describing: self?.currentUser))")
            } else {
                self?.currentUser = nil
                self?.listener?.remove()
            }
        }
    }

    deinit {
        listener?.remove()
    }

    /// Fetch user data from Firestore
    func fetchUserData(uid: String) {
        listener = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                print("fetchUserData callback triggered")

                if let error = error {
                    self.error = IdentifiableError(message: "Failed to fetch user data: \(error.localizedDescription)")
                    print("[ERROR] Failed to fetch user data: \(error.localizedDescription)")
                    return
                }

                guard let snapshot = snapshot, snapshot.exists else {
                    self.error = IdentifiableError(message: "User data not found.")
                    print("[ERROR] User data not found.")
                    return
                }

                // Print the raw data for debugging
                if let data = snapshot.data() {
                    print("Snapshot data: \(data)")
                } else {
                    print("Snapshot data is nil.")
                }

                do {
                    let user = try snapshot.data(as: User.self)
                    self.currentUser = user
                    self.error = nil
                    print("Successfully decoded user: \(user)")

                    let savedCharityIDs = user.savedCharityIDs ?? []
                    print("Saved Charity IDs: \(savedCharityIDs)")

                    if !savedCharityIDs.isEmpty {
                        self.fetchSavedCharities(charityIDs: savedCharityIDs)
                    } else {
                        self.savedCharities = []
                        print("No saved charities found.")
                    }
                } catch let decodingError {
                    self.error = IdentifiableError(message: "Failed to decode user data: \(decodingError.localizedDescription)")
                    print("[ERROR] Failed to decode user data: \(decodingError.localizedDescription)")
                }
            }
        }
        
        print("end of fetchUserData")
        print("user data: \(String(describing: self.currentUser))")
    }

    /// Fetch saved charities from Firestore
    private func fetchSavedCharities(charityIDs: [String]) {
        guard !charityIDs.isEmpty else {
            self.savedCharities = []
            return
        }

        db.collection("charities").whereField(FieldPath.documentID(), in: charityIDs).getDocuments { [weak self] querySnapshot, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.error = IdentifiableError(message: "Failed to fetch saved charities: \(error.localizedDescription)")
                    return
                }

                // Convert documents to Charity objects
                self.savedCharities = querySnapshot?.documents.compactMap { doc in
                    try? doc.data(as: Charity.self)
                } ?? []
            }
        }
    }

    /// Update the user's name
    func updateName(newName: String) {
        guard let user = currentUser, let uid = user.id else {
            self.error = IdentifiableError(message: "User not found.")
            return
        }

        db.collection("users").document(uid).updateData(["name": newName]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = IdentifiableError(message: "Failed to update name: \(error.localizedDescription)")
                } else {
                    self?.error = nil
                }
            }
        }
    }

    /// Update the user's email
    func updateEmail(newEmail: String) {
        guard let user = currentUser, let uid = user.id else {
            self.error = IdentifiableError(message: "User not found.")
            return
        }

        Auth.auth().currentUser?.updateEmail(to: newEmail) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = IdentifiableError(message: "Failed to update email: \(error.localizedDescription)")
                } else {
                    // Also update in Firestore
                    self?.db.collection("users").document(uid).updateData(["email": newEmail]) { error in
                        DispatchQueue.main.async {
                            if let error = error {
                                self?.error = IdentifiableError(message: "Failed to update email in Firestore: \(error.localizedDescription)")
                            } else {
                                self?.error = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Updates the user’s profile with the given name, email, and (optionally) a new profile image.
    /// - Parameters:
    ///   - name: The new display name.
    ///   - email: The new email address.
    ///   - newProfileImage: An optional UIImage to use as the new profile image.
    ///   - completion: A completion handler that is called with `true` if all updates succeed, or `false` otherwise.
    func updateUserProfile(name: String, newProfileImage: UIImage?, completion: @escaping (Bool) -> Void) {
        // Ensure we have a valid user.
        guard let user = currentUser, let uid = user.id else {
            print("User not found. Cannot update profile.")
            completion(false)
            return
        }
        
        // Create a dispatch group to wait for all update operations.
        let group = DispatchGroup()
        var overallSuccess = true  // Track if all updates succeed.
        
        // 1. Update the user's name if it has changed.
        if name != user.name {
            group.enter()
            db.collection("users").document(uid).updateData(["name": name]) { error in
                if let error = error {
                    print("Error updating name: \(error.localizedDescription)")
                    overallSuccess = false
                } else {
                    // Optionally, update the local model.
                    self.currentUser?.name = name
                }
                group.leave()
            }
        }
        
        // 3. Update the profile image if a new one is provided.
        if let image = newProfileImage {
            group.enter()
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("Failed to compress image.")
                overallSuccess = false
                group.leave()
                // Note: Returning here would not call group.leave() for other updates.
                // Instead, we mark the update as failed and continue.
                // Alternatively, you might want to call completion(false) immediately.
                // For this example, we'll continue.
                return
            }
            
            // Create a unique image name.
            let imageName = UUID().uuidString + ".jpg"
            let storageRef = storage.reference().child("profile_images/\(uid)/\(imageName)")
            
            // Upload the image to Firebase Storage.
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    overallSuccess = false
                    group.leave()
                } else {
                    // Retrieve the download URL.
                    storageRef.downloadURL { url, error in
                        if let error = error {
                            print("Error retrieving image URL: \(error.localizedDescription)")
                            overallSuccess = false
                        } else if let downloadURL = url?.absoluteString {
                            // Update the user's profileImageURL in Firestore.
                            self.db.collection("users").document(uid).updateData(["profileImageURL": downloadURL]) { error in
                                if let error = error {
                                    print("Error updating profile image URL: \(error.localizedDescription)")
                                    overallSuccess = false
                                } else {
                                    // Optionally, update the local model.
                                    self.currentUser?.profileImageURL = downloadURL
                                }
                                group.leave()
                            }
                        } else {
                            overallSuccess = false
                            group.leave()
                        }
                    }
                }
            }
        }
        
        // Notify the caller once all update operations have finished.
        group.notify(queue: .main) {
            completion(overallSuccess)
        }
    }

    /// Update the user's profile image
    func updateProfileImage(image: UIImage) {
        guard let user = currentUser, let uid = user.id else {
            self.error = IdentifiableError(message: "User not found.")
            return
        }

        self.isUploadingImage = true

        // Convert UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            self.error = IdentifiableError(message: "Failed to compress image.")
            self.isUploadingImage = false
            return
        }

        // Create a unique image name
        let imageName = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("profile_images/\(uid)/\(imageName)")

        // Upload the image to Firebase Storage
        storageRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.error = IdentifiableError(message: "Failed to upload image: \(error.localizedDescription)")
                    self.isUploadingImage = false
                    return
                }

                // Retrieve the download URL
                storageRef.downloadURL { url, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.error = IdentifiableError(message: "Failed to retrieve image URL: \(error.localizedDescription)")
                            self.isUploadingImage = false
                            return
                        }

                        guard let downloadURL = url?.absoluteString else {
                            self.error = IdentifiableError(message: "Invalid image URL.")
                            self.isUploadingImage = false
                            return
                        }

                        // Update the user's profileImageURL in Firestore
                        self.db.collection("users").document(uid).updateData(["profileImageURL": downloadURL]) { error in
                            DispatchQueue.main.async {
                                if let error = error {
                                    self.error = IdentifiableError(message: "Failed to update profile image URL: \(error.localizedDescription)")
                                } else {
                                    self.error = nil
                                    // Optionally, update the currentUser's profileImageURL
                                    self.currentUser?.profileImageURL = downloadURL
                                }
                                self.isUploadingImage = false
                            }
                        }
                    }
                }
            }
        }
    }
}
