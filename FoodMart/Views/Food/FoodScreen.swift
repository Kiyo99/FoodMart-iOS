//
//  FoodScreen.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//
import SwiftUI

struct FoodScreen: View {
    @Environment(HomeViewModel.self) private var viewModel

    var body: some View {
        VStack {
            if viewModel.isFoodLoading {
                ProgressView()
                    .accessibilityIdentifier("loadingIndicator")
            }
            else if !viewModel.errorMessage.isEmpty {
                Text("Error: \(viewModel.errorMessage)")
                    .accessibilityIdentifier("errorMessage")
            }
            else {
                VStack(spacing: 0) {
                    if !viewModel.categories.isEmpty {
                        HStack(spacing: 0) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.categories) { category in
                                        CategoryChip(
                                            category: category,
                                            isSelected: viewModel.selectedCategories?.contains(where: { $0.id == category.id }) ?? false,
                                            onTap: { viewModel.toggleCategory(category) }
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }

                            Button {
                                viewModel.sortOrder = viewModel.sortOrder.toggled
                            } label: {
                                Image(systemName: viewModel.sortOrder.icon)
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundStyle(.blue)
                                    .frame(width: 36, height: 36)
                                    .background(Color.blue.opacity(0.1), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 16)
                        }
                    }

                    ScrollView {
                        VStack {
                            if viewModel.filteredFoodItems.isEmpty {
                                VStack {
                                    Text("Oops! There aren't any food items right now")
                                        .accessibilityIdentifier("emptyFoodMessage")
                                }
                            } else {
                                ForEach(viewModel.filteredFoodItems) { item in
                                    VStack {
                                        FoodItemRow(
                                            item: item,
                                            categoryName: viewModel.categoryName(for: item),
                                            quantity: viewModel.quantityInCart(item),
                                            onAdd: { viewModel.addToCart(item) }
                                        )
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityIdentifier("foodRow_\(item.id)")
                                }
                            }
                        }
                    }
                    .refreshable {
                            // concurrent firing
                            let vm = viewModel
                            async let cats: () = vm.fetchCategories()
                            async let foods: () = vm.fetchFoodItems()
                            await cats
                            await foods
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FoodScreen()
        .environment(HomeViewModel())
}
