//
//  SwipeView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI
import FirebaseAuth

struct SwipeView: View {
    @EnvironmentObject var savedManager: SavedCharitiesManager
    @EnvironmentObject var charitiesManager: CharitiesManager
    @EnvironmentObject var userViewModel: UserViewModel

    // Local flag to ensure only one swipe is processed at a time.
    @State private var isSwipeInProgress = false

    // New state variables for search mode, text, results, and selected charity.
    @State private var isSearching: Bool = false
    @State private var searchText: String = ""
    @State private var searchResults: [Charity] = []
    @State private var selectedCharity: Charity? = nil

    // Shared namespace for matched geometry animations.
    @Namespace private var animationNamespace

    var body: some View {
        ZStack {
            // Background adapts to light/dark mode.
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Top Bar with Title / Search Field and Search Button
                HStack {
                    if isSearching {
                        TextField("Search charities...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .transition(.move(edge: .trailing))
                            .onChange(of: searchText) { newValue in
                                charitiesManager.searchCharitiesInFirebase(query: newValue) { results in
                                    let group = DispatchGroup()
                                    var updatedResults: [Charity] = []
                                    
                                    for charity in results {
                                        if charity.heroImage != nil && charity.logoImage != nil {
                                            updatedResults.append(charity)
                                        } else {
                                            group.enter()
                                            charitiesManager.fetchImages(for: charity) { updatedCharity in
                                                if let updatedCharity = updatedCharity,
                                                   updatedCharity.heroImage != nil,
                                                   updatedCharity.logoImage != nil {
                                                    updatedResults.append(updatedCharity)
                                                }
                                                group.leave()
                                            }
                                        }
                                    }
                                    
                                    group.notify(queue: .main) {
                                        withAnimation {
                                            searchResults = updatedResults
                                        }
                                    }
                                }
                            }
                    } else {
                        Text("Discover Charities")
                            .font(.custom("SourceSerifPro-Semibold", size: 24))
                            .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut) {
                            isSearching.toggle()
                            if !isSearching {
                                searchText = ""
                                searchResults = []
                            }
                        }
                    }) {
                        Image(systemName: isSearching ? "xmark.circle.fill" : "magnifyingglass")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .padding(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // MARK: - Content: Either Search Results or Swipe Cards
                if isSearching {
                    if searchText.isEmpty {
                        Text("Type to search for charities")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        if searchResults.isEmpty {
                            Text("No charities found matching \"\(searchText)\"")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(searchResults) { charity in
                                        CharityCardView(charity: charity, onSwipe: { _ in }, namespace: animationNamespace)
                                            .padding(.horizontal)
                                            .onTapGesture {
                                                selectedCharity = charity
                                            }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // MARK: - Swipe Cards / Loading Animation
                    if charitiesManager.displayedCharities.isEmpty {
                        LoadingAnimationView()
                            .transition(.opacity)
                            .animation(.easeInOut, value: charitiesManager.displayedCharities.count)
                    } else {
                        ZStack {
                            ForEach(charitiesManager.displayedCharities, id: \.id) { charity in
                                // Get the index to assign a zIndex.
                                let index = charitiesManager.displayedCharities.firstIndex(where: { $0.id == charity.id }) ?? 0
                                CharityCardView(charity: charity, onSwipe: { direction in
                                    if charity.id == charitiesManager.displayedCharities.last?.id {
                                        handleSwipe(direction, charity: charity)
                                    } else {
                                        print("Ignoring swipe on non-top card: \(charity.name)")
                                    }
                                }, namespace: animationNamespace)
                                .zIndex(Double(index))
                                .transition(.opacity)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
                
                Spacer()
                
                // MARK: - Bottom Control Panel (Hidden when Searching)
                if !isSearching {
                    HStack(spacing: 40) {
                        Button(action: {
                            swipeTopCard(with: .left)
                        }) {
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(Circle().fill(Color.red.opacity(0.2)))
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            swipeTopCard(with: .down)
                        }) {
                            Image(systemName: "bookmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(Circle().fill(Color.blue.opacity(0.2)))
                                .foregroundColor(.blue)
                        }
                        .overlay(
                            // This invisible view is anchored at the button’s location.
                            Color.clear
                                .frame(width: 30 + 16 * 2, height: 30 + 16 * 2)
                                .matchedGeometryEffect(id: "saveButton", in: animationNamespace)
                        )
                        
                        Button(action: {
                            swipeTopCard(with: .up)
                        }) {
                            Image(systemName: "arrow.up")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(Circle().fill(Color.green.opacity(0.2)))
                                .foregroundColor(.green)
                        }
                        
                        Button(action: {
                            swipeTopCard(with: .right)
                        }) {
                            Image(systemName: "heart")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(Circle().fill(Color.pink.opacity(0.2)))
                                .foregroundColor(.pink)
                        }
                    }
                    .padding(.vertical, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: charitiesManager.displayedCharities.count)
                }
            }
        }
        .onAppear {
            // Only fetch if no charities are currently loaded.
            if charitiesManager.displayedCharities.isEmpty {
                charitiesManager.fetchCharities()
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { charitiesManager.errorMessage != nil },
            set: { _ in charitiesManager.errorMessage = nil }
        )) {
            Alert(
                title: Text("Error").font(.custom("SourceSerifPro-Semibold", size: 16)),
                message: Text(charitiesManager.errorMessage ?? "Unknown error").font(.custom("SourceSerifPro-Regular", size: 14)),
                dismissButton: .default(Text("OK").font(.custom("SourceSerifPro-Regular", size: 14)))
            )
        }
        // Sheet presentation for CharityDetailView.
        .sheet(item: $selectedCharity) { charity in
            CharityDetailView(charity: charity)
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Private Methods
extension SwipeView {
    /// Handles a swipe action and calls the reaction API for like, dislike, or donate.
    private func handleSwipe(_ direction: SwipeDirection, charity: Charity) {
        print("handleSwipe called with direction \(direction) for charity: \(charity.name)")
        guard !isSwipeInProgress else {
            print("Swipe already in progress for \(charity.name)")
            return
        }
        isSwipeInProgress = true

        switch direction {
        case .left:
            print("User swiped LEFT (dislike) on \(charity.name)")
            callReactionAPI(for: charity, reactionNum: 1)
        case .right:
            print("User swiped RIGHT (like) on \(charity.name)")
            callReactionAPI(for: charity, reactionNum: 0)
        case .up:
            print("User swiped UP (donate) on \(charity.name)")
            callReactionAPI(for: charity, reactionNum: 3, amount: 0)
        case .down:
            print("User swiped DOWN (save) on \(charity.name)")
            callReactionAPI(for: charity, reactionNum: 1)
            savedManager.addCharity(charity)
            // No reaction API call for save.
        }
        
        // Remove the card after the swipe.
        DispatchQueue.main.async {
            withAnimation(.easeInOut) {
                charitiesManager.removeDisplayedCharity(charity)
            }
            isSwipeInProgress = false
        }
    }
    
    /// Simulates a swipe action on the top card with the given direction.
    private func swipeTopCard(with direction: SwipeDirection) {
        guard let topCharity = charitiesManager.displayedCharities.last else {
            print("No charity available to swipe.")
            return
        }
        print("Simulating swipe \(direction) on \(topCharity.name)")
        handleSwipe(direction, charity: topCharity)
    }
    
    /// Calls the reaction API with the given reaction number and amount.
    /// - Parameters:
    ///   - charity: The charity being swiped.
    ///   - reactionNum: The reaction number (0 = like, 1 = dislike, 3 = donate).
    ///   - amount: The donation amount (defaults to 0).
    private func callReactionAPI(for charity: Charity, reactionNum: Int, amount: Double = 0.0) {
        // Ensure we have an authenticated user.
        guard let userID = Auth.auth().currentUser?.uid, let charityID = charity.id else {
            print("Missing user or charity ID; cannot call reaction API.")
            return
        }
        
        let apiBaseURL = "http://52.70.58.148"  // Replace with your actual API base URL.
        let urlString = "\(apiBaseURL)/reaction?userID=\(userID)&reactionNum=\(reactionNum)&nonprofitID=\(charityID)&amount=\(amount)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid reaction API URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error calling reaction API: \(error.localizedDescription)")
            } else {
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Reaction API response: \(responseString)")
                } else {
                    print("Reaction API called successfully; no data returned.")
                }
            }
        }.resume()
    }
}
