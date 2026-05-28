//
//  HomeViewModel.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import SwiftUI

enum SortOrder {
    case priceAscending, priceDescending

    var toggled: SortOrder {
        self == .priceAscending ? .priceDescending : .priceAscending
    }

    var icon: String {
        self == .priceAscending ? "arrow.up" : "arrow.down"
    }
}

@Observable
@MainActor
class HomeViewModel {
    // injecting repo for testability
    private let repo: FoodServiceProtocol
    
    init(
        repo: FoodServiceProtocol? = nil
    ){
#if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--testing-ui-error") {
            let mock = MockFoodService()
            mock.errorToThrow = URLError(.badServerResponse)
            self.repo = mock
            self.cart = []
            CartStore.clear()
            return
        }
        if args.contains("--testing-ui-empty") {
            let mock = MockFoodService()
            mock.mockFoods = []
            mock.mockCategories = []
            self.repo = mock
            self.cart = []
            CartStore.clear()
            return
        }
        if args.contains("--testing-ui") {
            self.repo = MockFoodService()
            self.cart = []
            CartStore.clear()
            return
        }
#endif
        self.repo = repo ?? FoodService()
        self.cart = CartStore.load()
    }
    
    // MARK: - state
    var foodItems: [FoodItem] = []
    var categories: [Category] = []
    var cart: [PurchaseItem]
    
    // MARK: - UI State
    var selectedCategories: [Category]? = nil
    var sortOrder: SortOrder = .priceAscending
    var isFoodLoading: Bool = false
    var isCategoryLoading: Bool = false
    var errorMessage: String = ""
    var showPurchasedAlert: Bool = false
    
    /// Returns the category name for a given food item, or empty string if not found.
    func categoryName(for item: FoodItem) -> String {
        categories.first { $0.id == item.categoryUUID }?.name ?? ""
    }
    
    
    // MARK: - Computed
    var filteredFoodItems: [FoodItem] {
        let base: [FoodItem]
        if let selected = selectedCategories, !selected.isEmpty {
            let ids = Set(selected.map(\.id))
            base = foodItems.filter { ids.contains($0.categoryUUID) }
        } else {
            base = foodItems
        }
        return base.sorted { sortOrder == .priceAscending ? $0.price < $1.price : $0.price > $1.price }
    }

    func isInCart(_ item: FoodItem) -> Bool {
        cart.contains { $0.foodItem.id == item.id }
    }

    func quantityInCart(_ item: FoodItem) -> Int {
        cart.first { $0.foodItem.id == item.id }?.quantity ?? 0
    }

    // MARK: - Local methods
    func toggleCategory(_ category: Category) {
        if selectedCategories == nil { selectedCategories = [] }
        if let idx = selectedCategories!.firstIndex(where: { $0.id == category.id }) {
            selectedCategories!.remove(at: idx)
        } else {
            selectedCategories!.append(category)
        }
    }

    func addToCart(_ item: FoodItem) {
        if let idx = cart.firstIndex(where: { $0.foodItem.id == item.id }) {
            cart[idx].quantity += 1
        } else {
            cart.append(PurchaseItem(id: UUID(), foodItem: item, quantity: 1))
        }
        CartStore.save(cart)
    }

    func removeFromCart(_ item: FoodItem) {
        cart.removeAll { $0.foodItem.id == item.id }
        CartStore.save(cart)
    }

    func purchase() {
        cart = []
        CartStore.clear()
        showPurchasedAlert = true
    }
    
    // MARK: - Fetch Methods
    
    func fetchCategories() async {
        isCategoryLoading = true
        defer { isCategoryLoading = false }
        self.categories = []
        self.errorMessage = ""
        do {
            self.categories = try await repo.getCategories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchFoodItems() async {
        self.foodItems = []
        self.errorMessage = ""
        isFoodLoading = true
        defer { isFoodLoading = false }
        do {
            self.foodItems = try await repo.getFoods()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
