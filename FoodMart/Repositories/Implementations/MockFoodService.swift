//
//  MockFoodService.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import Foundation

#if DEBUG
class MockFoodService: FoodServiceProtocol {
    static let fruitID = UUID()
    static let fiberID = UUID()
    static let drinkID = UUID()

    var mockFoods = [
        FoodItem(id: UUID(), name: "Apple",  price: 4.56,  categoryUUID: MockFoodService.fruitID, imageURL: "https://"),
        FoodItem(id: UUID(), name: "Banana", price: 5.99,  categoryUUID: MockFoodService.fiberID, imageURL: "https://"),
        FoodItem(id: UUID(), name: "Chips",  price: 20.56, categoryUUID: MockFoodService.drinkID, imageURL: "https://")
    ]

    var mockCategories = [
        Category(id: MockFoodService.fruitID, name: "Fruit"),
        Category(id: MockFoodService.fiberID, name: "Fiber"),
        Category(id: MockFoodService.drinkID, name: "Drink")
    ]
    
    var errorToThrow: Error? = nil
    var foodCallCount = 0
    var categoryCallCount = 0
    
    func getFoods() async throws -> [FoodItem] {
        foodCallCount += 1
        if let error = errorToThrow { throw error }
        return mockFoods
    }
    
    func getCategories() async throws -> [Category] {
        categoryCallCount += 1
        if let error = errorToThrow { throw error }
        return mockCategories
    }
    
}

#endif
