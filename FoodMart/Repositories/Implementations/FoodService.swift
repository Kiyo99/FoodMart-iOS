//
//  FoodService.swift
//  FoodMart
//
//  Created by Godsfavour Ngo Kio on 2026-05-28.
//
import Foundation

class FoodService: FoodServiceProtocol {
    // injected dependencies
    private let session: URLSessionProtocol
    
    init(
        session: URLSessionProtocol = URLSession.shared
    ) {
        self.session = session
    }
    
    func getFoods() async throws -> [FoodItem] {
        let baseURL = "https://7shifts.github.io/mobile-takehome/api/food_items.json"
        
        // first make sure the base url is valid
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        //Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("About to hit \(url.absoluteString)")
        
        // execute
        do {
            let (data, response) = try await session.data(for: request)
            
            //validate the response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            // Validate it was successful
            guard (200...299).contains(httpResponse.statusCode) else {
                print("Failed: \(httpResponse.statusCode)")
                var errorDescription: String?
                if let dataString = String(data: data, encoding: .utf8) {
                    errorDescription = dataString
                }
                let nsError = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedFailureReasonErrorKey: errorDescription ?? "Unknown error"])
                throw nsError
            }
            
            // Decode
            do {
                let decoder = JSONDecoder()
                
                let items = try decoder.decode([FoodItem].self, from: data)
                print("✅ Successfully decoded result server")
                return items
            } catch {
                print("❌ Failed to decode: \(error)")
                throw error
            }
        } catch {
            print("Error: \(error)")
            throw error
        }
    }
    
    func getCategories() async throws -> [Category] {
        let baseURL = "https://7shifts.github.io/mobile-takehome/api/food_item_categories.json"
        
        // first make sure the base url is valid
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        //Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("About to hit \(url.absoluteString)")
        
        // execute
        do {
            let (data, response) = try await session.data(for: request)
            
            //validate the response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            // Validate it was successful
            guard (200...299).contains(httpResponse.statusCode) else {
                print("Failed: \(httpResponse.statusCode)")
                var errorDescription: String?
                if let dataString = String(data: data, encoding: .utf8) {
                    errorDescription = dataString
                }
                let nsError = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedFailureReasonErrorKey: errorDescription ?? "Unknown error"])
                throw nsError
            }
            
            // Decode
            do {
                let decoder = JSONDecoder()
                
                let categories = try decoder.decode([Category].self, from: data)
                print("✅ Successfully decoded result server")
                return categories
            } catch {
                print("❌ Failed to decode: \(error)")
                throw error
            }
        } catch {
            print("Error: \(error)")
            throw error
        }
    }
}
