//
//  URLSessionProtocol.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//

import Foundation

// So that we can eventually mock API failures and see how the app reacts
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// URLSession already implements both methods — declare conformance for free.
extension URLSession: URLSessionProtocol {}
