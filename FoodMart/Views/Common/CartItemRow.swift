//
//  CartItemRow.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import SwiftUI

struct CartItemRow: View {
    let item: PurchaseItem
    let onDelete: () -> Void

    var body: some View {
        HStack {
            // Thumbnail
            AsyncImage(url: URL(string: item.foodItem.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    Color(.darkGray)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.gray)
                        }
                @unknown default:
                    Color(.red)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Name + quantity
            VStack(alignment: .leading, spacing: 2) {
                Text(item.foodItem.name)
                    .bold()
                    .foregroundStyle(.blue)
                    .lineLimit(1)

                Text("Qty: \(item.quantity)")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }

            Spacer()

            // Line total
            Text(item.lineTotal, format: .currency(code: "USD"))
                .bold()
                .foregroundStyle(.blue)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(.red)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("delete_cart_item")
            .accessibilityLabel("Remove \(item.foodItem.name) from cart")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

#Preview {
    CartItemRow(
        item: PurchaseItem(
            id: UUID(),
            foodItem: FoodItem(id: UUID(), name: "Artisan Sourdough", price: 5.50, categoryUUID: UUID(), imageURL: ""),
            quantity: 2
        ),
        onDelete: {}
    )
}
