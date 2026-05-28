//
//  FoodItem.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import Foundation

struct FoodItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let price: Double
    let categoryUUID: UUID
    let imageURL: String
    
    enum CodingKeys: String, CodingKey {
        case id = "uuid"
        case name
        case price
        case categoryUUID = "category_uuid"
        case imageURL = "image_url"
    }
}
