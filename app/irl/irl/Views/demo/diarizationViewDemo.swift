//
//  diarizationViewDemo.swift
//  IRL
//
//  Created by Elijah Arbee on 10/15/24.
//

import Foundation

struct DiarizationOutput: Identifiable, Codable {
    let id = UUID()
    let diarization_output: DiarizationSegment
    let progress: Double
}

struct DiarizationSegment: Codable {
    let start: Double
    let end: Double
    let speaker: String
}
import SwiftUI
import Combine

class DiarizationViewModel: NSObject, ObservableObject, URLSessionDataDelegate {
    @Published var diarizationOutputs: [DiarizationOutput] = []
    @Published var isUploading: Bool = false
    @Published var errorMessage: String?
    
    private var urlSession: URLSession!
    private var buffer: Data = Data()
    
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        // Initialize URLSession with self as delegate to handle streaming data
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    /// Uploads the audio file and initiates diarization using the sliding window approach.
    /// - Parameters:
    ///   - fileURL: URL of the selected audio file.
    ///   - windowSize: Duration of each window in seconds.
    ///   - stepSize: Step size for sliding the window in seconds.
    func uploadAndDiarize(fileURL: URL, windowSize: Float = 5.0, stepSize: Float = 2.5) {
        isUploading = true
        diarizationOutputs = []
        errorMessage = nil
        buffer = Data()
        
        // Construct the API URL
        let baseURL = Constants.API.baseURL
        guard let url = URL(string: "\(baseURL)/api/diarization_sliding_window?window_size=\(windowSize)&step_size=\(stepSize)") else {
            self.errorMessage = "Invalid URL"
            self.isUploading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create multipart/form-data body
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let filename = fileURL.lastPathComponent
        let mimeType = "audio/wav"
        
        var body = Data()
        // Append the form data for the file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            body.append(fileData)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to read audio file: \(error.localizedDescription)"
                self.isUploading = false
            }
            return
        }
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Start the upload task
        let task = urlSession.uploadTask(with: request, from: body)
        task.resume()
    }
    
    // MARK: - URLSessionDataDelegate Methods
    
    /// Handles incoming data from the streaming response.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Append received data to the buffer
        buffer.append(data)
        
        // Process each complete line (assuming each line is a JSON object)
        while let range = buffer.range(of: Data("\n".utf8)) {
            let lineData = buffer.subdata(in: 0..<range.lowerBound)
            buffer.removeSubrange(0..<range.upperBound)
            
            if let jsonString = String(data: lineData, encoding: .utf8) {
                do {
                    let output = try JSONDecoder().decode(DiarizationOutput.self, from: Data(jsonString.utf8))
                    DispatchQueue.main.async {
                        self.diarizationOutputs.append(output)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to parse diarization output: \(error.localizedDescription)"
                        self.isUploading = false
                    }
                }
            }
        }
    }
    
    /// Handles task completion, including any errors.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            self.isUploading = false
            if let error = error {
                self.errorMessage = "Upload failed: \(error.localizedDescription)"
            }
        }
    }
}
import SwiftUI

struct DiarizationView: View {
    @StateObject private var viewModel = DiarizationViewModel()
    @State private var showingFileImporter = false
    @State private var selectedFileURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Display selected file information
                if let fileURL = selectedFileURL {
                    Text("Selected File: \(fileURL.lastPathComponent)")
                        .padding()
                } else {
                    Text("No file selected")
                        .padding()
                }
                
                // Button to select an audio file
                Button(action: {
                    showingFileImporter = true
                }) {
                    Text("Select Audio File")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .fileImporter(
                    isPresented: $showingFileImporter,
                    allowedContentTypes: [.audio],
                    allowsMultipleSelection: false
                ) { result in
                    do {
                        let urls = try result.get()
                        if let firstURL = urls.first {
                            selectedFileURL = firstURL
                        }
                    } catch {
                        viewModel.errorMessage = "Failed to select file: \(error.localizedDescription)"
                    }
                }
                
                // Button to start diarization
                Button(action: {
                    if let fileURL = selectedFileURL {
                        viewModel.uploadAndDiarize(fileURL: fileURL)
                    }
                }) {
                    Text("Start Diarization")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background((selectedFileURL != nil && !viewModel.isUploading) ? Color.green : Color.gray)
                        .cornerRadius(8)
                }
                .disabled(selectedFileURL == nil || viewModel.isUploading)
                
                // Progress Indicator
                if viewModel.isUploading {
                    ProgressView("Diarization in progress...")
                        .padding()
                }
                
                // Display diarization outputs
                List(viewModel.diarizationOutputs) { output in
                    VStack(alignment: .leading) {
                        Text("Speaker: \(output.diarization_output.speaker)")
                            .font(.headline)
                        Text(String(format: "Start: %.2f s, End: %.2f s", output.diarization_output.start, output.diarization_output.end))
                            .font(.subheadline)
                        Text(String(format: "Progress: %.2f%%", output.progress))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Display error message if any
                if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Diarization Test")
            .padding()
        }
    }
}
