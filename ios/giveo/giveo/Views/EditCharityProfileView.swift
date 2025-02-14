import SwiftUI

struct EditCharityProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var charitiesManager: CharitiesManager

    // The charity to be edited.
    @ObservedObject var charity: Charity

    // Local state for edited fields.
    @State private var editedDescription: String = ""
    @State private var editedLocation: String = ""
    @State private var newHeroImage: UIImage? = nil
    @State private var newLogoImage: UIImage? = nil

    // New local state for tag selections.
    @State private var editedPrimaryTags: [String] = []
    @State private var editedSecondaryTags: [String] = []

    // A master list of tags.
    private let allTags: [String] = [
        "children", "women", "men", "LGBTQ", "suicide awareness",
        "mental health", "club", "elementary school", "middle school",
        "high school", "university", "sports", "housing", "addiction",
        "disasters", "food", "abuse", "animals", "veterans", "environment",
        "poverty", "education", "arts", "homelessness", "elderly", "cancer",
        "research", "disability", "human rights", "legal aid", "immigration",
        "refugees", "community", "youth empowerment", "domestic violence",
        "fundraising", "global health", "water", "sanitation", "refugee support",
        "community service", "social justice", "advocacy", "climate change",
        "sustainability", "conservation", "wildlife", "animal rescue", "elder care",
        "hunger relief", "disaster recovery", "mental illness", "substance abuse",
        "homeless shelters", "disability rights", "women's health", "children's health",
        "education access", "literacy", "after school programs", "recreation",
        "employment", "job training", "entrepreneurship", "nonprofit support",
        "community gardens", "urban development", "rural development",
        "technology access", "digital literacy", "public safety", "emergency response",
        "crisis intervention", "parenting support", "healthcare access",
        "suicide prevention", "disaster preparedness", "veteran support", "legal services",
        "justice reform", "humanitarian aid", "international aid", "childhood education",
        "early childhood", "environmental justice", "sustainable agriculture", "food banks",
        "community kitchens", "homeschooling", "religious organizations", "spiritual support",
        "mental health support", "senior support", "child advocacy", "disaster relief",
        "health education", "public health", "community outreach", "volunteerism",
        "capacity building"
    ]

    // Flags to present image pickers.
    @State private var showingHeroPicker: Bool = false
    @State private var showingLogoPicker: Bool = false

    // Flags to show tag selection sheets.
    @State private var showingPrimaryTagSheet: Bool = false
    @State private var showingSecondaryTagSheet: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // MARK: - Hero (Banner) Image Section
                    ZStack(alignment: .topTrailing) {
                        if let hero = newHeroImage ?? charity.heroImage {
                            Image(uiImage: hero)
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
                        Button(action: { showingHeroPicker = true }) {
                            Image(systemName: "camera.fill")
                                .font(.title)
                                .padding(10)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                    .edgesIgnoringSafeArea(.top)
                    
                    // MARK: - Logo Image Section
                    ZStack(alignment: .bottomTrailing) {
                        if let logo = newLogoImage ?? charity.logoImage {
                            Image(uiImage: logo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                                .shadow(radius: 4)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.white)
                                )
                        }
                        Button(action: { showingLogoPicker = true }) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .padding(6)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        .offset(x: -10, y: -10)
                    }
                    .offset(y: -60)
                    .padding(.bottom, -60)
                    
                    // MARK: - Editable Fields
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            Text("Description")
                                .font(.headline)
                            TextEditor(text: $editedDescription)
                                .frame(height: 150)
                                .padding(8)
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1))
                        }
                        
                        Group {
                            Text("Location")
                                .font(.headline)
                            TextField("Enter location", text: $editedLocation)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // MARK: - Primary Tags Section
                        Group {
                            HStack {
                                Text("Primary Tags (Select 3)")
                                    .font(.headline)
                                Spacer()
                                Button("Edit") {
                                    showingPrimaryTagSheet = true
                                }
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(editedPrimaryTags, id: \.self) { tag in
                                        Text(tag)
                                            .padding(8)
                                            .background(Color.accentColor.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Secondary Tags Section
                        Group {
                            HStack {
                                Text("Secondary Tags (Select up to 20)")
                                    .font(.headline)
                                Spacer()
                                Button("Edit") {
                                    showingSecondaryTagSheet = true
                                }
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(editedSecondaryTags, id: \.self) { tag in
                                        Text(tag)
                                            .padding(8)
                                            .background(Color.accentColor.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationBarTitle("Edit Profile", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { updateProfile() }
                }
            }
            .onAppear {
                // Initialize fields with current values.
                editedDescription = charity.description
                editedLocation = charity.location
                editedPrimaryTags = charity.primaryTags ?? []
                editedSecondaryTags = charity.secondaryTags ?? []
            }
            // MARK: - Image Picker Sheets
            .sheet(isPresented: $showingHeroPicker) { ImagePicker(image: $newHeroImage) }
            .sheet(isPresented: $showingLogoPicker) { ImagePicker(image: $newLogoImage) }
            // MARK: - Tag Selection Sheets
            .sheet(isPresented: $showingPrimaryTagSheet) {
                TagSelectionSheetView(allTags: allTags,
                                      selectedTags: $editedPrimaryTags,
                                      maxSelection: 3,
                                      title: "Primary")
            }
            .sheet(isPresented: $showingSecondaryTagSheet) {
                TagSelectionSheetView(allTags: allTags,
                                      selectedTags: $editedSecondaryTags,
                                      maxSelection: 20,
                                      title: "Secondary")
            }
        }
    }
    
    private func updateProfile() {
        // Update the charity profile with the edited values and tags.
        charitiesManager.updateCharityProfile(
            charity: charity,
            newDescription: editedDescription,
            newLocation: editedLocation,
            newHeroImage: newHeroImage,
            newLogoImage: newLogoImage,
            newPrimaryTags: editedPrimaryTags,
            newSecondaryTags: editedSecondaryTags
        ) { success in
            if success {
                print("Charity profile updated successfully.")
                presentationMode.wrappedValue.dismiss()
            } else {
                print("Error updating charity profile.")
                // Optionally present an alert here.
            }
        }
    }
}
struct EditCharityProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock charity for preview.
        let charity = Charity(
            id: "charity123",
            name: "Helping Hands",
            description: "Dedicated to supporting communities with resources and care.",
            location: "New York, NY",
            heroImageURL: "",
            logoImageURL: "",
            primaryTags: ["children", "education", "community"],
            secondaryTags: ["arts", "health", "research"]
        )
        charity.heroImage = UIImage(named: "whitehouseHero")
        charity.logoImage = UIImage(named: "whitehouseLogo")
        
        return NavigationView {
            EditCharityProfileView(charity: charity)
                .environmentObject(CharitiesManager())
        }
    }
}
