import SwiftUI
import FirebaseFirestore

struct CharityMigrationView: View {
    @State private var migrationStatus: String = "Idle"
    @State private var isMigrating: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Migration Status:")
                .font(.headline)
            Text(migrationStatus)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                startMigration()
            }) {
                Text(isMigrating ? "Migrating…" : "Start Migration")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isMigrating ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isMigrating)
        }
        .padding()
    }
    
    func startMigration() {
        isMigrating = true
        migrationStatus = "Querying charity documents..."
        
        let db = Firestore.firestore()
        db.collection("charities").getDocuments { snapshot, error in
            if let error = error {
                migrationStatus = "Error querying charities: \(error.localizedDescription)"
                isMigrating = false
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                migrationStatus = "No charity documents found."
                isMigrating = false
                return
            }
            
            let group = DispatchGroup()
            var migratedCount = 0
            
            for document in documents {
                // Check if the document has the fields to be migrated.
                let data = document.data()
                if let heroImageURL = data["heroImageURL"] as? String,
                   let logoImageURL = data["logoImageURL"] as? String {
                    
                    group.enter()
                    // Prepare the update: add new fields with the same values
                    // and delete the old fields.
                    let updates: [String: Any] = [
                        "heroImage": heroImageURL,
                        "logoImage": logoImageURL,
                        "heroImageURL": FieldValue.delete(),
                        "logoImageURL": FieldValue.delete()
                    ]
                    
                    db.collection("charities").document(document.documentID).updateData(updates) { updateError in
                        if let updateError = updateError {
                            print("Error updating document \(document.documentID): \(updateError.localizedDescription)")
                        } else {
                            print("Migrated document \(document.documentID)")
                            migratedCount += 1
                        }
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                migrationStatus = "Migration complete. \(migratedCount) documents updated."
                isMigrating = false
            }
        }
    }
}

struct CharityMigrationView_Previews: PreviewProvider {
    static var previews: some View {
        CharityMigrationView()
    }
}
