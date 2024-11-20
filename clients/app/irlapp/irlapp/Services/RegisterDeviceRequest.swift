//
//  RegisterDeviceToServer.swift
//  CaringMind
//
//  Handles device registration with the backend server.
//

import Foundation

// MARK: - RegisterDeviceRequest Struct

struct RegisterDeviceRequest: Encodable {
    let google_account_id: String
    let device_uuid: String
    let id_token: String
    let access_token: String
}

// MARK: - RegisterDeviceToServer

class RegisterDeviceToServer {
    
    // Hardcoded backend URL for device registration
    private let registerDeviceURL = "https://8bdb-2a09-bac5-661b-1232-00-1d0-c6.ngrok-free.app/v2/device/register"
    
    /// Asynchronously registers the device with the backend server.
    /// - Parameters:
    ///   - googleAccountID: The Google Account ID of the user.
    ///   - deviceUUID: The UUID of the device.
    ///   - idToken: The ID token for authentication.
    ///   - accessToken: The access token for authentication.
    func registerDeviceWithServer(googleAccountID: String, deviceUUID: String, idToken: String, accessToken: String) async throws {
        guard let url = URL(string: registerDeviceURL) else {
            throw URLError(.badURL)
        }
    
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
        // Create the request body using RegisterDeviceRequest struct
        let body = RegisterDeviceRequest(
            google_account_id: googleAccountID,
            device_uuid: deviceUUID,
            id_token: idToken,
            access_token: accessToken
        )
        request.httpBody = try JSONEncoder().encode(body)
    
        // Perform the network request
        let (data, response) = try await URLSession.shared.data(for: request)
    
        // Check the response status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
    
        switch httpResponse.statusCode {
        case 201:
            print("Device registered successfully.")
            // Update local registration status
            RegistrationStatus.setDeviceRegistered(true)
        case 400:
            // Handle bad request
            let decoder = JSONDecoder()
            let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
            throw RegistrationError.badRequest(errorResponse.detail)
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

// MARK: - Supporting Models and Enums

/// Represents an error response from the backend.
struct ErrorResponse: Codable {
    let detail: String
}

/// Defines possible registration errors.
enum RegistrationError: Error, LocalizedError {
    case badRequest(String)
    case serverError(Int, String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .badRequest(let message):
            return "Bad Request: \(message)"
        case .serverError(let code, let message):
            return "Server Error (\(code)): \(message)"
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
