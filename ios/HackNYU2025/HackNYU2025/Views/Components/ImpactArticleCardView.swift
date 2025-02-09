//
//  ImpactArticleCardView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct ImpactArticleCardView: View {
    var article: ImpactArticle
    
    var body: some View {
        HStack(spacing: 16) {
            Image(article.thumbnailImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 80)
                .clipped()
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(article.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}

struct ImpactArticleCardView_Previews: PreviewProvider {
    static var previews: some View {
        ImpactArticleCardView(article: ImpactArticle(title: "Community Meal Brings Neighbors Together",
                                                      subtitle: "A heartwarming story of unity and support.",
                                                      thumbnailImageName: "storyPlaceholder",
                                                      blocks: [
                                                        ArticleBlock(type: .text("**Breaking News:** Today, the community gathered for a meal.")),
                                                        ArticleBlock(type: .image(name: "communityMeal", caption: "Residents enjoying a shared meal."))
                                                      ]))
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
