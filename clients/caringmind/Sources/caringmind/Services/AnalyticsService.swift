import Foundation
import WebKit

/// AnalyticsService: A service class that handles Google Analytics tracking in SwiftUI
/// Using GA4 configuration:
/// - Stream Name: caringmindxyz
/// - Stream URL: https://www.caringmind.xyz
/// - Stream ID: 10005514776
/// - Measurement ID: G-KMV4Y9H0SX
class AnalyticsService {
    /// Shared singleton instance
    static let shared = AnalyticsService()
    
    /// Hidden WebView that loads GA scripts
    private let webView: WKWebView
    
    /// Google Analytics Configuration
    private let measurementID = "G-KMV4Y9H0SX"
    private let streamID = "10005514776"
    private let streamURL = "https://www.caringmind.xyz"
    
    /// Private initializer for singleton pattern
    private init() {
        webView = WKWebView(frame: .zero)
        setupAnalytics()
    }
    
    /// Sets up Google Analytics by injecting the required scripts
    /// This creates a hidden WebView that loads the GA tracking code
    private func setupAnalytics() {
        // Standard GA4 initialization script
        let script = """
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', '\(measurementID)');
        """
        
        // Complete HTML with GA script tags
        let scriptSource = """
            <script async src="https://www.googletagmanager.com/gtag/js?id=\(measurementID)"></script>
            <script>
                \(script)
            </script>
        """
        
        // Load the scripts into the WebView
        webView.loadHTMLString(scriptSource, baseURL: URL(string: streamURL))
    }
    
    /// Logs a custom event to Google Analytics
    /// - Parameters:
    ///   - name: The name of the event
    ///   - parameters: Optional dictionary of event parameters
    func logEvent(name: String, parameters: [String: Any]? = nil) {
        // Convert parameters to JSON string
        let parametersJSON = parameters.flatMap { try? JSONSerialization.data(withJSONObject: $0) }
        let parametersString = parametersJSON.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        
        // Create and execute GA4 event tracking script
        let script = """
            gtag('event', '\(name)', \(parametersString));
        """
        
        // Execute the script in the WebView
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Analytics Error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Logs a screen view event
    /// - Parameter name: The name of the screen being viewed
    func logScreen(name: String) {
        logEvent(name: "screen_view", parameters: ["screen_name": name])
    }
    
    /// Logs a user action event
    /// - Parameters:
    ///   - action: The action performed
    ///   - category: Optional category of the action
    func logUserAction(action: String, category: String? = nil) {
        var parameters: [String: Any] = ["action": action]
        if let category = category {
            parameters["category"] = category
        }
        logEvent(name: "user_action", parameters: parameters)
    }
}