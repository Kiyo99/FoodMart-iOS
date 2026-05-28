 # Issue Breakdown

Issues are organized in implementation order. Each phase builds on the last, so later issues can be picked up without rework.

---

## Phase 1 — Foundation

### Issue 1: Define data models

**Summary**  
Create the core data structures that the rest of the app depends on. These are derived directly from inspecting the API responses before any UI or networking code is written.

**Acceptance criteria**
- `FoodItem` model exists with `id`, `name`, `price`, `categoryUUID`, and `imageURL` fields
- `Category` model exists with `id` and `name` fields
- `PurchaseItem` model exists with `id`, `foodItem: FoodItem`, `quantity: Int`, and a computed `lineTotal`
- All models conform to `Codable`, `Identifiable`, and `Equatable` where appropriate
- `CodingKeys` map snake_case API field names to camelCase Swift properties

**Assumptions**
- The API returns UUIDs as strings; `UUID` type is used directly since JSONDecoder handles the conversion
- Quantity is tracked on `PurchaseItem` rather than on `FoodItem` — the food catalogue is read-only and quantity is a cart concept, not a product attribute
---

### Issue 2: Implement the networking layer

**Summary**  
Define a `FoodServiceProtocol` and a concrete `FoodService` implementation that fetches food items and categories from the provided API endpoints. Abstracting behind a protocol allows the implementation to be swapped for a mock in tests.

**Acceptance criteria**
- `FoodServiceProtocol` declares `getFoods() async throws -> [FoodItem]` and `getCategories() async throws -> [Category]`
- `FoodService` implements the protocol using `URLSession`
- `URLSession` is itself injected via a `URLSessionProtocol` to support future unit testing of the service layer
- Both endpoints are called using `async/await`
- Network errors propagate as thrown errors to the caller

**Assumptions**
- The API is read-only and unauthenticated; no auth headers are needed
- Response decoding failures are treated as errors and propagated up rather than silently ignored

---

### Issue 3: Implement MockFoodService for testing

**Summary**  
Create a `MockFoodService` that satisfies `FoodServiceProtocol` with in-memory fixture data. This powers both unit tests and UI test scenarios without hitting the real network.

**Acceptance criteria**
- `MockFoodService` provides three hardcoded `FoodItem` fixtures and three `Category` fixtures
- `errorToThrow: Error?` property allows tests to simulate failure
- Call counters (`FoodCallCount`, `CategoryCallCount`) allow tests to assert service interactions
- The class is only compiled in `DEBUG` builds
- `HomeViewModel.init` checks `ProcessInfo.processInfo.arguments` for `--testing-ui`, `--testing-ui-empty`, and `--testing-ui-error` and configures the mock accordingly so UI tests can drive different states via launch arguments

**Assumptions**
- `--testing-ui-empty` maps to empty food and category arrays
- `--testing-ui-error` maps to a thrown `URLError(.badServerResponse)` on all calls
- Fixture item IDs are random UUIDs; UI tests use predicate-based queries (`identifier BEGINSWITH 'foodRow_'`) rather than hard-coded IDs

---

## Phase 2 — Core Logic

### Issue 4: Implement HomeViewModel

**Summary**  
Build the single `@Observable` ViewModel shared across all screens. It owns fetch lifecycle, cart state, category filter selection, and sort order. Centralizing state here keeps the views thin and the logic testable.

**Acceptance criteria**
- `fetchFoodItems()` and `fetchCategories()` populate their respective arrays and clear `errorMessage` at the start of each call
- `errorMessage` is set on failure and cleared on the next successful fetch
- `addToCart(_ item:)` increments quantity if the item already exists in the cart, otherwise appends a new `PurchaseItem` with quantity 1
- `removeFromCart(_ item:)` removes the entire `PurchaseItem` entry regardless of quantity
- `purchase()` clears `cart: [PurchaseItem]` and sets `showPurchasedAlert = true`
- `quantityInCart(_ item:) -> Int` exposes per-item quantity for the food list badge
- `purchase()` clears the cart and sets `showPurchasedAlert = true`
- `selectedCategories: [Category]?` tracks active filter chips; `nil` means no filter applied
- `toggleCategory(_ category:)` adds or removes from `selectedCategories`
- `sortOrder: SortOrder` is `.priceAscending` by default and can be toggled
- `filteredFoodItems` computed property applies active category filter then sort in one pass
- `isInCart(_ item:) -> Bool` helper is exposed for the food list quantity badge
- `categoryName(for item:) -> String` resolves a display name from loaded categories
- ViewModel is `@MainActor` to keep all state mutations on the main thread

