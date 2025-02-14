//
//  Font+Extension.swift
//  swipeapp
//
//  Created by Alec Agayan on 1/19/25.
//

import SwiftUI

extension Font {
    static func sourceSerifPro(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        // Map SwiftUI's Font.Weight to the actual font names
        let fontName: String
        switch weight {
            case .ultraLight:
                fontName = "SourceSerifPro-ExtraLight"
            case .light:
                fontName = "SourceSerifPro-Light"
            case .regular:
                fontName = "SourceSerifPro-Regular"
            case .semibold:
                fontName = "SourceSerifPro-SemiBold"
            case .bold:
                fontName = "SourceSerifPro-Bold"
            case .heavy:
                fontName = "SourceSerifPro-Black"
            default:
                fontName = "SourceSerifPro-Regular"
        }
        return .custom(fontName, size: size, relativeTo: .body)
    }
}
