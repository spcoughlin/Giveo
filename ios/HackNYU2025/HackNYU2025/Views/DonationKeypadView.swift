//
//  DonationKeypadView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct DonationKeypadView: View {
    /// Binding to the donation amount string.
    @Binding var amountString: String
    
    var body: some View {
        VStack(spacing: 32) {
            // Shiny donation amount display using your custom ShinyText.
            ShinyText(text: "$" + amountString,
                      font: .system(size: 48, weight: .bold),
                      weight: .bold)
                .padding(.top, 50)
            
            // Keypad grid.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                ForEach(keypadButtons, id: \.self) { key in
                    Button(action: { handleKeyPress(key) }) {
                        Text(key)
                            .font(.system(size: 32, weight: .medium))
                            .frame(width: 80, height: 80)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding(.bottom, 50)
    }
    
    /// The keys for our keypad.
    var keypadButtons: [String] {
        // Four rows: "1 2 3", "4 5 6", "7 8 9", and [".", "0", "<"] (where "<" is backspace)
        ["1", "2", "3",
         "4", "5", "6",
         "7", "8", "9",
         ".", "0", "<"]
    }
    
    // MARK: - Input Handling
    
    /// Append a digit or character to the current amount string.
    func appendDigit(_ digit: String) {
        if amountString == "0" && digit != "." {
            amountString = digit
        } else {
            amountString.append(digit)
        }
    }
    
    /// Delete the last character.
    func deleteLast() {
        if amountString.count > 1 {
            amountString.removeLast()
        } else {
            amountString = "0"
        }
    }
    
    /// Process a keypad button press.
    func handleKeyPress(_ key: String) {
        switch key {
        case "<":
            deleteLast()
        case ".":
            // Only allow one decimal point.
            if !amountString.contains(".") {
                amountString.append(key)
            }
        default:
            appendDigit(key)
        }
    }
}

struct DonationKeypadView_Previews: PreviewProvider {
    @State static var previewAmount = "0"
    static var previews: some View {
        DonationKeypadView(amountString: $previewAmount)
            .preferredColorScheme(.light)
    }
}