**Assumptions**
- A single ViewModel instance is injected at the app root via `@Environment` and shared across all tabs
- Sort and filter are client-side; no additional API calls are made when the user changes them

---

### Issue 5: Implement cart persistence with CartStore

**Summary**  
Persist the cart to a JSON file in the app's Documents directory so items survive app restarts. This is intentionally lightweight — no SwiftData, no CoreData.

**Acceptance criteria**
- `CartStore.save(_ items: [PurchaseItem])` encodes and writes atomically to `cart.json`
- `CartStore.load() -> [PurchaseItem]` decodes and returns saved items, or `[]` on any failure
- `CartStore.clear()` removes the file
- `HomeViewModel.cart` is initialized with `CartStore.load()` so the cart is populated before the first frame
- `addToCart`, `removeFromCart` call `save` after mutating; `purchase` calls `clear`
- No user-facing error is shown if persistence fails — the cart simply behaves as if it were in-memory

**Assumptions**
- I choose this over SwiftData and CoreData because of the time constraint and this is straightforward

---

## Phase 3 — UI

### Issue 6: Build reusable CategoryChip component

**Summary**  
A small pill-shaped chip that represents a single category. Stateless — it receives `isSelected` and an `onTap` closure from its parent. Lives in `Views/Common` for reuse.

**Acceptance criteria**
- Displays `category.name` in a capsule
- Filled blue background and white text when `isSelected == true`
- Light blue tint background and blue text when `isSelected == false`
- Tapping calls `onTap()`
- No internal state; fully controlled by the caller

**Assumptions**
- Font weight shifts to `.semibold` when selected as a subtle affordance; no additional animation is needed for the MVP

---

### Issue 7: Build reusable FoodItemRow component

**Summary**  
A single row representing a food item in the list. Shows thumbnail, name, category, price, and an always-visible add button with a quantity badge.

**Acceptance criteria**
- Displays item thumbnail via `AsyncImage` with a dark gray fallback
- Displays `item.name` (bold, blue) and `categoryName` (subheadline, gray)
- Displays formatted USD price
- `+` button (orange) always visible; tapping always adds one to the cart
- When `quantity > 0`, a blue badge overlays the button showing the current count
- Accessibility identifier `add_to_cart` on the button
- Accessibility label describes the action and item name

**Assumptions**
- Removal is handled on the cart screen, not the food list — the food list is purely additive
- The `quantity: Int` prop is passed in from the ViewModel; the row has no knowledge of cart state itself
- Image loading failures show a placeholder; no retry logic is implemented

---

### Issue 8: Build reusable CartItemRow component

**Summary**  
A single row for an item in the shopping cart. Shows thumbnail, name, line price, and a delete button.

**Acceptance criteria**
- Displays item thumbnail, `foodItem.name` (bold, blue), and quantity (`Qty: N`)
- Displays `lineTotal` (unit price × quantity) formatted as USD
- Delete button removes the entire entry (all quantity) and calls `onDelete()`
- Accessibility identifier `delete_cart_item` on the delete button

**Assumptions**
- Deleting removes the full entry rather than decrementing by one — fine-grained quantity adjustment is a future iteration

---

### Issue 9: Build FoodScreen

**Summary**  
The primary browsing screen. Shows the category chip strip with a sort button, then a scrollable list of food items filtered and sorted according to ViewModel state.

**Acceptance criteria**
- Shows `ProgressView` while `isLoading` is true (identifier: `loadingIndicator`)
- Shows error text when `errorMessage` is non-empty (identifier: `errorMessage`)
- Shows category chip strip (horizontal scroll) when categories are loaded; chip strip is hidden until then
- Sort button pinned to the right of the chip strip toggles between ascending and descending price order; icon reflects current order
- Food list uses `filteredFoodItems` (not `foodItems` directly) so filter and sort are always applied
- Each food row has identifier `foodRow_<item.id>`
- Shows empty message (identifier: `emptyFoodMessage`) when `filteredFoodItems` is empty
- Pull-to-refresh fires both fetch calls concurrently using `async let` inside `.refreshable` (no wrapping `Task`)

**Assumptions**
- Categories and food items are fetched at the `HomeScreen` level on `.task`, not inside `FoodScreen` itself
- The chip strip is hidden (not shown as empty) until categories arrive to avoid a jarring empty strip flash

