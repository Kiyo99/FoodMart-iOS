//
//  HomeViewModelTests.swift
//  FoodMartTests
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import XCTest
@testable import FoodMart

@MainActor
final class HomeViewModelTests: XCTestCase {

    // MARK: - Properties
    var homeViewModel: HomeViewModel!
    var mockFoodService: MockFoodService!

    // MARK: - Setup and Teardown
    override func setUp() {
        super.setUp()
        CartStore.clear()
        mockFoodService = MockFoodService()
        homeViewModel = HomeViewModel(repo: mockFoodService)
    }

    override func tearDown() {
        CartStore.clear()
        homeViewModel = nil
        mockFoodService = nil
        super.tearDown()
    }

    // MARK: - Initial State
    func test_initial_vm_state() {
        XCTAssertTrue(homeViewModel.foodItems.isEmpty)
        XCTAssertTrue(homeViewModel.categories.isEmpty)
        XCTAssertTrue(homeViewModel.cart.isEmpty)
        XCTAssertTrue(homeViewModel.errorMessage.isEmpty)
        XCTAssertNil(homeViewModel.selectedCategories)
        XCTAssertFalse(homeViewModel.showPurchasedAlert)
    }

    func test_initial_sortOrder_isAscending() {
        XCTAssertEqual(homeViewModel.sortOrder, .priceAscending)
    }

    // MARK: - fetchFoodItems Happy Paths
    func testFetchFoodItems_Success_Populates() async {
        // Act
        await homeViewModel.fetchFoodItems()

        // Assert
        XCTAssertEqual(homeViewModel.foodItems.count, 3)
    }

    func testFetchFoodItems_CallsServiceOnce() async {
        // Act
        await homeViewModel.fetchFoodItems()

        // Assert
        XCTAssertEqual(mockFoodService.foodCallCount, 1)
    }

    func testFetchFoodItems_WithEmptyArray_Works() async {
        // Arrange
        mockFoodService.mockFoods = []

        // Act
        await homeViewModel.fetchFoodItems()

        // Assert
        XCTAssertTrue(homeViewModel.foodItems.isEmpty)
        XCTAssertTrue(homeViewModel.errorMessage.isEmpty)
    }

    // MARK: - fetchFoodItems Failure Paths
    func testFetchFoodItems_Failure_SetsErrorMessage() async {
        // Arrange
        mockFoodService.errorToThrow = URLError(.badServerResponse)

        // Act
        await homeViewModel.fetchFoodItems()

        // Assert
        XCTAssertFalse(homeViewModel.errorMessage.isEmpty)
        XCTAssertTrue(homeViewModel.foodItems.isEmpty)
    }

    func testFetchFoodItems_Failure_ClearsExistingItems() async {
        // Arrange
        homeViewModel.foodItems = mockFoodService.mockFoods
        mockFoodService.errorToThrow = URLError(.notConnectedToInternet)

        // Act
        await homeViewModel.fetchFoodItems()

        // Assert — fetch clears items before the request; failure leaves them empty
        XCTAssertTrue(homeViewModel.foodItems.isEmpty)
    }

    func testErrorMessageClears_AfterSuccessfulFetch_FromPreviousFailure() async {
        // Arrange
        homeViewModel.errorMessage = "Previous error"

        // Act
        await homeViewModel.fetchFoodItems()

        // Assert
        XCTAssertTrue(homeViewModel.errorMessage.isEmpty)
    }

    // MARK: - fetchCategories Happy Paths
    func testFetchCategories_Success_Populates() async {
        // Act
        await homeViewModel.fetchCategories()

        // Assert
        XCTAssertEqual(homeViewModel.categories.count, 3)
    }

    func testFetchCategories_CallsServiceOnce() async {
        // Act
        await homeViewModel.fetchCategories()

        // Assert
        XCTAssertEqual(mockFoodService.categoryCallCount, 1)
    }

    func testFetchCategories_WithEmptyArray_Works() async {
        // Arrange
        mockFoodService.mockCategories = []

        // Act
        await homeViewModel.fetchCategories()

        // Assert
        XCTAssertTrue(homeViewModel.categories.isEmpty)
        XCTAssertTrue(homeViewModel.errorMessage.isEmpty)
    }

