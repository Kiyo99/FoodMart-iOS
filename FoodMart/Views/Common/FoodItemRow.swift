//
//  FoodItemRow.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import SwiftUI

struct FoodItemRow: View {
    let item: FoodItem
    let categoryName: String
    let quantity: Int
    let onAdd: () -> Void

    var body: some View {
        HStack() {
            // Thumbnail
            AsyncImage(url: URL(string: item.imageURL)) { phase in
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

            // Name + subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                    .lineLimit(1)

                if !categoryName.isEmpty {
                    Text(categoryName)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Price
            Text(item.price, format: .currency(code: "USD"))
                .bold()
                .foregroundStyle(.blue)

            // Add button — shows quantity badge when already in cart
            Button(action: onAdd) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.orange)
                        .clipShape(Circle())

                    if quantity > 0 {
                        Text("\(quantity)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 16, height: 16)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("add_to_cart")
            .accessibilityLabel("Add \(item.name) to cart")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

#Preview {
    FoodItemRow(
        item: FoodItem(id: UUID(), name: "Organic Bananas", price: 1.29, categoryUUID: UUID(), imageURL: ""),
        categoryName: "Produce",
        quantity: 2,
        onAdd: {}
    )
}
