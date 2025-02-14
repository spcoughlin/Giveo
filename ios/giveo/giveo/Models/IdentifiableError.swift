//
//  IdentifiableError.swift
//  swipeapp
//
//  Created by Alec Agayan on 1/19/25.
//

import Foundation

struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}
