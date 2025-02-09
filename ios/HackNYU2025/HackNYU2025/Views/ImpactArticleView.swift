//
//  ImpactArticleView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct ImpactArticleView: View {
    var article: ImpactArticle
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Article header.
                Text(article.title)
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 4)
                Text(article.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                // Render each content block.
                ForEach(article.blocks) { block in
                    switch block.type {
                    case .text(let content):
                        // Using SwiftUI’s Markdown support.
                        Text(.init(content))
                            .font(.body)
                    case .image(let name, let caption):
                        VStack {
                            Image(name)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                            if !caption.isEmpty {
                                Text(caption)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ImpactArticleView_Previews: PreviewProvider {
    static var previews: some View {
        ImpactArticleView(article: ImpactArticle(title: "New Shelter Opens Its Doors",
                                                  subtitle: "A new beginning for those in need.",
                                                  thumbnailImageName: "whitehouseHero",
                                                  blocks: [
                                                    ArticleBlock(type: .text("Today marks the opening of a state-of-the-art shelter.")),
                                                    ArticleBlock(type: .image(name: "whitehouseHero", caption: "The newly opened shelter at dusk."))
                                                  ]))
    }
}
