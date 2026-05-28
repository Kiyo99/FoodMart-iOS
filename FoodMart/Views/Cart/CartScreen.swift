//
//  CartScreen.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import SwiftUI

struct CartScreen: View {
    @Environment(HomeViewModel.self) private var homeVM
    var body: some View {
        @Bindable var homeVM = homeVM
        VStack {
            if !homeVM.errorMessage.isEmpty {
                Text("Error: \(homeVM.errorMessage)")
                    .accessibilityIdentifier("errorMessage")
            }
            else {
                VStack {
                    ScrollView {
                        VStack {
                            
                            if homeVM.cart.isEmpty {
                                VStack {
                                    Text("Uh oh, your cart is empty right now")
                                        .accessibilityIdentifier("emptyCartMessage")
                                }
                            } else {
                                ForEach(homeVM.cart) { item in
                                    VStack {
                                        CartItemRow(
                                            item: item,
                                            onDelete: { homeVM.removeFromCart(item.foodItem) }
                                        )
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityIdentifier("cartRow_\(item.id)")
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    Button(action: {
                        homeVM.purchase()
                    }){
                        Text("Purchase")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .bold()
                    .frame(height:50)
                    .frame(maxWidth: .infinity)
                    .background(
                        Color(.orange),
                        in: Capsule()
                    )
                    .padding(.horizontal)
                    .accessibilityIdentifier("purchaseButton")
                }
            }
        }
        .alert("Purchased!", isPresented: $homeVM.showPurchasedAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

#Preview {
    CartScreen()
        .environment(HomeViewModel())
}