    // MARK: - fetchCategories Failure Paths
    func testFetchCategories_Failure_SetsErrorMessage() async {
        // Arrange
        mockFoodService.errorToThrow = URLError(.badServerResponse)

        // Act
        await homeViewModel.fetchCategories()

        // Assert
        XCTAssertFalse(homeViewModel.errorMessage.isEmpty)
        XCTAssertTrue(homeViewModel.categories.isEmpty)
    }

    func testCategoryErrorMessageClears_AfterSuccessfulFetch_FromPreviousFailure() async {
        // Arrange
        homeViewModel.errorMessage = "Previous error"

        // Act
        await homeViewModel.fetchCategories()

        // Assert
        XCTAssertTrue(homeViewModel.errorMessage.isEmpty)
    }

    // MARK: - Cart Operations
    func testAddToCart_AddsItem() {
        // Arrange
        let item = mockFoodService.mockFoods[0]

        // Act
        homeViewModel.addToCart(item)

        // Assert
        XCTAssertEqual(homeViewModel.cart.count, 1)
        XCTAssertEqual(homeViewModel.cart.first?.foodItem.id, item.id)
    }

    func testAddToCart_SameItem_IncreasesQuantity() {
        // Arrange
        let item = mockFoodService.mockFoods[0]

        // Act
        homeViewModel.addToCart(item)
        homeViewModel.addToCart(item)

        // Assert — one entry, quantity of 2
        XCTAssertEqual(homeViewModel.cart.count, 1)
        XCTAssertEqual(homeViewModel.cart.first?.quantity, 2)
    }

    func testAddToCart_DifferentItems_CreateSeparateEntries() {
        // Arrange
        let first = mockFoodService.mockFoods[0]
        let second = mockFoodService.mockFoods[1]

        // Act
        homeViewModel.addToCart(first)
        homeViewModel.addToCart(second)

        // Assert
        XCTAssertEqual(homeViewModel.cart.count, 2)
    }

    func testRemoveFromCart_RemovesEntry() {
        // Arrange
        let item = mockFoodService.mockFoods[0]
        homeViewModel.addToCart(item)

        // Act
        homeViewModel.removeFromCart(item)

        // Assert
        XCTAssertTrue(homeViewModel.cart.isEmpty)
    }

    func testRemoveFromCart_RemovesEntireEntry_RegardlessOfQuantity() {
        // Arrange
        let item = mockFoodService.mockFoods[0]
        homeViewModel.addToCart(item)
        homeViewModel.addToCart(item)
        homeViewModel.addToCart(item)

        // Act
        homeViewModel.removeFromCart(item)

        // Assert — all quantity removed, not just decremented
        XCTAssertTrue(homeViewModel.cart.isEmpty)
    }

    func testRemoveFromCart_OnlyRemovesMatchingItem() {
        // Arrange
        let first = mockFoodService.mockFoods[0]
        let second = mockFoodService.mockFoods[1]
        homeViewModel.addToCart(first)
        homeViewModel.addToCart(second)

        // Act
        homeViewModel.removeFromCart(first)

        // Assert
        XCTAssertEqual(homeViewModel.cart.count, 1)
        XCTAssertEqual(homeViewModel.cart.first?.foodItem.id, second.id)
    }

    func testRemoveFromCart_ItemNotInCart_DoesNothing() {
        // Arrange
        let item = mockFoodService.mockFoods[0]

        // Act
        homeViewModel.removeFromCart(item)

        // Assert
        XCTAssertTrue(homeViewModel.cart.isEmpty)
    }

    func testQuantityInCart_ReflectsAddCount() {
        // Arrange
        let item = mockFoodService.mockFoods[0]

        // Act
        homeViewModel.addToCart(item)
        homeViewModel.addToCart(item)
        homeViewModel.addToCart(item)

        // Assert
        XCTAssertEqual(homeViewModel.quantityInCart(item), 3)
    }

    func testQuantityInCart_IsZeroWhenNotInCart() {
        // Arrange
        let item = mockFoodService.mockFoods[0]

        // Act & Assert
        XCTAssertEqual(homeViewModel.quantityInCart(item), 0)
    }

    func testQuantityInCart_IsZeroAfterRemoval() {
        // Arrange
        let item = mockFoodService.mockFoods[0]
        homeViewModel.addToCart(item)
        homeViewModel.addToCart(item)

        // Act
        homeViewModel.removeFromCart(item)

        // Assert
        XCTAssertEqual(homeViewModel.quantityInCart(item), 0)
    }

