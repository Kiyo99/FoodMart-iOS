//
//  ContentView.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import SwiftUI

struct ContentView: View {
    @State private var homeViewModel = HomeViewModel()
    
    var body: some View {
        HomeScreen()
        //Environment objects
            .environment(homeViewModel)
    }
}

#Preview {
    ContentView()
        .environment(HomeViewModel())
}
