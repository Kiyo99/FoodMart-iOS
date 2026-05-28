//
//  CartStore.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import Foundation

enum CartStore {
    private static let fileURL: URL = {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("cart.json")
    }()

    static func save(_ items: [PurchaseItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func load() -> [PurchaseItem] {
        guard let data = try? Data(contentsOf: fileURL),
              let items = try? JSONDecoder().decode([PurchaseItem].self, from: data)
        else { return [] }
        return items
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
