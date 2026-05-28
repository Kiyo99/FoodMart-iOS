//
//  Cart.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import Foundation

struct PurchaseItem: Codable, Equatable, Identifiable {
    let id: UUID
    let foodItem: FoodItem
    var quantity: Int

    var lineTotal: Double {
        foodItem.price * Double(quantity)
    }

    static func == (lhs: PurchaseItem, rhs: PurchaseItem) -> Bool {
        lhs.id == rhs.id
    }
}
