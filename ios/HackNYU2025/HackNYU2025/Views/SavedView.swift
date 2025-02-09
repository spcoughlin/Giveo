//
//  SavedView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct SavedView: View {
    @EnvironmentObject var manager: SavedCharitiesManager
    @State private var hasAppeared = false // Tracks if the view has already appeared
    @State private var selectedCharity: Charity? = nil  // Holds the tapped charity

    var body: some View {
        NavigationView {
            Group {
                if manager.savedCharities.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)

                        Text("No saved charities yet.")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.gray)

                        Text("Browse and save your favorite charities to see them here.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(manager.savedCharities) { charity in
                            CharityRowView(charity: charity)
                                .onTapGesture {
                                    selectedCharity = charity
                                }
                        }
                        .onDelete { indexSet in
                            // Ensure only one deletion at a time.
                            indexSet.forEach { index in
                                let charity = manager.savedCharities[index]
                                manager.removeCharity(charity)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Saved Charities")
            .refreshable {
                manager.fetchSavedCharities() // Reload data when user pulls down
            }
            .onAppear {
                if !hasAppeared {
                    manager.fetchSavedCharities() // Fetch only on first appearance
                    hasAppeared = true
                }
            }
            // Present CharityDetailView modally. Users can swipe down to dismiss.
            .sheet(item: $selectedCharity) { charity in
                CharityDetailView(charity: charity)
                    // Optional: Presentation detents allow for a medium or large modal.
                    //.presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

struct SavedView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock managers with sample data for preview.
        let mockManagerWithCharities = SavedCharitiesManager(userID: nil)
        var charityA = Charity(
            id: "1",
            name: "Charity A",
            description: "Helping those in need.",
            location: "New York, NY",
            heroImageURL: "hero1.jpg",
            logoImageURL: "logo1.jpg"
        )
        var charityB = Charity(
            id: "2",
            name: "Charity B",
            description: "Providing education for underprivileged children.",
            location: "Los Angeles, CA",
            heroImageURL: "hero2.jpg",
            logoImageURL: "logo2.jpg"
        )
        mockManagerWithCharities.savedCharities = [charityA, charityB]
        
        let mockManagerEmpty = SavedCharitiesManager(userID: nil) // No saved charities

        return Group {
            // Preview with saved charities
            SavedView()
                .environmentObject(mockManagerWithCharities)
                .previewDisplayName("With Saved Charities")
            
            // Preview with no saved charities
            SavedView()
                .environmentObject(mockManagerEmpty)
                .previewDisplayName("No Saved Charities")
        }
    }
}
