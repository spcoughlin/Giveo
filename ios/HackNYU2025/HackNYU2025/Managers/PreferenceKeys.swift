//
//  PreferenceKeys.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct SaveButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
