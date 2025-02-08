//
//  CharitiesManager.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/8/25.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Combine
import UIKit

class CharitiesManager: ObservableObject {
    // All charities fetched from Firestore.
    @Published var allCharities: [Charity] = []
    // Live queue of charities for swipe display.
    @Published var displayedCharities: [Charity] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    let db = Firestore.firestore()
    let storage = Storage.storage()
    var listenerRegistration: ListenerRegistration?
    
    // Maximum number of cards in the swipe deck.
    private let maxCardsInStack = 3
    
    // MARK: - Fetching Charities
    
    /// Fetch all charities from Firestore.
    func fetchCharities(completion: (() -> Void)? = nil) {
        isLoading = true
        errorMessage = nil

        db.collection("charities").getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = "Error fetching charities: \(error.localizedDescription)"
                    print(self.errorMessage ?? "")
                    completion?()
                    return
                }
                guard let documents = querySnapshot?.documents else {
                    self.isLoading = false
                    self.errorMessage = "No charities found."
                    print(self.errorMessage ?? "")
                    completion?()
                    return
                }
                // Decode charities and update list & cache.
                let fetchedCharities = documents.compactMap { document -> Charity? in
                    var charity = try? document.data(as: Charity.self)
                    if var charity = charity {
                        charity.id = document.documentID // Ensure the ID is set
                        if let cached = GlobalCache.shared.charityCache[charity.id!] {
                            // Update if this version has more data.
                            if charity.hasMoreData(than: cached) {
                                GlobalCache.shared.charityCache[charity.id!] = charity
                                return charity
                            } else {
                                return cached
                            }
                        } else {
                            GlobalCache.shared.charityCache[charity.id!] = charity
                            return charity
                        }
                    }
                    return nil
                }
                
                self.allCharities = fetchedCharities
                self.isLoading = false
                
                // Optionally fetch images for all charities.
                self.fetchImagesForCharities()
                
                // Initialize the swipe deck by filling it with 3 random cards.
                self.updateDisplayedCharities()
                
