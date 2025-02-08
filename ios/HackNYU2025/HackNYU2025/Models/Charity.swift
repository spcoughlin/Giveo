//
//  Charity.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/8/25.
//

import Foundation
import FirebaseFirestore
import UIKit
import Combine

class Charity: Identifiable, Codable, Equatable, ObservableObject {
    @DocumentID var id: String? // Firebase UID
    let name: String
    let description: String
    let location: String       // REPLACED: A real location string (e.g. "New York, NY")
    
    let heroImageURL: String   // Filename for hero image
    let logoImageURL: String   // Filename for logo image
    
    let primaryTags: [String]? // New property for primary tags

    // Image properties – marked as @Published so changes are observed.
    @Published var heroImage: UIImage? = nil
    @Published var logoImage: UIImage? = nil

    // Explicit initializer
    init(
        id: String? = nil,
        name: String,
        description: String,
        location: String,         // Use a real location instead of a boolean
        heroImageURL: String,
        logoImageURL: String,
        primaryTags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.location = location
        self.heroImageURL = heroImageURL
        self.logoImageURL = logoImageURL
        self.primaryTags = primaryTags
    }

    // CodingKeys to exclude image properties from Codable (if using Firestore’s Codable support)
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case location
        case heroImageURL = "heroImage"
        case logoImageURL = "logoImage"
        case primaryTags
    }
    
    static func ==(lhs: Charity, rhs: Charity) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.location == rhs.location &&
        lhs.heroImageURL == rhs.heroImageURL &&
        lhs.logoImageURL == rhs.logoImageURL &&
        lhs.primaryTags == rhs.primaryTags
    }
    
    func hasMoreData(than other: Charity) -> Bool {
        return (heroImage != nil && other.heroImage == nil) ||
               (logoImage != nil && other.logoImage == nil) ||
               (description != other.description) ||
               (location != other.location) ||       // Check if location data has changed.
               ((primaryTags?.count ?? 0) > (other.primaryTags?.count ?? 0))
    }
}
