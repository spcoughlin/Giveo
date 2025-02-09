//
//  OnboardingView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode

    // Example list of charity tags
    let charityTags = [
        "Education",
        "Health",
        "Environment",
        "Animal Welfare",
        "Arts & Culture",
        "Community Development",
        "Human Rights",
        "Disaster Relief",
        "International Aid",
        "Sports",
        "Food Security",
        "Technology",
        "Youth Empowerment",
        "Elderly Care",
        "Mental Health",
        "Disability Support"
    ]

    @State private var selectedTags: Set<String> = []

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Your Top 3 Charity Interests")
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 40)
                    .multilineTextAlignment(.center)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 15) {
                        ForEach(charityTags, id: \.self) { tag in
                            TagButton(tag: tag, isSelected: selectedTags.contains(tag)) {
                                toggleSelection(for: tag)
                            }
                        }
                    }
                    .padding()
                }

                Spacer()

                Button(action: {
                    // Save selected tags to Firestore
                    //userViewModel.updatePrimaryTags(tags: Array(selectedTags)) {
                        // Dismiss onboarding after saving
                        presentationMode.wrappedValue.dismiss()
                    //}
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTags.count == 3 ? Color.accentColor : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(selectedTags.count != 3)
                .padding([.horizontal, .bottom], 20)
            }
            .navigationBarTitle("Onboarding", displayMode: .inline)
        }
    }

    /// Toggle selection for a given tag, ensuring a maximum of 3 selections
    private func toggleSelection(for tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            if selectedTags.count < 3 {
                selectedTags.insert(tag)
            }
        }
    }
}

struct TagButton: View {
    let tag: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(tag)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : .primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(UserViewModel())
    }
}
