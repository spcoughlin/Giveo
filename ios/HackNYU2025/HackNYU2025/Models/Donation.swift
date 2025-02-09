//
//  Donation.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import Foundation
import FirebaseFirestore

// This model mirrors the Firestore donation document.
struct Donation: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let charityID: String
    let userID: String
    let amount: Double
}

// This model is used for display in the UI.
struct DonationDisplay: Identifiable {
    let id: String
    let charityName: String
    let charityDescription: String
    let amount: Double
}
