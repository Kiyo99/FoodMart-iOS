//
//  CategoryChip.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import SwiftUI

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(category.name)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? .white : .blue)
            .background(isSelected ? Color.blue : Color.blue.opacity(0.1), in: Capsule())
            .onTapGesture { onTap() }
            .accessibilityIdentifier("chip_\(category.name)")
    }
}
