//
//  ImpactArticle.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import Foundation

struct ImpactArticle: Identifiable {
    let id = UUID().uuidString
    let title: String
    let subtitle: String       // A short excerpt or summary.
    let thumbnailImageName: String  // Thumbnail image asset name.
    let blocks: [ArticleBlock] // The content blocks of the article.
}

struct ArticleBlock: Identifiable {
    let id = UUID()
    let type: BlockType
    
    enum BlockType {
        case text(String)               // Markdown-enabled text.
        case image(name: String, caption: String)
    }
}
