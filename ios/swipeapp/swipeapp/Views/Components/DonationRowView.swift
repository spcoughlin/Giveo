//
//  DonationRow.swift
//  swipeapp
//
//  Created by Alec Agayan on 1/16/25.
//

import SwiftUI

struct DonationRowView: View {
    let donation: DonationDisplay
    let isShinyNumbersEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "gift.fill")
                        .foregroundColor(.accentColor)
                )
            
            // Donation info using the charity details
            VStack(alignment: .leading) {
                Text(donation.charityName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(donation.charityDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Conditionally show shiny or regular text
            if isShinyNumbersEnabled {
                ShinyText(
                    text: String(format: "$%.2f", donation.amount),
                    font: .title,
                    weight: .bold
                )
            } else {
                Text(String(format: "$%.2f", donation.amount))
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
        .padding(.horizontal)
    }
}

struct DonationRowView_Previews: PreviewProvider {
    static var previews: some View {
        DonationRowView(
            donation: DonationDisplay(
                id: "sampleID",
                charityName: "Clean Water Fund",
                charityDescription: "Provided clean water in remote areas.",
                amount: 50.0
            ),
            isShinyNumbersEnabled: true
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
