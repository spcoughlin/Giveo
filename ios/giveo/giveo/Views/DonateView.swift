//
//  DonateView.swift
//  swipeapp
//
//  Created by Alec Agayan on 2/8/25.
//

import SwiftUI

struct DonateView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var donationManager: DonationManager
    @EnvironmentObject var userViewModel: UserViewModel

    /// The charity that will receive the donation.
    var charity: Charity

    /// The donation amount (as a string).
    @State private var donationAmount: String = "0"
    @State private var isProcessing: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationView {
            VStack {
                // Header title.
                Text("Donate to \(charity.name)")
                    .font(.custom("SourceSerifPro-Semibold", size: 24))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                
                // Insert the donation keypad view.
                DonationKeypadView(amountString: $donationAmount)
                
                // Donate Now Button.
                Button(action: {
                    donate()
                }) {
                    Text("Donate Now")
                        .font(.custom("SourceSerifPro-Semibold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(8)
                        .shadow(radius: 3)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
                .disabled(isProcessing)
            }
            //.navigationBarTitle("Make a Donation", displayMode: .inline)
//            .navigationBarItems(leading: Button("Cancel") {
//                presentationMode.wrappedValue.dismiss()
//            })
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Donation"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK"), action: {
                        presentationMode.wrappedValue.dismiss()
                      }))
            }
        }
    }
    
    /// Processes the donation.
    private func donate() {
        // Validate donation amount.
        guard let amount = Double(donationAmount), amount > 0 else {
            alertMessage = "Please enter a valid donation amount."
            showAlert = true
            return
        }
        
        // Ensure the user is authenticated.
        guard let user = userViewModel.currentUser, let _ = user.id else {
            alertMessage = "User not authenticated."
            showAlert = true
            return
        }
        
        isProcessing = true
        
        // Create a donation object.
        let donation = Donation(
            id: nil,  // Will be set after Firestore creates the document.
            charityID: charity.id!, // Ensure your charity has an id.
            userID: user.id!,
            amount: amount
        )
        
        // Call the DonationManager to add the donation.
        donationManager.addDonation(donation: donation, for: charity, forUser: user) { success in
            DispatchQueue.main.async {
                self.isProcessing = false
                if success {
                    self.alertMessage = "Thank you for donating $\(String(format: "%.2f", amount)) to \(self.charity.name)!"
                } else {
                    self.alertMessage = "Failed to process your donation. Please try again later."
                }
                self.showAlert = true
            }
        }
    }
}

struct DonateView_Previews: PreviewProvider {
    static var previews: some View {
        // Dummy charity for preview.
        let dummyCharity = Charity(
            id: "charity123",
            name: "Helping Hands",
            description: "A charity dedicated to helping those in need.",
            location: "New York, NY",
            heroImageURL: "",
            logoImageURL: "",
            primaryTags: ["Support"],
            secondaryTags: ["Community"],
            donationIDs: [],
            donorIDs: [],
            campaignIDs: []
        )
        
        DonateView(charity: dummyCharity)
            .environmentObject(DonationManager())
            .environmentObject(UserViewModel())
    }
}
