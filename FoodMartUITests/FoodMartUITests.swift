//
//  FoodMartUITests.swift
//  FoodMartUITests
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import XCTest

final class FoodMartUITests: XCTestCase {
    var app: XCUIApplication!

    // MARK: - Setup and Teardown
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--testing-ui"]
        app.launch()
    }

    override func tearDown() {
        app = nil
    }

    // MARK: - Helpers
    func findElement(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    func firstFoodRow() -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'foodRow_'"))
            .firstMatch
    }

    func firstCartRow() -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'cartRow_'"))
            .firstMatch
    }

    func relaunch(with arguments: [String]) {
        app.terminate()
        app.launchArguments = arguments
        app.launch()
    }

    // MARK: - Food Screen: Happy Path
    func testFoodScreen_LoadsItems() {
        XCTAssertTrue(firstFoodRow().waitForExistence(timeout: 5))
    }

    func testFoodScreen_PullToRefresh_ReloadsItems() {
        let row = firstFoodRow()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeDown()
        XCTAssertTrue(firstFoodRow().waitForExistence(timeout: 5))
    }

    // MARK: - Food Screen: Empty State
    func testFoodScreen_EmptyState_ShowsMessage() {
        relaunch(with: ["--testing-ui-empty"])
        XCTAssertTrue(findElement("emptyFoodMessage").waitForExistence(timeout: 5))
        XCTAssertFalse(firstFoodRow().exists)
    }

    // MARK: - Food Screen: Error State
    func testFoodScreen_ErrorState_ShowsErrorMessage() {
        relaunch(with: ["--testing-ui-error"])
        XCTAssertTrue(findElement("errorMessage").waitForExistence(timeout: 5))
    }

    func testFoodScreen_ErrorState_DoesNotShowItems() {
        relaunch(with: ["--testing-ui-error"])
        _ = findElement("errorMessage").waitForExistence(timeout: 5)
        XCTAssertFalse(firstFoodRow().exists)
    }

    func testFoodScreen_ErrorState_DoesNotShowEmptyMessage() {
        relaunch(with: ["--testing-ui-error"])
        _ = findElement("errorMessage").waitForExistence(timeout: 5)
        XCTAssertFalse(findElement("emptyFoodMessage").exists)
    }

    // MARK: - Cart Add
    func testAddToCart_ButtonRemainsAddable() {
        // + always stays — multiple taps means multiple quantity, not a toggle
        XCTAssertTrue(firstFoodRow().waitForExistence(timeout: 5))
        findElement("add_to_cart").firstMatch.tap()
        XCTAssertTrue(findElement("add_to_cart").waitForExistence(timeout: 2))
    }

    func testAddToCart_MultipleTimesShowsInCart() {
        XCTAssertTrue(firstFoodRow().waitForExistence(timeout: 5))
        findElement("add_to_cart").firstMatch.tap()
        findElement("add_to_cart").firstMatch.tap()
        findElement("tab_Cart").tap()
        XCTAssertTrue(firstCartRow().waitForExistence(timeout: 5))
    }

    // MARK: - Cart Screen: Empty State
    func testCart_EmptyByDefault() {
        findElement("tab_Cart").tap()
        XCTAssertTrue(findElement("emptyCartMessage").waitForExistence(timeout: 5))
    }

    func testCart_EmptyState_DoesNotShowCartRows() {
        findElement("tab_Cart").tap()
        _ = findElement("emptyCartMessage").waitForExistence(timeout: 5)
        XCTAssertFalse(firstCartRow().exists)
    }

    // MARK: - Cart Screen: With Items
    func testCart_ShowsItemAfterAdd() {
        XCTAssertTrue(firstFoodRow().waitForExistence(timeout: 5))
        findElement("add_to_cart").firstMatch.tap()
        findElement("tab_Cart").tap()
        XCTAssertTrue(firstCartRow().waitForExistence(timeout: 5))
        XCTAssertFalse(findElement("emptyCartMessage").exists)
    }

    func testCart_RemoveItem_ShowsEmptyMessage() {
        // Add item
        XCTAssertTrue(firstFoodRow().waitForExistence(timeout: 5))
        findElement("add_to_cart").firstMatch.tap()

        // Go to cart and delete
        findElement("tab_Cart").tap()
        XCTAssertTrue(firstCartRow().waitForExistence(timeout: 5))
        findElement("delete_cart_item").firstMatch.tap()

        XCTAssertTrue(findElement("emptyCartMessage").waitForExistence(timeout: 3))
    }

    // MARK: - Purchase Flow
    func testPurchase_ClearsCartAndShowsAlert() {
        // Arrange — add an item
        XCTAssertTrue(firstFoodRow().waitForExistence(timeout: 5))
        findElement("add_to_cart").firstMatch.tap()

        // Navigate to cart and verify item is there
        findElement("tab_Cart").tap()
        XCTAssertTrue(firstCartRow().waitForExistence(timeout: 5))

        // Act — tap Purchase
        findElement("purchaseButton").tap()

        // Assert — alert appears
        XCTAssertTrue(app.alerts["Purchased!"].waitForExistence(timeout: 3))

        // Dismiss and verify cart is empty
        app.alerts["Purchased!"].buttons["OK"].tap()
        XCTAssertTrue(findElement("emptyCartMessage").waitForExistence(timeout: 3))
    }

    // MARK: - Category Filter
    func testCategoryChip_FiltersFoodList() {
        XCTAssertTrue(firstFoodRow().waitForExistence(timeout: 5))
        let rows = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'foodRow_'"))
        XCTAssertEqual(rows.count, 3)

        // Wait for the chip strip to render, then tap Fruit
        let fruitChip = findElement("chip_Fruit")
        XCTAssertTrue(fruitChip.waitForExistence(timeout: 3))
        fruitChip.tap()

        // Wait for SwiftUI to re-render filtered list — only Apple belongs to Fruit
        wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(block: { _, _ in rows.count == 1 }),
            object: nil
        )], timeout: 3)

        // Deselect — all items return
        fruitChip.tap()
        wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(block: { _, _ in rows.count == 3 }),
            object: nil
        )], timeout: 3)
    }

    // MARK: - Tab Navigation
    func testTabSwitch_ToCart() {
        findElement("tab_Cart").tap()
        XCTAssertTrue(findElement("emptyCartMessage").waitForExistence(timeout: 5))
        XCTAssertFalse(firstFoodRow().exists)
    }

    func testTabSwitch_BackToFood() {
        findElement("tab_Cart").tap()
        findElement("tab_Food").tap()
        XCTAssertTrue(firstFoodRow().waitForExistence(timeout: 5))
    }

    func testTabSwitch_CartState_PersistedAcrossTabs() {
        // Add to cart on Food tab
        XCTAssertTrue(firstFoodRow().waitForExistence(timeout: 5))
        findElement("add_to_cart").firstMatch.tap()

        // Switch away and back
        findElement("tab_Cart").tap()
        findElement("tab_Food").tap()

        // Cart row should still exist on food tab switch back
        findElement("tab_Cart").tap()
        XCTAssertTrue(firstCartRow().waitForExistence(timeout: 2))
    }
}
