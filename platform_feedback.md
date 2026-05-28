# Platform Feedback

Wrapping up the first iteration of FoodMart. Below is what I'd propose the mobile team standardize or abstract to make future feature delivery faster and more repeatable.

---

## 1. Reusable networking request abstraction

Every fetch function today follows the same pattern: set `isLoading`, clear `errorMessage`, call the repo, handle success, handle failure, unset `isLoading`. That's boilerplate that will be copy-pasted into every new endpoint.

I'd introduce a generic `perform` helper on the ViewModel base (or as a free function) so developers define only what's unique to their endpoint:

```swift
// A private, generic helper function to handle all network requests
    private func performRequest<T: Decodable>(
        method: String = "GET",
        pathComponents: [String],
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil,
        contentType: String? = nil,
        decoder: JSONDecoder = JSONDecoder(),
        addHeaders: Bool = false
    ) async throws -> T {
    // repeat URL validation
    }
```

New endpoints adhere to this and become much shorter. The pattern is consistent and testable in one place.

---

## 2. Typed error handling

`errorMessage: String` works for one screen but doesn't scale. A raw string can't be acted on — the UI can't distinguish "no internet" (retry makes sense) from "item not found" (retry doesn't). I'd introduce an `AppError` enum:

```swift
enum AppError: Error {
    case network(URLError)
    case decoding
    case server(statusCode: Int)
    case unknown
}
```

The ViewModel holds `var appError: AppError?` instead of a string. Views pattern-match on it to show the right message and the right action (retry button, empty state, alert). The string for display is derived from the enum, not stored raw.

---

## 3. Shared design tokens and reusable styling

I would standardize:
    - spacing values
    - typography
    - colors
    - button styles
    - row styling
    - icon usage

into reusable SwiftUI modifiers and shared components. This would improve visual consistency while reducing repeated styling code across features.

---

## 4. Component library in `Views/Common`

`CategoryChip`, `FoodItemRow`, and `CartItemRow` are already in `Common` — that's the right instinct I feel. I would abstract as many components as can be re-used here. As the app grows, this folder becomes the first place a new developer looks before building a new view. 

---

## 5. Standardize folder structure

Current structure mixes conventions. I'd standardize on feature-scoped folders:

```
Views/
  Food/
    FoodScreen.swift
    FoodViewModel.swift       ← feature-owned VM if it splits off
  Cart/
    CartScreen.swift
  Home/
    HomeScreen.swift
    HomeViewModel.swift
Common/                       ← shared, stateless components only
Core/                         ← app-wide services and utilities
Models/
Repositories/
  Protocols/
  Implementations/
```

The rule: a file lives in a feature folder if it belongs to one feature, in `Common` if it's reused across features, and in `Core` if it's infrastructure. Enforcing this now prevents the flat-file sprawl that makes large codebases hard to navigate.

---

## 6. Generic persistence store, not just CartStore

`CartStore` is a thin JSON read/write wrapper. The same three methods (`save`, `load`, `clear`) will be needed for any offline-first data. Extract a generic `JSONStore<T: Codable>`:

```swift
struct JSONStore<T: Codable> {
    let filename: String
    func save(_ value: T) { ... }
    func load() -> T? { ... }
    func clear() { ... }
}
```

`CartStore` becomes `JSONStore<[PurchaseItem]>(filename: "cart.json")`. Future stores (user preferences, cached categories) follow the same pattern without new boilerplate.

---

## 7. Network layer tests

The `URLSessionProtocol` abstraction is already in place to support this — it just hasn't been exercised yet. I'd add `FoodServiceTests` that inject a mock `URLSession` and assert on:

- Correct URLs being constructed
- Decoding succeeding on well-formed fixture JSON
- Decoding failing gracefully on malformed JSON
- HTTP error codes propagating as typed errors

These tests catch API contract drift (the server changes a field name, `CodingKeys` breaks) without needing to hit the network.

---

## 8. CI pipeline with test gate

None of the tests run automatically today. I'd add a GitHub Actions workflow (or XCode cloud equivalent) that runs the unit test suite on every PR. UI tests can be gated separately since they're slower. The key rule: a PR cannot merge if unit tests fail. This makes the test suite meaningful rather than aspirational.

---

## 9. Accessibility beyond identifiers

The current accessibility identifiers serve the test suite, not VoiceOver users. Before shipping, each interactive element needs a `.accessibilityLabel` (already partially done), `.accessibilityHint` for non-obvious actions, and correct `.accessibilityTraits`. Rows using `.accessibilityElement(children: .combine)` need a synthesized label that makes sense when read aloud. Making this a standard review checklist item prevents accessibility debt from accumulating.

## 10. Image caching
Additional image caching beyond the default AsyncImage behavior was intentionally omitted for this iteration because the application only loads a small set of lightweight thumbnail images. Introducing a dedicated caching library at this stage would add complexity without significant user benefit.

If the catalogue size, image quality, offline requirements, or scrolling performance requirements increased, I would evaluate introducing a more robust image loading and caching solution.
