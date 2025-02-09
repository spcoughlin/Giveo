//
//  IdentifiableError.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import Foundation

struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}
