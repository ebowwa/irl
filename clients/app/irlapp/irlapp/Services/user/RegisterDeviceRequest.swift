//
//  RegisterDeviceToServer.swift
//  CaringMind
//
//  Handles device registration with the backend server.
//
// TODO:
/* ERROR
 User not registered on server. Proceeding to register.
 handleSignIn: Registering device with server.
 Device registered successfully.
 RegistrationStatus.setDeviceRegistered: true
 Device registered successfully.
 
 INFO:     2600:387:f:4819::a:0 - "POST /onboarding/v6/process-audio?prompt_type=transcription HTTP/1.1" 200 OK
 INFO:route.user.device_registration_v2:Checking device registration status.
 INFO:route.user.device_registration_v2:Device is not registered.
 INFO:     73.15.186.2:0 - "POST /v2/device/register/check HTTP/1.1" 200 OK
 INFO:route.user.device_registration_v2:Registering device with Google Account ID: 116304392706380119032
 INFO:route.user.device_registration_v2:Device is already registered. Updating existing registration.
 INFO:route.user.device_registration_v2:Device registration updated successfully.
 INFO:route.user.device_registration_v2:Updated device registration retrieved: <databases.backends.common.records.Record object at 0x7fa003a9a0>
 INFO:     73.15.186.2:0 - "POST /v2/device/register HTTP/1.1" 201 Created
 */
import Foundation

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
