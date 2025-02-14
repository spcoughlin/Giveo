//
//  CampaignManager.swift
//  swipeapp
//
//  Created by Alec Agayan on [Date]
//

import Foundation
import FirebaseFirestore
import Combine

class CampaignManager: ObservableObject {
    @Published var campaigns: [Campaign] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let db = Firestore.firestore()
    
    /// Fetch all campaigns from Firestore.
    func fetchAllCampaigns(completion: (() -> Void)? = nil) {
        isLoading = true
        errorMessage = nil
        
        db.collection("campaigns").getDocuments { [weak self] (querySnapshot, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error fetching campaigns: \(error.localizedDescription)"
                    self.isLoading = false
                    completion?()
                    return
                }
                
                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    self.errorMessage = "No campaigns found."
                    self.isLoading = false
                    completion?()
                    return
                }
                
                self.campaigns = documents.compactMap { document in
                    var campaign = try? document.data(as: Campaign.self)
                    campaign?.id = document.documentID // Ensure the ID is set.
                    return campaign
                }
                self.isLoading = false
                completion?()
            }
        }
    }
    
    /// Fetch campaigns for a specific charity.
    func fetchCampaigns(for charityID: String, completion: (() -> Void)? = nil) {
        isLoading = true
        errorMessage = nil
        
        db.collection("campaigns")
            .whereField("charityID", isEqualTo: charityID)
            .getDocuments { [weak self] (querySnapshot, error) in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.errorMessage = "Error fetching campaigns for charity: \(error.localizedDescription)"
                        self.isLoading = false
                        completion?()
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                        self.errorMessage = "No campaigns found for this charity."
                        self.isLoading = false
                        completion?()
                        return
                    }
                    
                    self.campaigns = documents.compactMap { document in
                        var campaign = try? document.data(as: Campaign.self)
                        campaign?.id = document.documentID
                        return campaign
                    }
                    self.isLoading = false
                    completion?()
                }
            }
    }
}
