//
//  View+CardStyle.swift
//  Prune
//
//  View modifier for consistent card background styling.
//

import SwiftUI

extension View {
    func cardBackground() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: 0xF2F7FD))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

