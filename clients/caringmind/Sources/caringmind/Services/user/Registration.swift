//
//  RegistrationStatus.swift
//  CaringMind
//
//  Created by Elijah Arbee on 11/12/24.
//

import Foundation

struct RegistrationStatus {
    private static let registrationKey = "isDeviceRegistered"

    /// Checks the local state reflecting the relationship with the server.
    static func isDeviceRegistered() -> Bool {
        let status = UserDefaults.standard.bool(forKey: registrationKey)
        print("RegistrationStatus.isDeviceRegistered: \(status)")
        return status
    }

    /// Updates the local state reflecting the relationship with the server.
    /// - Parameter registered: The current registration state with the server.
    static func setDeviceRegistered(_ registered: Bool) {
        UserDefaults.standard.set(registered, forKey: registrationKey)
        print("RegistrationStatus.setDeviceRegistered: \(registered)")
    }
}
//
//  RegisterDeviceToServer.swift
//  CaringMind
//
//  Handles device registration with the backend server.
//

struct RegisterDeviceRequest: Encodable {
    let google_account_id: String
    let device_uuid: String
    let id_token: String
    let access_token: String
}

class RegisterDeviceToServer {
    private let registerDeviceURL = Constants.baseURL + "/v2/device/register"

    func registerDeviceWithServer(googleAccountID: String, deviceUUID: String, idToken: String, accessToken: String) async throws {
        guard let url = URL(string: registerDeviceURL) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = RegisterDeviceRequest(
            google_account_id: googleAccountID,
            device_uuid: deviceUUID,
            id_token: idToken,
            access_token: accessToken
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        switch httpResponse.statusCode {
        case 201:
            print("Device registered successfully.")
            RegistrationStatus.setDeviceRegistered(true)
        case 400, 500:
            let decoder = JSONDecoder()
            let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
            throw RegistrationError.serverError(httpResponse.statusCode, errorResponse.detail)
        default:
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

//
//  CheckRegistrationRequest.swift
//  CaringMind
//
//  Created by Elijah Arbee on 11/19/24.
//

struct CheckRegistrationRequest: Encodable {
    let google_account_id: String
    let device_uuid: String
}

struct DeviceRegistrationCheckResponse: Codable {
    let is_registered: Bool
    let device: DeviceRegistrationEntry?
}

struct DeviceRegistrationEntry: Codable {
    let id: Int
    let google_account_id: String
    let device_uuid: String
    let id_token: String
    let access_token: String
    let created_at: String
}

class CheckDeviceServerRegistration {
    private let checkRegistrationURL = Constants.baseURL + "/v2/device/register/check"

    func isUserRegistered(googleAccountID: String, deviceUUID: String) async throws -> DeviceRegistrationCheckResponse {
        guard let url = URL(string: checkRegistrationURL) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = CheckRegistrationRequest(
            google_account_id: googleAccountID,
            device_uuid: deviceUUID
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(DeviceRegistrationCheckResponse.self, from: data)
        case 400, 404, 500:
            let decoder = JSONDecoder()
            let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
            throw RegistrationError.serverError(httpResponse.statusCode, errorResponse.detail)
        default:
            let decoder = JSONDecoder()
            let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
            throw RegistrationError.serverError(httpResponse.statusCode, errorResponse.detail)
        }
    }
}
