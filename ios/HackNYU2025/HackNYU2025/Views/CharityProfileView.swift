//
//  CharityProfileView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI
import FirebaseAuth

struct CharityProfileView: View {
    @EnvironmentObject var charitiesManager: CharitiesManager
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var donationManager: DonationManager

    // Controls the presentation of the edit view sheet.
    @State private var showEditProfile: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Header: Hero Image with Overlapping Profile (Logo) Image
                ZStack(alignment: .bottom) {
                    // Hero Image
                    if let heroImage = currentCharity?.heroImage {
                        Image(uiImage: heroImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 250)
                            .clipped()
                    } else {
                        Color.gray.opacity(0.3)
                            .frame(height: 250)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // Profile (Logo) Image – positioned so its center aligns with the bottom edge.
                    if let logo = currentCharity?.logoImage {
                        Image(uiImage: logo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                            .shadow(radius: 4)
                            .offset(y: 40)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            )
                            .offset(y: 60)
                    }
                }
                .padding(.bottom, 32)
                
                // MARK: - Charity Name & Location
                if let charity = currentCharity {
                    VStack(spacing: 8) {
                        Text(charity.name)
                            .font(.sourceSerifPro(size: 24, weight: .semibold))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.accentColor)
                            Text(charity.location)
                                .font(.sourceSerifPro(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // MARK: - Stats Row
                if let charity = currentCharity {
                    HStack(spacing: 40) {
                        statItem(value: Int(charity.totalDonationAmount), label: "Donations")
                        statItem(value: charity.donorCount, label: "Donors")
                        statItem(value: charity.campaignCount, label: "Campaigns")
                    }
                }
                
                // MARK: - Bio, Tags & Donate Button
                if let charity = currentCharity {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(charity.description)
                            .font(.sourceSerifPro(size: 16, weight: .regular))
                            .foregroundColor(.primary)
                        
                        if let tags = charity.primaryTags, !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.sourceSerifPro(size: 14, weight: .regular))
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 12)
                                            .background(Color.accentColor.opacity(0.2))
                                            .foregroundColor(Color.accentColor)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        
//                        Button(action: {
//                            print("Donate tapped for \(charity.name)")
//                            // Insert donation logic here.
//                        }) {
//                            Text("Donate Now")
//                                .font(.sourceSerifPro(size: 16, weight: .semibold))
//                                .foregroundColor(.white)
//                                .padding()
//                                .frame(maxWidth: .infinity)
//                                .background(Color.accentColor)
//                                .cornerRadius(8)
//                        }
                    }
                    .padding(.horizontal)
                }
                
                // MARK: - Campaigns Section
//                if let charity = currentCharity, !charity.campaigns.isEmpty {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Campaigns")
//                            .font(.sourceSerifPro(size: 18, weight: .semibold))
//                            .padding(.horizontal)
//                        
//                        ScrollView(.horizontal, showsIndicators: false) {
//                            HStack(spacing: 16) {
//                                ForEach(charity.campaigns) { campaign in
//                                    NavigationLink(destination: CampaignDetailView(campaign: campaign)) {
//                                        CampaignCardView(campaign: campaign)
//                                            .frame(width: 250)
//                                    }
//                                    .buttonStyle(PlainButtonStyle())
//                                }
//                            }
//                            .padding(.horizontal)
//                        }
//                    }
//                    .padding(.vertical)
//                }
                
                // MARK: - Impact Articles Section
                // (Here we use dummy articles for demonstration.)
//                if !dummyImpactArticles.isEmpty {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Impact Articles")
//                            .font(.sourceSerifPro(size: 18, weight: .semibold))
//                            .padding(.horizontal)
//                        
//                        ForEach(dummyImpactArticles) { article in
//                            NavigationLink(destination: ImpactArticleView(article: article)) {
//                                ImpactArticleCardView(article: article)
//                                    .padding(.horizontal)
//                            }
//                            .buttonStyle(PlainButtonStyle())
//                        }
//                    }
//                    .padding(.vertical)
//                }
                
                // Add extra space at the bottom so the floating buttons don't block content.
                Spacer()
                    .frame(height: 64)
            }
        }
        .navigationBarTitle("Charity Profile", displayMode: .inline)
        .sheet(isPresented: $showEditProfile) {
            if let charity = currentCharity {
                EditCharityProfileView(charity: charity)
                    .environmentObject(charitiesManager)
            }
        }
    }
    
    /// Returns the charity associated with the current user.
    private var currentCharity: Charity? {
        guard let charityID = userViewModel.currentUser?.charityID else { return nil }
        return charitiesManager.allCharities.first(where: { $0.id == charityID })
    }
    
    /// A helper view to display a stat item.
    @ViewBuilder
    private func statItem(value: Int, label: String) -> some View {
        VStack {
            Text("\(value)")
                .font(.sourceSerifPro(size: 20, weight: .semibold))
            Text(label)
                .font(.sourceSerifPro(size: 12, weight: .regular))
                .foregroundColor(.gray)
        }
    }
}