    func testPurchase_ClearsCart() {
        // Arrange
        homeViewModel.addToCart(mockFoodService.mockFoods[0])

        // Act
        homeViewModel.purchase()

        // Assert
        XCTAssertTrue(homeViewModel.cart.isEmpty)
    }

    func testPurchase_ShowsAlert() {
        // Act
        homeViewModel.purchase()

        // Assert
        XCTAssertTrue(homeViewModel.showPurchasedAlert)
    }

    func testIsInCart_ReturnsTrueWhenInCart() {
        // Arrange
        let item = mockFoodService.mockFoods[0]
        homeViewModel.addToCart(item)

        // Act & Assert
        XCTAssertTrue(homeViewModel.isInCart(item))
    }

    func testIsInCart_ReturnsFalseWhenNotInCart() {
        // Arrange
        let item = mockFoodService.mockFoods[0]

        // Act & Assert
        XCTAssertFalse(homeViewModel.isInCart(item))
    }

    func testIsInCart_RemainsTrue_AfterMultipleAdds() {
        // Arrange
        let item = mockFoodService.mockFoods[0]

        // Act
        homeViewModel.addToCart(item)
        homeViewModel.addToCart(item)

        // Assert
        XCTAssertTrue(homeViewModel.isInCart(item))
    }

    // MARK: - categoryName
    func testCategoryName_ReturnsCorrectName_WhenFound() async {
        // Arrange
        await homeViewModel.fetchCategories()
        let item = mockFoodService.mockFoods[0] // Apple → fruitID

        // Act & Assert
        XCTAssertEqual(homeViewModel.categoryName(for: item), "Fruit")
    }

    func testCategoryName_ReturnsEmpty_WhenNotFound() {
        // Arrange — no categories loaded, unknown categoryUUID
        let item = FoodItem(id: UUID(), name: "Mystery", price: 1.00, categoryUUID: UUID(), imageURL: "")

        // Act & Assert
        XCTAssertTrue(homeViewModel.categoryName(for: item).isEmpty)
    }

    // MARK: - Cart persistence
    func testCartPersistence_SurvivesViewModelRecreation() {
        // Arrange — add items with the current VM (triggers CartStore.save)
        let item = mockFoodService.mockFoods[0]
        homeViewModel.addToCart(item)
        homeViewModel.addToCart(item) // quantity = 2

        // Act — new VM instance reads from disk
        let newViewModel = HomeViewModel(repo: mockFoodService)

        // Assert
        XCTAssertEqual(newViewModel.cart.count, 1)
        XCTAssertEqual(newViewModel.cart.first?.foodItem.id, item.id)
        XCTAssertEqual(newViewModel.cart.first?.quantity, 2)
    }

    // MARK: - Category Filter
    func testFilteredFoodItems_NoSelection_ReturnsAll() async {
        // Arrange
        await homeViewModel.fetchFoodItems()

        // Act & Assert
        XCTAssertEqual(homeViewModel.filteredFoodItems.count, homeViewModel.foodItems.count)
    }

    func testFilteredFoodItems_SingleSelection_FiltersCorrectly() async {
        // Arrange
        let targetCategory = Category(id: UUID(), name: "Fruit")
        let otherCategory = Category(id: UUID(), name: "Snack")
        homeViewModel.foodItems = [
            FoodItem(id: UUID(), name: "Apple", price: 1.00, categoryUUID: targetCategory.id, imageURL: ""),
            FoodItem(id: UUID(), name: "Chips", price: 2.00, categoryUUID: otherCategory.id, imageURL: "")
        ]

        // Act
        homeViewModel.toggleCategory(targetCategory)

        // Assert
        XCTAssertEqual(homeViewModel.filteredFoodItems.count, 1)
        XCTAssertEqual(homeViewModel.filteredFoodItems.first?.name, "Apple")
    }

    func testFilteredFoodItems_MultipleSelections_FiltersCorrectly() async {
        // Arrange
        let fruit = Category(id: UUID(), name: "Fruit")
        let snack = Category(id: UUID(), name: "Snack")
        let drink = Category(id: UUID(), name: "Drink")
        homeViewModel.foodItems = [
            FoodItem(id: UUID(), name: "Apple", price: 1.00, categoryUUID: fruit.id, imageURL: ""),
            FoodItem(id: UUID(), name: "Chips", price: 2.00, categoryUUID: snack.id, imageURL: ""),
            FoodItem(id: UUID(), name: "Water", price: 3.00, categoryUUID: drink.id, imageURL: "")
        ]

        // Act
        homeViewModel.toggleCategory(fruit)
        homeViewModel.toggleCategory(snack)

        // Assert
        XCTAssertEqual(homeViewModel.filteredFoodItems.count, 2)
    }

