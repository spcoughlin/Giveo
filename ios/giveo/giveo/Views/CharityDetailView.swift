//
//  CharityDetailView.swift
//  swipeapp
//
//  Created by [Your Name] on [Date]
//

import SwiftUI

struct CharityDetailView: View {
    @ObservedObject var charity: Charity

    // Check for preview mode.
    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-Screen Hero Image Background
                if isPreview {
                    Image("whitehouseHero")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width,
                               height: geometry.size.height)
                        .clipped()
                        .overlay(Color.black.opacity(0.35))
                        .ignoresSafeArea()
                } else {
                    if let heroImage = charity.heroImage {
                        Image("whitehouseHero")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width)
                            .clipped()
                            .overlay(Color.black.opacity(0.35))
                    } else {
                        Image("whitehouseHero")
                            .frame(width: geometry.size.width,
                                   height: geometry.size.height)
                    }
                }

                // Floating Detail Card with Overlapping Logo
                VStack {
                    Spacer() // Push the card to the bottom
                    ZStack(alignment: .top) {
                        DetailCardView(charity: charity)
                            .padding(.top, 60)
                        
                        if isPreview {
                            Image("whitehouseLogo")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .offset(y: -50)
                        } else {
                            if let logo = charity.logoImage {
                                Image(uiImage: logo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .offset(y: -50)
                            }
                        }
                    }
                    .frame(width: geometry.size.width - 32)
                    .padding(.horizontal, 16)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
        // Force the view to refresh whenever the charity publishes changes.
        .onReceive(charity.objectWillChange) { _ in }
    }
}

// MARK: - DetailCardView
/// Displays the charity’s details (name, description, location, tags, new statistics, and a donate button)
struct DetailCardView: View {
    let charity: Charity
    
    // Add a state variable to control the presentation of the DonateView.
    @State private var showDonateSheet = false
    
    // Pull in environment objects that DonateView requires.
    @EnvironmentObject var donationManager: DonationManager
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Charity Name
            Text(charity.name)
                .font(.custom("SourceSerifPro-Semibold", size: 28))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Charity Description
            Text(charity.description)
                .font(.custom("SourceSerifPro-Regular", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Location Indicator
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.accentColor)
                Text(charity.location)
                    .font(.custom("SourceSerifPro-Regular", size: 16))
                    .foregroundColor(.secondary)
            }
            
            // Tags (if available)
            if let tags = charity.primaryTags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.accentColor.opacity(0.2))
                                .foregroundColor(Color.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // New Statistics Row: Donations, Donors, and Campaigns
            HStack {
                Spacer()
                VStack {
                    Text(String(format: "$%.0f", charity.totalDonationAmount))
                        .font(.headline)
                    Text("Donations (\(charity.donationCount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack {
                    Text("\(charity.donorCount)")
                        .font(.headline)
                    Text("Donors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack {
                    Text("\(charity.campaignCount)")
                        .font(.headline)
                    Text("Campaigns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // Donate Now Button
            Button(action: {
                showDonateSheet = true
            }) {
                Text("Donate Now")
                    .font(.custom("SourceSerifPro-Semibold", size: 18))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                    .shadow(radius: 3)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding(.top, 8)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(radius: 10)
        // Present the DonateView when the button is tapped.
        .sheet(isPresented: $showDonateSheet) {
            DonateView(charity: charity)
                .environmentObject(donationManager)
                .environmentObject(userViewModel)
        }
    }
}

// MARK: - Preview
struct CharityDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CharityDetailView(
                charity: Charity(
                    id: "1",
                    name: "The White House",
                    description: "The official residence and workplace of the President of the United States. Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                    location: "Washington, D.C.",
                    heroImageURL: "whitehouseHero",  // Used by Firebase in production mode.
                    logoImageURL: "whitehouseLogo",
                    primaryTags: ["Government", "Historic", "Tourism"],
                    secondaryTags: ["Landmark"],
                    donationIDs: ["d1", "d2"],
                    donorIDs: ["u1", "u2", "u3"],
                    campaignIDs: ["c1", "c2"],
                    donations: [
                        Donation(id: "d1", charityID: "1", userID: "u1", amount: 500),
                        Donation(id: "d2", charityID: "1", userID: "u2", amount: 750)
                    ],
                    donors: [
                        User(id: "u1", name: "Alice", email: "alice@example.com"),
                        User(id: "u2", name: "Bob", email: "bob@example.com"),
                        User(id: "u3", name: "Charlie", email: "charlie@example.com")
                    ],
                    campaigns: [
                        Campaign(id: "c1", charityID: "1", title: "Fundraising Gala", description: "Annual fundraising event.", goal: 10000, donated: 8000, imageName: "whitehouseHero"),
                        Campaign(id: "c2", charityID: "1", title: "Community Outreach", description: "Support for local community programs.", goal: 5000, donated: 3500, imageName: "whitehouseHero")
                    ]
                )
            )
            // For preview purposes, provide dummy environment objects.
            .environmentObject(DonationManager())
            .environmentObject(UserViewModel())
        }
    }
}
