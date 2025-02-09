//
//  SavedCharitiesManager.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Combine
import UIKit

class SavedCharitiesManager: ObservableObject {
    @Published var savedCharities: [Charity] = []
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()
    // Although SavedCharitiesManager has its own storage reference,
    // it will delegate common operations to commonManager.
    private let storage = Storage.storage()
    private var userID: String?
    
    // An instance of the common manager to delegate shared functions.
    private let commonManager = CharitiesManager()
    
    init(userID: String?) {
        self.userID = userID
        fetchSavedCharities()
    }
    
    func setUserID(_ userID: String?) {
        self.userID = userID
        fetchSavedCharities()
    }
    
    // MARK: - Saved-Specific Operations
    
    /// Add a charity to the saved list in Firestore.
    func addCharity(_ charity: Charity) {
        guard let userID = Auth.auth().currentUser?.uid, let charityID = charity.id else {
            self.errorMessage = "User or charity ID is invalid."
            return
        }
        
        db.collection("users").document(userID).updateData([
            "savedCharities": FieldValue.arrayUnion([charityID])
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to add charity: \(error.localizedDescription)"
                } else {
                    self?.updateSavedCharities(with: charity)
                    print("Charity \(charity.name) added to saved charities.")
                }
            }
        }
    }
    
    /// Remove a charity from the saved list in Firestore.
    func removeCharity(_ charity: Charity) {
        guard let userID = Auth.auth().currentUser?.uid, let charityID = charity.id else {
            self.errorMessage = "User or charity ID is invalid."
            print("[ERROR] Cannot remove charity: User or charity ID is invalid.")
            return
        }
        
        // Optimistically update the savedCharities array.
        DispatchQueue.main.async {
            self.savedCharities.removeAll { $0.id == charity.id }
        }
        
        db.collection("users").document(userID).updateData([
            "savedCharities": FieldValue.arrayRemove([charityID])
        ]) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to remove charity: \(error.localizedDescription)"
                    print("[ERROR] \(self.errorMessage ?? "")")
                    // Revert removal on failure.
                    self.savedCharities.append(charity)
                }
            } else {
                print("[DEBUG] Charity \(charity.name) successfully removed from Firestore.")
            }
        }
    }
    
    /// Fetch saved charity IDs for the current user and update savedCharities.
    func fetchSavedCharities() {
        guard let userID = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User is not authenticated."
            return
        }
        
        db.collection("users").document(userID).getDocument { [weak self] documentSnapshot, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Failed to fetch saved charities: \(error.localizedDescription)"
                    return
                }
                
                guard let document = documentSnapshot, document.exists,
                      let data = document.data(),
                      let savedCharityIDs = data["savedCharities"] as? [String] else {
                    self.savedCharities = []
                    return
                }
                
                self.fetchCharitiesByIDsOrCache(savedCharityIDs)
            }
        }
    }
    
    /// For each saved charity ID, use the cache if available;
    /// otherwise fetch from Firestore and update using commonManager’s methods.
    private func fetchCharitiesByIDsOrCache(_ ids: [String]) {
        var charitiesToFetch: [String] = []
        for id in ids {
            if let cached = GlobalCache.shared.charityCache[id] {
                // If images are missing, use the common manager to fetch them.
                if cached.heroImage == nil {
                    commonManager.fetchHeroImage(for: cached) { image in
                        DispatchQueue.main.async {
                            cached.heroImage = image
                        }
                    }
                }
                if cached.logoImage == nil {
                    commonManager.fetchLogoImage(for: cached) { image in
                        DispatchQueue.main.async {
                            cached.logoImage = image
                        }
                    }
                }
                // Update our saved charities array.
                self.updateSavedCharities(with: cached)
            } else {
                charitiesToFetch.append(id)
            }
        }
        
        // If any charities were not found in cache, fetch them.
        if !charitiesToFetch.isEmpty {
            commonManager.fetchCharities(with: charitiesToFetch) { fetched in
                // For each newly fetched charity, fetch images.
                fetched.forEach { charity in
                    self.commonManager.fetchHeroImage(for: charity) { _ in }
                    self.commonManager.fetchLogoImage(for: charity) { _ in }
                    self.updateSavedCharities(with: charity)
                }
            }
        }
    }
    
    /// Update the saved charities array and global cache.
    private func updateSavedCharities(with charity: Charity) {
        if let index = savedCharities.firstIndex(where: { $0.id == charity.id }) {
            // Directly update the properties on the existing instance.
            let existing = savedCharities[index]
            // Only update if the new data is available.
            if let newHeroImage = charity.heroImage {
                existing.heroImage = newHeroImage
            }
            if let newLogoImage = charity.logoImage {
                existing.logoImage = newLogoImage
            }
            // No need to replace the object in the array.
            GlobalCache.shared.charityCache[charity.id!] = existing
        } else {
            savedCharities.append(charity)
            if let id = charity.id {
                GlobalCache.shared.charityCache[id] = charity
            }
            commonManager.printCacheSize()
        }
    }
    
    func reset() {
        savedCharities.removeAll()
        errorMessage = nil
    }
}
