//
//  TagSelectionSheetView.swift
//  swipeapp
//
//  Created by Alec Agayan on 2/8/25.
//

import SwiftUI

struct TagSelectionSheetView: View {
    let allTags: [String]
    @Binding var selectedTags: [String]
    let maxSelection: Int?
    let title: String

    @Environment(\.presentationMode) var presentationMode
    @State private var searchText: String = ""

    // Filter the available tags based on the search query.
    private var filteredTags: [String] {
        if searchText.isEmpty {
            return allTags
        } else {
            return allTags.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            List(filteredTags, id: \.self) { tag in
                Button {
                    toggleSelection(for: tag)
                } label: {
                    HStack {
                        Text(tag)
                        Spacer()
                        if selectedTags.contains(tag) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("\(title) Tags")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleSelection(for tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            if let max = maxSelection, selectedTags.count >= max {
                // Optionally, add feedback to the user (haptic, alert, etc.).
                return
            }
            selectedTags.append(tag)
        }
    }
}
