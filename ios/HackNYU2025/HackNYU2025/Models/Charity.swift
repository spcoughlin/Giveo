//
//  Charity.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import Foundation
import FirebaseFirestore
import UIKit
import Combine

class Charity: Identifiable, Codable, Equatable, ObservableObject {
    @DocumentID var id: String?
    let name: String
    let description: String
    let location: String
    
    let heroImageURL: String
    let logoImageURL: String
    
    let primaryTags: [String]?
    let secondaryTags: [String]?
    
    // Temporary storage for raw IDs (these are not published)
    var donationIDs: [String]
    var donorIDs: [String]
    var campaignIDs: [String]
    
    // Public properties to hold full objects.
    @Published var donations: [Donation]
    @Published var donors: [User]
    @Published var campaigns: [Campaign]
    
    @Published var heroImage: UIImage? = nil
    @Published var logoImage: UIImage? = nil

    // MARK: - Computed Properties
    
    /// Returns the total donation amount by summing the amount of each Donation.
    var totalDonationAmount: Double {
        donations.reduce(0.0) { $0 + $1.amount }
    }
    
    /// Returns the number of donations.
    var donationCount: Int {
        donations.count
    }
    
    /// Returns the number of donors.
    var donorCount: Int {
        donors.count
    }
    
    /// Returns the number of campaigns.
    var campaignCount: Int {
        campaigns.count
    }

    // MARK: - Initializer
    init(
        id: String? = nil,
        name: String,
        description: String,
        location: String,
        heroImageURL: String,
        logoImageURL: String,
        primaryTags: [String] = [],
        secondaryTags: [String] = [],
        donationIDs: [String] = [],
        donorIDs: [String] = [],
        campaignIDs: [String] = [],
        donations: [Donation] = [],
        donors: [User] = [],
        campaigns: [Campaign] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.location = location
        self.heroImageURL = heroImageURL
        self.logoImageURL = logoImageURL
        self.primaryTags = primaryTags
        self.secondaryTags = secondaryTags
        self.donationIDs = donationIDs
        self.donorIDs = donorIDs
        self.campaignIDs = campaignIDs
        self.donations = donations
        self.donors = donors
        self.campaigns = campaigns
    }
    
    // MARK: - Custom Decoding to supply defaults for the raw ID arrays.
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.location = try container.decode(String.self, forKey: .location)
        self.heroImageURL = try container.decode(String.self, forKey: .heroImageURL)
        self.logoImageURL = try container.decode(String.self, forKey: .logoImageURL)
        self.primaryTags = try container.decodeIfPresent([String].self, forKey: .primaryTags) ?? []
        self.secondaryTags = try container.decodeIfPresent([String].self, forKey: .secondaryTags) ?? []
        // Decode raw IDs; if missing, default to empty arrays.
        self.donationIDs = try container.decodeIfPresent([String].self, forKey: .donations) ?? []
        self.donorIDs = try container.decodeIfPresent([String].self, forKey: .donors) ?? []
        self.campaignIDs = try container.decodeIfPresent([String].self, forKey: .campaigns) ?? []
        // Start with empty full-object arrays.
        self.donations = []
        self.donors = []
        self.campaigns = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(location, forKey: .location)
        try container.encode(heroImageURL, forKey: .heroImageURL)
        try container.encode(logoImageURL, forKey: .logoImageURL)
        try container.encode(primaryTags, forKey: .primaryTags)
        try container.encode(secondaryTags, forKey: .secondaryTags)
        // Encode the raw IDs.
        try container.encode(donationIDs, forKey: .donations)
        try container.encode(donorIDs, forKey: .donors)
        try container.encode(campaignIDs, forKey: .campaigns)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case location
        case heroImageURL = "heroImage"
        case logoImageURL = "logoImage"
        case primaryTags
        case secondaryTags
        case donations
        case donors
        case campaigns
    }
    
    static func ==(lhs: Charity, rhs: Charity) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.location == rhs.location &&
        lhs.heroImageURL == rhs.heroImageURL &&
        lhs.logoImageURL == rhs.logoImageURL &&
        lhs.primaryTags == rhs.primaryTags &&
        lhs.secondaryTags == rhs.secondaryTags &&
        lhs.donationIDs == rhs.donationIDs &&
        lhs.donorIDs == rhs.donorIDs &&
        lhs.campaignIDs == rhs.campaignIDs
    }
    
    func hasMoreData(than other: Charity) -> Bool {
        return (heroImage != nil && other.heroImage == nil) ||
               (logoImage != nil && other.logoImage == nil) ||
               (description != other.description) ||
               (location != other.location) ||
               ((primaryTags?.count ?? 0) > (other.primaryTags?.count ?? 0))
    }
}
