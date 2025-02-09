//
//  CharitiesManager.swift
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
    
    /// Fetch all charities from Firestore and load their additional data (donations, donors, and campaigns) fully before adding to allCharities.
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
                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    self.isLoading = false
                    self.errorMessage = "No charities found."
                    print(self.errorMessage ?? "")
                    completion?()
                    return
                }
                
                // Use a DispatchGroup to wait for each charity to be fully populated.
                let group = DispatchGroup()
                var loadedCharities: [Charity] = []
                
                for document in documents {
                    group.enter()
                    self.fetchFullyPopulatedCharity(from: document) { charity in
                        if let charity = charity {
                            loadedCharities.append(charity)
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self.allCharities = loadedCharities
                    self.isLoading = false
                    
                    // Optionally fetch images for all charities.
                    self.fetchImagesForCharities()
                    
                    // Initialize the swipe deck by filling it with up to maxCardsInStack charities.
                    self.updateDisplayedCharities()
                    
                    completion?()
                }
            }
        }
    }
    
    func fetchFullyPopulatedCharity(from document: DocumentSnapshot, completion: @escaping (Charity?) -> Void) {
        do {
            var charity = try document.data(as: Charity.self)
            charity.id = document.documentID
            
            // Now load additional data (donations, donors, campaigns) before returning.
            self.loadAdditionalData(for: charity) {
                completion(charity)
            }
        } catch DecodingError.keyNotFound(let key, let context) {
            print("Decoding error: Missing key '\(key.stringValue)' in document \(document.documentID). \(context.debugDescription)")
            completion(nil)
        } catch DecodingError.typeMismatch(let type, let context) {
            print("Decoding error: Type mismatch for type '\(type)' in document \(document.documentID). \(context.debugDescription)")
            completion(nil)
        } catch DecodingError.valueNotFound(let type, let context) {
            print("Decoding error: Value not found for type '\(type)' in document \(document.documentID). \(context.debugDescription)")
            completion(nil)
        } catch {
            print("Error decoding charity from document \(document.documentID): \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    /// Loads additional data for a charity by converting raw ID arrays into full objects.
    func loadAdditionalData(for charity: Charity, completion: @escaping () -> Void) {
        print("running loadAdditionalData")
        guard let _ = charity.id else {
            completion()
            return
        }
        
        let group = DispatchGroup()
        
        // --- Fetch Donations ---
        group.enter()
        if !charity.donationIDs.isEmpty {
            db.collection("donations")
                .whereField(FieldPath.documentID(), in: charity.donationIDs)
                .getDocuments { snapshot, error in
                    if let docs = snapshot?.documents {
                        let donations = docs.compactMap { doc -> Donation? in
                            var donation = try? doc.data(as: Donation.self)
                            donation?.id = doc.documentID
                            return donation
                        }
                        charity.donations = donations
                    } else {
                        charity.donations = []
                    }
                    group.leave()
                }
        } else {
            charity.donations = []
            group.leave()
        }
        
        // --- Fetch Donors ---
        group.enter()
        if !charity.donorIDs.isEmpty {
            db.collection("users")
                .whereField(FieldPath.documentID(), in: charity.donorIDs)
                .getDocuments { snapshot, error in
                    if let docs = snapshot?.documents {
                        let donors = docs.compactMap { doc -> User? in
                            var user = try? doc.data(as: User.self)
                            user?.id = doc.documentID
                            return user
                        }
                        charity.donors = donors
                    } else {
                        charity.donors = []
                    }
                    group.leave()
                }
        } else {
            charity.donors = []
            group.leave()
        }
        
        // --- Fetch Campaigns ---
        group.enter()
        if !charity.campaignIDs.isEmpty {
            db.collection("campaigns")
                .whereField(FieldPath.documentID(), in: charity.campaignIDs)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error fetching campaigns for charity \(charity.name): \(error.localizedDescription)")
                    }
                    let docs = snapshot?.documents ?? []
                    print("Snapshot returned \(docs.count) documents for charity \(charity.name)")
                    let campaigns: [Campaign] = docs.compactMap { doc -> Campaign? in
                        do {
                            var campaign = try doc.data(as: Campaign.self)
                            campaign.id = doc.documentID
                            return campaign
                        } catch {
                            print("Decoding error for campaign document \(doc.documentID): \(error)")
                            return nil
                        }
                    }
                    charity.campaigns = campaigns
                    print("Loaded campaigns: \(campaigns)")
                    group.leave()
                }
        } else {
            charity.campaigns = []
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.objectWillChange.send()
            completion()
        }
    }
    
    func fetchCampaignImage(for campaign: Campaign, completion: @escaping (UIImage?) -> Void) {
        guard let campaignId = campaign.id else { completion(nil); return }
        let imageRef = Storage.storage().reference().child("campaign_images/\(campaignId)/image.jpg")
        imageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                print("Error fetching campaign image for campaign \(campaign.title): \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    /// Fetch charities for the specified array of document IDs.
    /// (Now updated so that each returned charity has its additional data loaded.)
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
                    
                    let charities = querySnapshot?.documents.compactMap { doc -> Charity? in
                        var charity = try? doc.data(as: Charity.self)
                        charity?.id = doc.documentID
                        return charity
                    } ?? []
                    
                    // Load additional data for each charity before returning
                    let group = DispatchGroup()
                    var updatedCharities: [Charity] = []
                    for charity in charities {
                        group.enter()
                        self.loadAdditionalData(for: charity) {
                            updatedCharities.append(charity)
                            group.leave()
                        }
                    }
                    group.notify(queue: .main) {
                        // (Optional) Cache the charities if desired.
                        for charity in updatedCharities {
                            if let id = charity.id {
                                GlobalCache.shared.charityCache[id] = charity
                            }
                        }
                        completion(updatedCharities)
                    }
                }
            }
    }
    
    /// Fetch images for all charities in the allCharities array.
    func fetchImagesForCharities() {
        for (index, charity) in self.allCharities.enumerated() {
            guard charity.id != nil else {
                print("Charity \(charity.name) does not have an ID.")
                continue
            }
            fetchHeroImage(for: charity) { image in
                DispatchQueue.main.async {
                    self.allCharities[index].heroImage = image
                }
            }
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
                GlobalCache.shared.imageCache[id] = updatedCharity.heroImage
            }
            completion(updatedCharity)
        }
    }
    
    func updateDisplayedCharities() {
        print("Updating displayed charities from server...")
        displayedCharities.removeAll()
        isLoading = true
        refillDeckIfNeeded()
    }
    
    private var isProcessingSwipe = false

    func removeDisplayedCharity(_ charity: Charity) {
        guard !isProcessingSwipe else { return }
        isProcessingSwipe = true

        if let topCard = displayedCharities.last, topCard.id == charity.id {
            displayedCharities.removeLast()
            print("Removed top charity: \(charity.name). Deck count: \(displayedCharities.count)")
        } else if let index = displayedCharities.firstIndex(where: { $0.id == charity.id }) {
            displayedCharities.remove(at: index)
            print("Removed charity (non-top): \(charity.name). Deck count: \(displayedCharities.count)")
        } else {
            print("Charity \(charity.name) not found in displayed deck.")
        }
        
        if displayedCharities.isEmpty {
            print("Deck is empty—refreshing entire deck.")
            isLoading = true
            updateDisplayedCharities()
        } else {
            refillDeckIfNeeded()
        }
        
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
    
    /// Fetches the next charities from the API and adds them to the deck.
    /// It queries the `/nextN` endpoint using the authenticated user's id and the number of cards needed.
    func getNextCharity(completion: (() -> Void)? = nil) {
        print("Fetching new charities from API...")
        
        // Ensure an authenticated user is available.
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated; cannot fetch next charities.")
            completion?()
            return
        }
        
        // Determine how many charities are needed to fill the deck.
        let countNeeded = maxCardsInStack - displayedCharities.count
        guard countNeeded > 0 else {
            completion?()
            return
        }
        
        // Construct the URL for the `/nextN` endpoint.
        let apiBaseURL = "http://52.70.58.148" // Replace with your actual API URL
        guard let url = URL(string: "\(apiBaseURL)/nextN?userID=\(userID)&n=\(countNeeded)") else {
            print("Invalid nextN URL.")
            completion?()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Send the request to the API.
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Handle errors from the API call.
            if let error = error {
                print("Error calling nextN API: \(error.localizedDescription)")
                DispatchQueue.main.async { completion?() }
                return
            }
            
            guard let data = data else {
                print("No data received from nextN API.")
                DispatchQueue.main.async { completion?() }
                return
            }
            
            // Debug: Print the raw JSON data received.
            print("Data received from nextN API: \(String(data: data, encoding: .utf8) ?? "No data")")
            
            // Parse the JSON response.
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let charityIds = json["array"] as? [String] {
                    
                    if charityIds.isEmpty {
                        print("nextN API returned an empty array.")
                        DispatchQueue.main.async { completion?() }
                        return
                    }
                    
                    // Fetch the charity documents from Firestore for the returned IDs.
                    self.fetchCharities(with: charityIds) { charities in
                        DispatchQueue.main.async {
                            // Add each charity to the swipe deck if it's not already there.
                            for charity in charities {
                                if !self.displayedCharities.contains(where: { $0.id == charity.id }) {
                                    self.displayedCharities.insert(charity, at: 0)
                                }
                            }
                            print("Added \(charities.count) charities from API to deck.")
                            completion?()
                        }
                    }
                } else {
                    print("Invalid JSON format from nextN API.")
                    DispatchQueue.main.async { completion?() }
                }
            } catch {
                print("Error parsing JSON from nextN API: \(error.localizedDescription)")
                DispatchQueue.main.async { completion?() }
            }
        }.resume()
    }
    
    func updateCharityProfile(charity: Charity,
                              newDescription: String,
                              newLocation: String,
                              newHeroImage: UIImage?,
                              newLogoImage: UIImage?,
                              newPrimaryTags: [String],
                              newSecondaryTags: [String],
                              completion: @escaping (Bool) -> Void) {
        guard let charityID = charity.id else {
            completion(false)
            return
        }
        
        var updates: [String: Any] = [
            "description": newDescription,
            "location": newLocation,
            "primaryTags": newPrimaryTags,
            "secondaryTags": newSecondaryTags
        ]
        
        let group = DispatchGroup()
        
        if let newHero = newHeroImage, let imageData = newHero.jpegData(compressionQuality: 0.8) {
            group.enter()
            let heroRef = storage.reference().child("charity_images/\(charityID)/hero.jpg")
            heroRef.putData(imageData, metadata: nil) { metadata, error in
                if error != nil { group.leave(); return }
                updates["heroImage"] = "hero.jpg"
                group.leave()
            }
        }
        
        if let newLogo = newLogoImage, let imageData = newLogo.jpegData(compressionQuality: 0.8) {
            group.enter()
            let logoRef = storage.reference().child("charity_images/\(charityID)/logo.jpg")
            logoRef.putData(imageData, metadata: nil) { metadata, error in
                if error != nil { group.leave(); return }
                updates["logoImage"] = "logo.jpg"
                group.leave()
            }
        }
        
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
    
    /// Searches for charities based on a query.
    /// (Now updated so that the returned charities have their additional data loaded.)
    func searchCharitiesInFirebase(query: String, completion: @escaping ([Charity]) -> Void) {
        guard !query.isEmpty else {
            completion([])
            return
        }
        
        let query1 = query
        let query2 = query.capitalized
        
        let nameQuery1 = db.collection("charities")
            .whereField("name", isGreaterThanOrEqualTo: query1)
            .whereField("name", isLessThanOrEqualTo: query1 + "\u{f8ff}")
        
        let nameQuery2 = db.collection("charities")
            .whereField("name", isGreaterThanOrEqualTo: query2)
            .whereField("name", isLessThanOrEqualTo: query2 + "\u{f8ff}")
        
        let tagsQuery = db.collection("charities")
            .whereField("primaryTags", arrayContains: query.lowercased())
        
        let group = DispatchGroup()
        var resultsSet = [String: Charity]()
        
        let processSnapshot: (QuerySnapshot?) -> Void = { snapshot in
            if let docs = snapshot?.documents {
                for doc in docs {
                    var charity = try? doc.data(as: Charity.self)
                    charity?.id = doc.documentID
                    if let charity = charity, let id = charity.id {
                        resultsSet[id] = charity
                    }
                }
            }
        }
        
        group.enter()
        nameQuery1.getDocuments { snapshot, error in
            if let error = error {
                print("Error in nameQuery1: \(error.localizedDescription)")
            }
            processSnapshot(snapshot)
            group.leave()
        }
        
        group.enter()
        nameQuery2.getDocuments { snapshot, error in
            if let error = error {
                print("Error in nameQuery2: \(error.localizedDescription)")
            }
            processSnapshot(snapshot)
            group.leave()
        }
        
        group.enter()
        tagsQuery.getDocuments { snapshot, error in
            if let error = error {
                print("Error in tagsQuery: \(error.localizedDescription)")
            }
            processSnapshot(snapshot)
            group.leave()
        }
        
        group.notify(queue: .main) {
            let charities = Array(resultsSet.values)
            let loadGroup = DispatchGroup()
            var updatedCharities: [Charity] = []
            for charity in charities {
                loadGroup.enter()
                self.loadAdditionalData(for: charity) {
                    updatedCharities.append(charity)
                    loadGroup.leave()
                }
            }
            loadGroup.notify(queue: .main) {
                completion(updatedCharities)
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
