//
//  CheckRegistrationRequest.swift
//   CaringMind
//
//  Created by Elijah Arbee on 11/19/24.
//
import Foundation

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
