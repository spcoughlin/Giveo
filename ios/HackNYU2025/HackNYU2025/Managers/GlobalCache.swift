//
//  GlobalCache.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/8/25.
//

import UIKit

class GlobalCache {
    static let shared = GlobalCache() // Singleton instance

    private init() {} // Private initializer to prevent instantiation

    var charityCache: [String: Charity] = [:] // Cache for charity objects
    var imageCache: [String: UIImage] = [:]  // Cache for images
    
    func reset() {
        charityCache.removeAll()
        imageCache.removeAll()
    }
}
