//
//  Category.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import Foundation

struct Category: Codable, Identifiable {
    let id: UUID
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id = "uuid"
        case name
    }
}