    func testFilteredFoodItems_DeselectedCategory_ShowsAll() async {
        // Arrange
        let category = Category(id: UUID(), name: "Fruit")
        homeViewModel.foodItems = [
            FoodItem(id: UUID(), name: "Apple", price: 1.00, categoryUUID: category.id, imageURL: "")
        ]
        homeViewModel.toggleCategory(category)

        // Act — toggle off
        homeViewModel.toggleCategory(category)

        // Assert
        XCTAssertEqual(homeViewModel.filteredFoodItems.count, 1)
    }

    func testFilteredFoodItems_FilterAndSortCombined() {
        // Arrange — two fruit items at different prices, one snack
        let fruit = Category(id: UUID(), name: "Fruit")
        let snack = Category(id: UUID(), name: "Snack")
        homeViewModel.foodItems = [
            FoodItem(id: UUID(), name: "Banana", price: 2.00, categoryUUID: fruit.id, imageURL: ""),
            FoodItem(id: UUID(), name: "Apple",  price: 1.00, categoryUUID: fruit.id, imageURL: ""),
            FoodItem(id: UUID(), name: "Chips",  price: 3.00, categoryUUID: snack.id, imageURL: "")
        ]
        homeViewModel.sortOrder = .priceAscending

        // Act
        homeViewModel.toggleCategory(fruit)

        // Assert — only fruit items, cheapest first
        XCTAssertEqual(homeViewModel.filteredFoodItems.count, 2)
        XCTAssertEqual(homeViewModel.filteredFoodItems[0].name, "Apple")
        XCTAssertEqual(homeViewModel.filteredFoodItems[1].name, "Banana")
    }

    // MARK: - Sort
    func testFilteredFoodItems_SortAscending() {
        // Arrange
        homeViewModel.foodItems = [
            FoodItem(id: UUID(), name: "Expensive", price: 9.99, categoryUUID: UUID(), imageURL: ""),
            FoodItem(id: UUID(), name: "Cheap", price: 1.00, categoryUUID: UUID(), imageURL: "")
        ]
        homeViewModel.sortOrder = .priceAscending

        // Act & Assert
        XCTAssertEqual(homeViewModel.filteredFoodItems.first?.name, "Cheap")
    }

    func testFilteredFoodItems_SortDescending() {
        // Arrange
        homeViewModel.foodItems = [
            FoodItem(id: UUID(), name: "Cheap", price: 1.00, categoryUUID: UUID(), imageURL: ""),
            FoodItem(id: UUID(), name: "Expensive", price: 9.99, categoryUUID: UUID(), imageURL: "")
        ]
        homeViewModel.sortOrder = .priceDescending

        // Act & Assert
        XCTAssertEqual(homeViewModel.filteredFoodItems.first?.name, "Expensive")
    }

    func testSortOrder_Toggles() {
        // Arrange — starts ascending
        XCTAssertEqual(homeViewModel.sortOrder, .priceAscending)

        // Act
        homeViewModel.sortOrder = homeViewModel.sortOrder.toggled

        // Assert
        XCTAssertEqual(homeViewModel.sortOrder, .priceDescending)
    }

    // MARK: - toggleCategory
    func testToggleCategory_AddsWhenNotSelected() {
        // Arrange
        let category = Category(id: UUID(), name: "Fruit")

        // Act
        homeViewModel.toggleCategory(category)

        // Assert
        XCTAssertEqual(homeViewModel.selectedCategories?.count, 1)
    }

    func testToggleCategory_RemovesWhenAlreadySelected() {
        // Arrange
        let category = Category(id: UUID(), name: "Fruit")
        homeViewModel.toggleCategory(category)

        // Act
        homeViewModel.toggleCategory(category)

        // Assert
        XCTAssertTrue(homeViewModel.selectedCategories?.isEmpty ?? true)
    }

    func testToggleCategory_MultipleCategories_StackCorrectly() {
        // Arrange
        let fruit = Category(id: UUID(), name: "Fruit")
        let snack = Category(id: UUID(), name: "Snack")

        // Act
        homeViewModel.toggleCategory(fruit)
        homeViewModel.toggleCategory(snack)

        // Assert
        XCTAssertEqual(homeViewModel.selectedCategories?.count, 2)
    }
}
