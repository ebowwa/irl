//
//  main.swift
//  openapi-generator
//
//  Created by Elijah Arbee on 10/12/24.
//
import OpenAPIURLSession
import Foundation

let client = Client(
    serverURL: URL(string: "http://localhost:8000/openapi.json")!,
    transport: URLSessionTransport()  // Using URLSession for making requests
)

Task {
    do {
        let response = try await client.getGreeting()
        print("Response: \(response)")
    } catch {
        print("Error: \(error)")
    }
}
