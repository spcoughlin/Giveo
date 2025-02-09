//
//  ImpactArticleFeedView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct ImpactArticleFeedView: View {
    // Dummy data for demonstration.
    // In production, load your articles from a backend (e.g., Firestore).
    let articles: [ImpactArticle] = [
        ImpactArticle(title: "Community Meal Brings Neighbors Together",
                      subtitle: "A heartwarming story of unity and support.",
                      thumbnailImageName: "storyPlaceholder",
                      blocks: [
                        ArticleBlock(type: .text("**Breaking News:** Today, the community gathered for a meal.")),
                        ArticleBlock(type: .image(name: "communityMeal", caption: "Residents enjoying a shared meal."))
                      ]),
        ImpactArticle(title: "New Shelter Opens Its Doors",
                      subtitle: "A new beginning for those in need.",
                      thumbnailImageName: "whitehouseHero",
                      blocks: [
                        ArticleBlock(type: .text("Today marks the opening of a state-of-the-art shelter.")),
                        ArticleBlock(type: .image(name: "whitehouseHero", caption: "The newly opened shelter at dusk."))
                      ])
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ForEach(articles) { article in
                        NavigationLink(destination: ImpactArticleView(article: article)) {
                            ImpactArticleBigCardView(article: article)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Impact Articles")
        }
    }
}

struct ImpactArticleFeedView_Previews: PreviewProvider {
    static var previews: some View {
        ImpactArticleFeedView()
    }
}
