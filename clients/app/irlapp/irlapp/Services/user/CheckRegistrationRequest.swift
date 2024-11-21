//
//  CheckRegistrationRequest.swift
//   CaringMind
//
//  Created by Elijah Arbee on 11/19/24.
//


//
//  CheckDeviceServerRegistration.swift
//  CaringMind
//
//  Handles checking device registration status with the backend server.
//

import Foundation

// MARK: - CheckRegistrationRequest Struct

struct CheckRegistrationRequest: Encodable {
    let google_account_id: String
    let device_uuid: String
}

// MARK: - DeviceRegistrationCheckResponse Struct

struct DeviceRegistrationCheckResponse: Codable {
    let is_registered: Bool
    let device: DeviceRegistrationEntry?
}

// MARK: - DeviceRegistrationEntry Struct

struct DeviceRegistrationEntry: Codable {
    let id: Int
    let google_account_id: String
    let device_uuid: String
    let id_token: String
    let access_token: String
    let created_at: String // Consider using Date with appropriate decoding
}

// MARK: - CheckDeviceServerRegistration

class CheckDeviceServerRegistration {
    
    // Hardcoded backend URL for checking device registration
    private let checkRegistrationURL = "https://8bdb-2a09-bac5-661b-1232-00-1d0-c6.ngrok-free.app/v2/device/register/check"
    
    /// Asynchronously checks if the user is registered by communicating with the backend.
    /// - Parameters:
    ///   - googleAccountID: The Google Account ID of the user.
    ///   - deviceUUID: The UUID of the device.
    /// - Returns: A `DeviceRegistrationCheckResponse` indicating registration status.
    func isUserRegistered(googleAccountID: String, deviceUUID: String) async throws -> DeviceRegistrationCheckResponse {
        guard let url = URL(string: checkRegistrationURL) else {
            throw URLError(.badURL)
        }
    
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
        // Use the CheckRegistrationRequest struct for the request body
        let body = CheckRegistrationRequest(
            google_account_id: googleAccountID,
            device_uuid: deviceUUID
        )
        request.httpBody = try JSONEncoder().encode(body)
    
        // Perform the network request
        let (data, response) = try await URLSession.shared.data(for: request)
    
        // Check the response status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
    
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(DeviceRegistrationCheckResponse.self, from: data)
        case 400:
            // Handle bad request
            let decoder = JSONDecoder()
            let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
            throw RegistrationError.badRequest(errorResponse.detail)
        case 404:
            // Not found, treat as not registered
            return DeviceRegistrationCheckResponse(is_registered: false, device: nil)
        case 500:
            // Handle server error
            let decoder = JSONDecoder()
            let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
            throw RegistrationError.serverError(httpResponse.statusCode, errorResponse.detail)
        default:
            // Handle other status codes
            let decoder = JSONDecoder()
            let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
            throw RegistrationError.serverError(httpResponse.statusCode, errorResponse.detail)
        }
    }
}
