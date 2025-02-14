//
//  CampaignCardView.swift
//  swipeapp
//
//  Created by Alec Agayan on 2/8/25.
//

import SwiftUI

struct CampaignCardView: View {
    var campaign: Campaign
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "whitehouseHero")
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .clipped()
                .cornerRadius(8)
            
            Text(campaign.title)
                .font(.headline)
                .lineLimit(2)
            
            // A donation progress indicator.
            ProgressView(value: campaign.donated / campaign.goal)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
            
            HStack {
                Text("$\(Int(campaign.donated)) raised")
                    .font(.caption)
                Spacer()
                Text("Goal: $\(Int(campaign.goal))")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}

//struct CampaignCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        CampaignCardView(campaign: Campaign(title: "Food for All",
//                                            imageName: "campaignPlaceholder",
//                                            progress: 0.7,
//                                            goal: 10000,
//                                            donated: 7000))
//            .previewLayout(.sizeThatFits)
//            .padding()
//    }
//}
