//
//  FoodServiceProtocol.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import Foundation

protocol FoodServiceProtocol {
    func getFoods() async throws -> [FoodItem]
    func getCategories() async throws -> [Category]
}
