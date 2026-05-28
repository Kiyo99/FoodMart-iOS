//
//  HomeScreen.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//
import SwiftUI

enum HomeTab: String, CaseIterable {
    case home = "Food"
    case cart = "Cart"
}

struct HomeScreen: View {
    @State private var selectedTab: HomeTab = .home
    @Environment(HomeViewModel.self) private var viewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    switch selectedTab {
                    case .home:
                        FoodScreen()
                    case .cart:
                        CartScreen()
                    }
                }
                .padding()
                
                Spacer()
                
                // BOTTOM BAR
                HStack() {
                    ForEach(HomeTab.allCases, id: \.self){ tab in
                        let cartCount = viewModel.cart.reduce(0) { $0 + $1.quantity }
                        Button(action: {
                            selectedTab = tab
                        }) {
                            VStack{
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: tab == .home ? "fork.knife" : "cart")
                                        .font(.title2)
                                    if tab == .cart && cartCount > 0 {
                                        Text("\(cartCount)")
                                            .font(.caption2).bold()
                                            .foregroundStyle(.white)
                                            .padding(4)
                                            .background(.blue, in: Circle())
                                            .offset(x: 8, y: -8)
                                    }
                                }
                                Text(tab.rawValue)
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(
                                selectedTab == tab ? .blue : .gray
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("tab_\(tab.rawValue)")

                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task {
                // concurrent firing
                async let cats: () = viewModel.fetchCategories()
                async let foods: () = viewModel.fetchFoodItems()
                await cats
                await foods
            }
        }
    }
}
#Preview {
    HomeScreen()
        .environment(HomeViewModel())
}
