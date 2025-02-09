//
//  User.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable, Equatable {
    @DocumentID var id: String? // Firebase UID
    var name: String
    var email: String
    var phoneNumber: String? // Optional phone number
    var charityID: String? // Optional charity ID
    var profileImageURL: String? // Optional profile image URL
    
    /// List of saved charity IDs (stored in Firestore)
    var savedCharityIDs: [String] = []
    
    /// List of saved `Charity` objects (not stored in Firestore, managed in memory)
    var savedCharities: [Charity] = []
    
    /// List of primary charity tags selected by the user
    var primaryTags: [String] = []
    
    // CodingKeys for Firestore encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phoneNumber
        case charityID
        case profileImageURL
        case savedCharityIDs = "savedCharities" // Map Firestore field
        case primaryTags // New field
    }
}
