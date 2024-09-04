//
//  Transcribe.swift
//  irl
//
//  Created by Elijah Arbee on 9/1/24.
//
import SwiftUI
import Combine
import AVFoundation

struct TranscribeView: View {
    @StateObject private var whisperService = WhisperService()
    @State private var task: TaskEnum = .transcribe
    @State private var language: LanguageEnum = .en
    @State private var isShowingFilePicker = false
    @State private var audioFileURL: URL?

    var body: some View {
        VStack {
            Text("WhisperTTS")
                .font(.largeTitle)
                .padding()

            Picker("Task", selection: $task) {
                Text("Transcribe").tag(TaskEnum.transcribe)
                Text("Translate").tag(TaskEnum.translate)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Picker("Language", selection: $language) {
                ForEach(LanguageEnum.allCases, id: \.self) { language in
                    Text(language.rawValue).tag(language)
                }
            }
            .padding()

            Button(action: {
                isShowingFilePicker = true
            }) {
                Text("Select Audio File")
            }
            .padding()

            if whisperService.isLoading {
                ProgressView()
            } else if !whisperService.output.text.isEmpty {
                Text("Result:")
                    .font(.headline)
                ScrollView {
                    Text(whisperService.output.text)
                        .padding()
                }
                
                Text("Chunks:")
                    .font(.headline)
                List(whisperService.output.chunks, id: \.text) { chunk in
                    VStack(alignment: .leading) {
                        Text("\(chunk.timestamp[0]) - \(chunk.timestamp[1])")
                            .font(.caption)
                        Text(chunk.text)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingFilePicker) {
            DocumentPicker(fileURL: $audioFileURL)
        }
        .onChange(of: audioFileURL) { newValue in
            if let url = newValue {
                whisperService.uploadFile(url: url, task: task, language: language)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            print("Error: \(error.localizedDescription)")
                        }
                    }, receiveValue: { _ in })
                    .store(in: &whisperService.cancellables)
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileURL: URL?

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.fileURL = url
        }
    }
}