                completion?()
            }
        }
    }
    
    /// Fetch charities for the specified array of document IDs.
    func fetchCharities(with ids: [String], completion: @escaping ([Charity]) -> Void) {
        guard !ids.isEmpty else {
            completion([])
            return
        }
        
        db.collection("charities")
            .whereField(FieldPath.documentID(), in: ids)
            .getDocuments { [weak self] querySnapshot, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.errorMessage = "Failed to fetch charity details: \(error.localizedDescription)"
                        print(self.errorMessage ?? "")
                        completion([])
                        return
                    }
                    
                    let fetched = querySnapshot?.documents.compactMap { doc -> Charity? in
                        var charity = try? doc.data(as: Charity.self)
                        charity?.id = doc.documentID
                        if let id = charity?.id {
                            GlobalCache.shared.charityCache[id] = charity
                        }
                        return charity
                    } ?? []
                    
                    completion(fetched)
                }
            }
    }
    
    /// (Common) Fetch images for all charities in the allCharities array.
    func fetchImagesForCharities() {
        for (index, charity) in self.allCharities.enumerated() {
            guard charity.id != nil else {
                print("Charity \(charity.name) does not have an ID.")
                continue
            }
            // Fetch Hero Image.
            fetchHeroImage(for: charity) { image in
                DispatchQueue.main.async {
                    self.allCharities[index].heroImage = image
                }
            }
            // Fetch Logo Image.
            fetchLogoImage(for: charity) { image in
                DispatchQueue.main.async {
                    self.allCharities[index].logoImage = image
                }
            }
        }
    }
    
    // MARK: - Image Fetching Methods
    
    func fetchHeroImage(for charity: Charity, completion: @escaping (UIImage?) -> Void) {
        guard let charityId = charity.id else { completion(nil); return }
        let heroKey = "hero_\(charityId)"
        if let cachedImage = GlobalCache.shared.imageCache[heroKey] {
            completion(cachedImage)
            return
        }
        let heroRef = storage.reference().child("charity_images/\(charityId)/\(charity.heroImageURL)")
        heroRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    GlobalCache.shared.imageCache[heroKey] = image
                    completion(image)
                }
            } else {
                print("Error fetching hero image for \(charity.name): \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    func fetchLogoImage(for charity: Charity, completion: @escaping (UIImage?) -> Void) {
        guard let charityId = charity.id else { completion(nil); return }
        let logoKey = "logo_\(charityId)"
        if let cachedImage = GlobalCache.shared.imageCache[logoKey] {
            completion(cachedImage)
            return
        }
        let logoRef = storage.reference().child("charity_images/\(charityId)/\(charity.logoImageURL)")
        logoRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    GlobalCache.shared.imageCache[logoKey] = image
                    completion(image)
                }
            } else {
                print("Error fetching logo image for \(charity.name): \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    /// Fetch both images for a single charity.
    func fetchImages(for charity: Charity, completion: @escaping (Charity?) -> Void) {
        var updatedCharity = charity
        let group = DispatchGroup()
        
        group.enter()
        fetchHeroImage(for: charity) { image in
            updatedCharity.heroImage = image
            group.leave()
        }
        
        group.enter()
        fetchLogoImage(for: charity) { image in
            updatedCharity.logoImage = image
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let id = updatedCharity.id {
                GlobalCache.shared.charityCache[id] = updatedCharity
            }
            completion(updatedCharity)
        }
    }
    
    func updateDisplayedCharities() {
        print("Updating displayed charities from server...")
        displayedCharities.removeAll()
        // When refreshing the entire deck, show the loading indicator.
        isLoading = true
        refillDeckIfNeeded()
    }
    
    private var isProcessingSwipe = false

    func removeDisplayedCharity(_ charity: Charity) {
        // Prevent duplicate removals by checking the flag.
        guard !isProcessingSwipe else { return }
        isProcessingSwipe = true

        // Remove the card if it's the top card (assuming the last element is the top).
        if let topCard = displayedCharities.last, topCard.id == charity.id {
            displayedCharities.removeLast()
            print("Removed top charity: \(charity.name). Deck count: \(displayedCharities.count)")
        } else if let index = displayedCharities.firstIndex(where: { $0.id == charity.id }) {
            displayedCharities.remove(at: index)
            print("Removed charity (non-top): \(charity.name). Deck count: \(displayedCharities.count)")
        } else {
            print("Charity \(charity.name) not found in displayed deck.")
        }
        
        // Decide whether to refill the deck.
        if displayedCharities.isEmpty {
            print("Deck is empty—refreshing entire deck.")
            isLoading = true
            updateDisplayedCharities()
        } else {
            refillDeckIfNeeded()
        }
        
        // Allow subsequent swipes after this one is processed.
        isProcessingSwipe = false
    }
    
    private var isFetchingNextCharity = false

    func refillDeckIfNeeded() {
        guard displayedCharities.count < maxCardsInStack, !isFetchingNextCharity else { return }
        isFetchingNextCharity = true
        getNextCharity { [weak self] in
            guard let self = self else { return }
            self.isFetchingNextCharity = false
            if self.displayedCharities.count < self.maxCardsInStack {
                self.refillDeckIfNeeded()
            }
        }
    }
    
    /// Fetches a random charity from the server and adds it to the bottom of the deck.
    /// Fetches a random charity from the server and adds it to the bottom of the deck.
    func getNextCharity(completion: (() -> Void)? = nil) {
        print("Fetching new charity from server...")
        db.collection("charities").getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching charity for next card: \(error.localizedDescription)")
                    completion?()
                    return
                }
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No charities available from server.")
                    completion?()
                    return
                }
                
                // Filter out charities that are already in the displayed deck.
                let displayedIds = Set(self.displayedCharities.compactMap { $0.id })
                let filteredDocuments = documents.filter { !displayedIds.contains($0.documentID) }
                
                if filteredDocuments.isEmpty {
                    print("All charities are already in the deck. No new charity to add.")
                    completion?()
                    return
                }
                
                // Pick a random charity from the filtered list.
                let randomIndex = Int.random(in: 0..<filteredDocuments.count)
                let randomDoc = filteredDocuments[randomIndex]
                var charity = try? randomDoc.data(as: Charity.self)
                charity?.id = randomDoc.documentID
                guard let charityToAdd = charity else {
                    print("Error decoding charity from document.")
                    completion?()
                    return
                }
                
                self.fetchImages(for: charityToAdd) { updatedCharity in
                    DispatchQueue.main.async {
                        if let charity = updatedCharity {
                            // Insert the new charity at index 0 (i.e. at the bottom of the deck).
                            self.displayedCharities.insert(charity, at: 0)
                            print("Added charity: \(charity.name). Deck count is now: \(self.displayedCharities.count)")
                            
                            // --- NEW CODE: Print the current queue ---
                            let queueNames = self.displayedCharities.map { $0.name }
                            print("Current queue: \(queueNames)")
                            // --------------------------------------------
                            
                            // If the deck is now full, hide the loading indicator.
                            if self.displayedCharities.count >= self.maxCardsInStack {
                                self.isLoading = false
                            }
                        } else {
                            print("Error: Failed to fetch images for charity \(charityToAdd.name)")
                        }
                        completion?()
                    }
                }
            }
        }
    }
    
    func updateCharityProfile(charity: Charity,
                              newDescription: String,
                              newLocation: String,
                              newHeroImage: UIImage?,
                              newLogoImage: UIImage?,
                              completion: @escaping (Bool) -> Void) {
        guard let charityID = charity.id else {
            completion(false)
            return
        }
        
        // Prepare the fields to update in Firestore.
        var updates: [String: Any] = [
            "description": newDescription,
            "location": newLocation
        ]
        
        let group = DispatchGroup()
        
        // Upload new hero image if provided.
        if let newHero = newHeroImage,
           let imageData = newHero.jpegData(compressionQuality: 0.8) {
            group.enter()
            let heroRef = storage.reference().child("charity_images/\(charityID)/hero.jpg")
            heroRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading hero image: \(error.localizedDescription)")
                    group.leave()
                    return
                }
                // Update the Firestore field to use the fixed file name.
                updates["heroImage"] = "hero.jpg"
                print("updated hero")
                group.leave()
            }
        }
        
        // Upload new logo image if provided.
        if let newLogo = newLogoImage,
           let imageData = newLogo.jpegData(compressionQuality: 0.8) {
            group.enter()
            let logoRef = storage.reference().child("charity_images/\(charityID)/logo.jpg")
            logoRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading logo image: \(error.localizedDescription)")
                    group.leave()
                    return
                }
                updates["logoImage"] = "logo.jpg"
                print("updated logo")
                group.leave()
            }
        }
        
        // Once all image uploads are complete, update Firestore.
        group.notify(queue: .main) {
            self.db.collection("charities").document(charityID).updateData(updates) { error in
                if let error = error {
                    print("Error updating charity profile: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Charity profile updated successfully.")
                    completion(true)
                }
            }
        }
    }
    

    /// Resets all local caches and state.
    func reset() {
        allCharities.removeAll()
        displayedCharities.removeAll()
        errorMessage = nil
        isLoading = false
    }
    
    /// (Optional) Prints the global cache size.
    func printCacheSize() {
        var size = 0
        for (key, value) in GlobalCache.shared.charityCache {
            size += key.count
            size += value.name.count
            size += value.description.count
            size += value.heroImageURL.count
            size += value.logoImageURL.count
            size += value.heroImage?.jpegData(compressionQuality: 1)?.count ?? 0
            size += value.logoImage?.jpegData(compressionQuality: 1)?.count ?? 0
        }
        print("GlobalCache size: \(size) bytes")
    }
}
