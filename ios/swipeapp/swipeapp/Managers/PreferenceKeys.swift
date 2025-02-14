//
//  PreferenceKeys.swift
//  swipeapp
//
//  Created by Alec Agayan on 2/8/25.
//

import SwiftUI

struct SaveButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