---

### Issue 10: Build CartScreen

**Summary**  
The shopping cart screen. Displays cart items, a purchase button, and a confirmation alert.

**Acceptance criteria**
- Shows `ProgressView` while `isLoading` is true
- Shows error text when `errorMessage` is non-empty
- Shows empty message (identifier: `emptyCartMessage`) when cart is empty
- Shows a `CartItemRow` for each cart item (identifier: `cartRow_<item.id>`)
- "Purchase" button calls `viewModel.purchase()` and is always visible when cart content is shown
- `.alert` shows "Purchased!" after purchase using `Bindable(viewModel).$showPurchasedAlert`
- Pull-to-refresh re-fetches categories and food items concurrently

**Assumptions**
- The purchase button is always visible regardless of cart state so the user always knows where to go; it is simply a no-op on an empty cart at the server level

---

### Issue 11: Build HomeScreen with tab navigation

**Summary**  
Root screen that owns tab state and injects the ViewModel into the environment. Hosts a custom bottom tab bar switching between `FoodScreen` and `CartScreen`.

**Acceptance criteria**
- Two tabs: "Food" (`fork.knife` icon) and "Cart" (`cart` icon)
- Selected tab is highlighted in blue; unselected in gray
- Each tab button has an accessibility identifier `tab_<rawValue>`
- Data fetch (`fetchCategories` and `fetchFoodItems`) fires on `.task` using `async let` so both calls are concurrent
- Fetch is guarded with `foodItems.isEmpty` to avoid re-fetching on every appearance
- ViewModel is initialized at this level and passed into the environment

**Acceptance criteria (additional)**
- Cart tab shows a blue badge with the total item quantity when the cart is non-empty

**Assumptions**
- A custom tab bar is used instead of `TabView` to keep full control over layout and styling
- Total quantity (sum of all `PurchaseItem.quantity`) is shown rather than distinct item count, which is the more natural number from a user's perspective

---

## Phase 4 — Testing

### Issue 12: Unit test HomeViewModel

**Summary**  
Cover all meaningful ViewModel behaviour: fetch lifecycle, error handling, cart operations, filter logic, and sort logic. Uses `MockFoodService` for full isolation.

**Acceptance criteria**
- Initial state assertions (empty arrays, no loading, no error, sort ascending)
- `fetchFoodItems` and `fetchCategories`: success populates data, failure sets error, empty response is handled, `errorMessage` clears on subsequent success
- Call count assertions to verify single service invocations
- Cart: add creates a `PurchaseItem`; adding the same item again increments quantity on the existing entry; adding different items creates separate entries; remove deletes the full entry regardless of quantity; purchase clears cart and sets alert
- `quantityInCart` returns correct count before and after mutations
- `isInCart` returns correct values before and after mutations
- `filteredFoodItems`: no selection returns all, single category filters correctly, multiple categories stack, deselecting restores full list
- Sort ascending and descending produce correct ordering
- `toggleCategory` adds, removes, and stacks correctly

**Assumptions**
- `CartStore.clear()` is called in `setUp` and `tearDown` to prevent file system state leaking between test runs
- ViewModel properties (`foodItems`, `categories`) are set directly in filter/sort tests rather than going through fetch, keeping those tests fast and isolated

---

### Issue 13: UI test key user flows

**Summary**  
End-to-end tests that drive the real app process via launch arguments. Covers happy path, empty state, error state, cart toggle, and tab navigation.

**Acceptance criteria**
- Food screen loads items with `--testing-ui`
- Empty state shows message and hides rows with `--testing-ui-empty`
- Error state shows error text, hides items, hides loading indicator, hides empty message with `--testing-ui-error`
- Add-to-cart button remains visible and tappable after adding (no toggle — food list is purely additive)
- Tapping add twice then navigating to cart shows a single cart row (quantity stacked, not duplicated)
- Cart is empty by default; shows a cart row after an item is added from the food screen
- Removing the item from the cart screen restores the empty message
- Tab switching navigates between screens; cart state is preserved across tab switches

**Assumptions**
- UUID-based row identifiers (`foodRow_<uuid>`, `cartRow_<uuid>`) are queried with `NSPredicate` (`BEGINSWITH`) rather than exact match since UUIDs are not predictable at test time
- `continueAfterFailure = false` is set so a broken launch does not cascade through all tests
