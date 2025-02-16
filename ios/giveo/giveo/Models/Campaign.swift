//
//  Campaign.swift
//  swipeapp
//
//  Created by Alec Agayan on [Date]
//

import Foundation
import FirebaseFirestore

struct Campaign: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let charityID: String
    let title: String
    let description: String
    let goal: Double
    let donated: Double
    let imageName: String

}
