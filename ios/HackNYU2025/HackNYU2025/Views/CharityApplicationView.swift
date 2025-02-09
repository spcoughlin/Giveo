//
//  CharityApplicationView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//
import SwiftUI

struct CharityApplicationView: View {
    // Optionally, use your AuthViewModel or a dedicated view model.
    @EnvironmentObject var authViewModel: AuthViewModel

    // Form fields for the charity application.
    @State private var charityName: String = ""
    @State private var website: String = ""
    @State private var description: String = ""
    @State private var contactEmail: String = ""
    
    @State private var isSubmitting: Bool = false
    @State private var submissionSuccess: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header or Title
                        Text("Apply for Charity Account")
                            .font(.custom("SourceSerifPro-Regular", size: 24))
                            .foregroundColor(.primary)
                            .padding(.top, 20)

                        // Application Form Fields
                        VStack(spacing: 16) {
                            Group {
                                TextField("Charity Name", text: $charityName)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .font(.custom("SourceSerifPro-Regular", size: 16))
                                
                                TextField("Website", text: $website)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .font(.custom("SourceSerifPro-Regular", size: 16))
                                
                                TextField("Contact Email", text: $contactEmail)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .font(.custom("SourceSerifPro-Regular", size: 16))
                            }
                            
                            // Description using TextEditor with a bordered look.
                            VStack(alignment: .leading) {
                                Text("Description")
                                    .font(.custom("SourceSerifPro-Regular", size: 16))
                                    .foregroundColor(.gray)
                                TextEditor(text: $description)
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .font(.custom("SourceSerifPro-Regular", size: 16))
                                    .frame(height: 150)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Error Message, if any.
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        // Submit Button or Progress Indicator.
                        if isSubmitting {
                            ProgressView("Submitting...")
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
                                .font(.custom("SourceSerifPro-Semibold", size: 16))
                        } else {
                            Button(action: {
                                submitApplication()
                            }) {
                                Text("Submit Application")
                                    .font(.custom("SourceSerifPro-Semibold", size: 16))
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.accentColor)
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Success Message.
                        if submissionSuccess {
                            Text("Your application has been submitted! We'll be in touch soon.")
                                .foregroundColor(.green)
                                .font(.custom("SourceSerifPro-Regular", size: 16))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Charity Application")
        }
    }
    
    // MARK: - Submission Logic
    private func submitApplication() {
        // Validate required fields.
        guard !charityName.isEmpty,
              !contactEmail.isEmpty,
              !description.isEmpty else {
            errorMessage = "Please fill out all required fields."
            return
        }
        
        // Clear any previous error.
        errorMessage = nil
        isSubmitting = true
        
        // Simulate a network call. Replace this with your API call as needed.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSubmitting = false
            submissionSuccess = true
            
            // Optionally, notify your view model that an application was submitted.
            // authViewModel.applyForCharityAccount(charityName: charityName, ...)
        }
    }
}

struct CharityApplicationView_Previews: PreviewProvider {
    static var previews: some View {
        CharityApplicationView()
            .environmentObject(AuthViewModel())
    }
}
