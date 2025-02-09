//
//  DonationManager.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import Foundation
import FirebaseFirestore
import Combine

class DonationManager: ObservableObject {
    @Published var donations: [DonationDisplay] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()
    
    // Optionally, if you want to use common functions from CharitiesManager:
    var charityManager: CharitiesManager?
    
    /// Fetch donations for a given user from the "donations" collection.
    func fetchDonations(for userID: String, completion: (() -> Void)? = nil) {
        print("Fetching donations for userID: \(userID)")
        isLoading = true
        errorMessage = nil
        
        // Query the "donations" collection directly where the field "userID" matches.
        let donationsRef = db.collection("donations").whereField("userID", isEqualTo: userID)
        donationsRef.getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error fetching donations: \(error.localizedDescription)"
                    self.isLoading = false
                    completion?()
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "No donation documents found."
                    self.isLoading = false
                    completion?()
                    return
                }
                
                let fetchedDonations: [Donation] = documents.compactMap { doc in
                    do {
                        var donation = try doc.data(as: Donation.self)
                        donation.id = doc.documentID
                        print("Decoded donation: \(donation)")
                        return donation
                    } catch {
                        print("Error decoding donation document \(doc.documentID): \(error)")
                        return nil
                    }
                }
                
                // Map each Donation to a DonationDisplay using charity details from GlobalCache.
                let displayDonations: [DonationDisplay] = fetchedDonations.map { donation in
                    let charity = GlobalCache.shared.charityCache[donation.charityID]
                    let charityName = charity?.name ?? "Unknown Charity"
                    let charityDescription = charity?.description ?? ""
                    return DonationDisplay(
                        id: donation.id ?? UUID().uuidString,
                        charityName: charityName,
                        charityDescription: charityDescription,
                        amount: donation.amount
                    )
                }
                
                self.donations = displayDonations
                self.isLoading = false
                print("Final display donations: \(displayDonations)")
                completion?()
            }
        }
    }
    
    /// Fetch donations for a specific charity.
    func fetchDonationsForCharity(_ charityID: String, completion: (() -> Void)? = nil) {
        isLoading = true
        errorMessage = nil
        
        // Query the "donations" collection where "charityID" equals the provided charityID.
        db.collection("donations")
            .whereField("charityID", isEqualTo: charityID)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let error = error {
                        self.errorMessage = "Error fetching donations: \(error.localizedDescription)"
                        self.isLoading = false
                        completion?()
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        self.errorMessage = "No donation documents found."
                        self.isLoading = false
                        completion?()
                        return
                    }
                    
                    let fetchedDonations: [Donation] = documents.compactMap { doc in
                        do {
                            var donation = try doc.data(as: Donation.self)
                            donation.id = doc.documentID
                            return donation
                        } catch {
                            print("Error decoding donation document \(doc.documentID): \(error)")
                            return nil
                        }
                    }
                    
                    // Map each Donation to a DonationDisplay using charity details from GlobalCache.
                    let displayDonations: [DonationDisplay] = fetchedDonations.map { donation in
                        let charity = GlobalCache.shared.charityCache[donation.charityID]
                        let charityName = charity?.name ?? "Unknown Charity"
                        let charityDescription = charity?.description ?? ""
                        return DonationDisplay(
                            id: donation.id ?? UUID().uuidString,
                            charityName: charityName,
                            charityDescription: charityDescription,
                            amount: donation.amount
                        )
                    }
                    
                    self.donations = displayDonations
                    self.isLoading = false
                    completion?()
                }
            }
    }
    
    /// (Optional) Update a donation display if its associated charity isn’t already in cache.
    func updateDonationForCharity(_ donation: Donation, completion: @escaping (DonationDisplay) -> Void) {
        if let charity = GlobalCache.shared.charityCache[donation.charityID] {
            let donationDisplay = DonationDisplay(
                id: donation.id ?? UUID().uuidString,
                charityName: charity.name,
                charityDescription: charity.description,
                amount: donation.amount
            )
            completion(donationDisplay)
        } else if let charityManager = charityManager {
            charityManager.fetchCharities(with: [donation.charityID]) { fetchedCharities in
                let charity = fetchedCharities.first
                let name = charity?.name ?? "Unknown Charity"
                let description = charity?.description ?? ""
                let donationDisplay = DonationDisplay(
                    id: donation.id ?? UUID().uuidString,
                    charityName: name,
                    charityDescription: description,
                    amount: donation.amount
                )
                completion(donationDisplay)
            }
        } else {
            let donationDisplay = DonationDisplay(
                id: donation.id ?? UUID().uuidString,
                charityName: "Unknown Charity",
                charityDescription: "",
                amount: donation.amount
            )
            completion(donationDisplay)
        }
    }
}

extension DonationManager {
    /// Adds a donation to Firestore and updates the charity and user documents.
    /// - Parameters:
    ///   - donation: The Donation object to add.
    ///   - charity: The charity receiving the donation.
    ///   - user: The current user making the donation.
    ///   - completion: A closure that returns true if all updates succeed, false otherwise.
    func addDonation(donation: Donation, for charity: Charity, forUser user: User, completion: @escaping (Bool) -> Void) {
        // Create a new donation document with an auto-generated ID.
        let donationRef = db.collection("donations").document()
        let donationID = donationRef.documentID
        
        // Create a dictionary representation of the donation.
        // We add a server timestamp so the donation time is set by the server.
        let donationData: [String: Any] = [
            "userID": donation.userID,
            "charityID": donation.charityID,
            "amount": donation.amount,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        donationRef.setData(donationData) { error in
            if let error = error {
                print("Error adding donation: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Update the charity document: add the donation ID to its donationIDs array.
            self.db.collection("charities").document(charity.id!).updateData([
                "donations": FieldValue.arrayUnion([donationID])
            ]) { charityError in
                if let charityError = charityError {
                    print("Error updating charity with donation: \(charityError.localizedDescription)")
                    completion(false)
                    return
                }
                
                // Update the user document: add the donation ID to the user's donationIDs array.
                self.db.collection("users").document(user.id!).updateData([
                    "donationIDs": FieldValue.arrayUnion([donationID])
                ]) { userError in
                    if let userError = userError {
                        print("Error updating user with donation: \(userError.localizedDescription)")
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }
}