// Dummy impact articles for demo purposes.
extension CharityProfileView {
    var dummyImpactArticles: [ImpactArticle] {
        [
            ImpactArticle(title: "Community Meal Brings Neighbors Together",
                          subtitle: "A heartwarming story of unity and support.",
                          thumbnailImageName: "storyPlaceholder",
                          blocks: [
                              ArticleBlock(type: .text("**Breaking News:** Today, the community gathered for a meal.")),
                              ArticleBlock(type: .image(name: "communityMeal", caption: "Residents enjoying a shared meal."))
                          ]),
            ImpactArticle(title: "New Educational Program Empowers Local Youth",
                          subtitle: "Innovative programs creating lasting change.",
                          thumbnailImageName: "educationPlaceholder",
                          blocks: [
                              ArticleBlock(type: .text("A groundbreaking initiative has been launched...")),
                              ArticleBlock(type: .image(name: "youthEmpowerment", caption: "Students engaged in creative learning."))
                          ])
        ]
    }
}

struct CharityProfileView_Previews: PreviewProvider {
    static var previews: some View {
        CharityProfileViewPreview()
            .previewDevice("iPhone 14")
    }
}

struct CharityProfileViewPreview: View {
    @StateObject var mockCharitiesManager = CharitiesManager()
    @StateObject var mockUserViewModel = UserViewModel()
    @StateObject var mockDonationManager = DonationManager()

    init() {
        // Create a mock charity with campaigns, donations, and donors.
        let mockCharity = Charity(
            id: "charity123",
            name: "Helping Hands",
            description: "Dedicated to providing support and resources to those in need. Our mission is to help communities thrive.",
            location: "New York, NY",
            heroImageURL: "",
            logoImageURL: "",
            primaryTags: ["Support", "Community"],
            secondaryTags: ["Education", "Health"],
            donationIDs: ["d1", "d2"],
            donorIDs: ["u1", "u2", "u3"],
            campaignIDs: ["c1", "c2"]
        )
        
        // Simulate loaded full objects.
        mockCharity.donations = [
            Donation(id: "d1", charityID: "charity123", userID: "u1", amount: 500),
            Donation(id: "d2", charityID: "charity123", userID: "u2", amount: 750)
        ]
        mockCharitiesManager.allCharities = [mockCharity]
        
        // Create a mock user associated with the charity.
        let mockUser = User(
            id: "user123",
            name: "Jane Smith",
            email: "jane@example.com",
            phoneNumber: "987-654-3210",
            charityID: "charity123",
            profileImageURL: "https://via.placeholder.com/150"
        )
        mockUserViewModel.currentUser = mockUser
    }
    
    var body: some View {
        NavigationView {
            CharityProfileView()
                .environmentObject(mockCharitiesManager)
                .environmentObject(mockUserViewModel)
                .environmentObject(mockDonationManager)
        }
    }
}
struct CampaignDetailView: View {
    var campaign: Campaign
    
    var body: some View {
        VStack(spacing: 16) {
            CampaignCardView(campaign: campaign)
                .padding()
            Text("Details for \(campaign.title)")
                .font(.title2)
                .padding()
            Spacer()
        }
        .navigationTitle("Campaign Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
