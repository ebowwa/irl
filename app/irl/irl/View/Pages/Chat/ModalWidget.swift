import SwiftUI
import CoreData

// MARK: - View Models

class ChatParametersViewModel: ObservableObject, Codable {
    @Published var personality: String = ""
    @Published var skills: String = ""
    @Published var learningObjectives: String = ""
    @Published var intendedBehaviors: String = ""
    @Published var specificNeeds: String = ""
    @Published var apiEndpoint: String = ""
    @Published var jsonSchema: String = ""
    
    @Published var model: String
    @Published var maxTokens: Int
    @Published var temperature: Double
    @Published var systemPrompt: String
    
    @Published var imageGenerationEnabled: Bool = false
    @Published var speechGenerationEnabled: Bool = false
    @Published var videoGenerationEnabled: Bool = false
    
    @Published var useAIAlignment: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case personality, skills, learningObjectives, intendedBehaviors, specificNeeds, apiEndpoint, jsonSchema
        case model, maxTokens, temperature, systemPrompt
        case imageGenerationEnabled, speechGenerationEnabled, videoGenerationEnabled
        case useAIAlignment
    }
    
    init(claudeViewModel: ClaudeViewModel) {
        self.model = claudeViewModel.model
        self.maxTokens = claudeViewModel.maxTokens
        self.temperature = claudeViewModel.temperature
        self.systemPrompt = claudeViewModel.systemPrompt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        personality = try container.decode(String.self, forKey: .personality)
        skills = try container.decode(String.self, forKey: .skills)
        learningObjectives = try container.decode(String.self, forKey: .learningObjectives)
        intendedBehaviors = try container.decode(String.self, forKey: .intendedBehaviors)
        specificNeeds = try container.decode(String.self, forKey: .specificNeeds)
        apiEndpoint = try container.decode(String.self, forKey: .apiEndpoint)
        jsonSchema = try container.decode(String.self, forKey: .jsonSchema)
        model = try container.decode(String.self, forKey: .model)
        maxTokens = try container.decode(Int.self, forKey: .maxTokens)
        temperature = try container.decode(Double.self, forKey: .temperature)
        systemPrompt = try container.decode(String.self, forKey: .systemPrompt)
        imageGenerationEnabled = try container.decode(Bool.self, forKey: .imageGenerationEnabled)
        speechGenerationEnabled = try container.decode(Bool.self, forKey: .speechGenerationEnabled)
        videoGenerationEnabled = try container.decode(Bool.self, forKey: .videoGenerationEnabled)
        useAIAlignment = try container.decode(Bool.self, forKey: .useAIAlignment)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(personality, forKey: .personality)
        try container.encode(skills, forKey: .skills)
        try container.encode(learningObjectives, forKey: .learningObjectives)
        try container.encode(intendedBehaviors, forKey: .intendedBehaviors)
        try container.encode(specificNeeds, forKey: .specificNeeds)
        try container.encode(apiEndpoint, forKey: .apiEndpoint)
        try container.encode(jsonSchema, forKey: .jsonSchema)
        try container.encode(model, forKey: .model)
        try container.encode(maxTokens, forKey: .maxTokens)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(systemPrompt, forKey: .systemPrompt)
        try container.encode(imageGenerationEnabled, forKey: .imageGenerationEnabled)
        try container.encode(speechGenerationEnabled, forKey: .speechGenerationEnabled)
        try container.encode(videoGenerationEnabled, forKey: .videoGenerationEnabled)
        try container.encode(useAIAlignment, forKey: .useAIAlignment)
    }
    
    func applyToClaudeViewModel(_ claudeViewModel: ClaudeViewModel) {
        claudeViewModel.model = self.model
        claudeViewModel.maxTokens = self.maxTokens
        claudeViewModel.temperature = self.temperature
        claudeViewModel.systemPrompt = self.systemPrompt
    }
}

// MARK: - Views

struct ChatParametersModal: View {
    @StateObject private var viewModel: ChatParametersViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 0
    @State private var showingSaveDialog = false
    @State private var configTitle = ""
    @State private var configDescription = ""
    
    init(claudeViewModel: ClaudeViewModel) {
        _viewModel = StateObject(wrappedValue: ChatParametersViewModel(claudeViewModel: claudeViewModel))
    }
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                AdvancedSettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Developer", systemImage: "gearshape.2")
                    }
                    .tag(1)
                
                ToolsView(viewModel: viewModel)
                    .tabItem {
                        Label("Tools", systemImage: "network")
                    }
                    .tag(2)
                
                MemorySettingsView()
                    .tabItem {
                        Label("Memory", systemImage: "brain")
                    }
                    .tag(3)
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                showingSaveDialog = true
            })
        }
        .sheet(isPresented: $showingSaveDialog) {
            SaveConfigurationView(
                viewModel: viewModel,
                configTitle: $configTitle,
                configDescription: $configDescription,
                onSave: { isDraft in
                    saveConfiguration(isDraft: isDraft)
                },
                onDiscard: {
                    // Handle discard action (e.g., reset viewModel to initial state)
                    // For now, we'll just dismiss the modal
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func saveConfiguration(isDraft: Bool) {
        let config = Configuration(
            title: configTitle,
            description: configDescription,
            parameters: viewModel,
            isDraft: isDraft
        )
        LocalStorage.saveConfiguration(config)
        // 2 TODOS
        // TODO: IF no change has occured THEN DON'T save the configuration just exist on done

        // TODO: i want to display the local saves with an image as if this was imessage and the saved configurations people on ones favorites for their imessage.
        
        // Cloud saving (Firebase) would be implemented here
        // CloudStorage.saveConfiguration(config)
        
        if !isDraft {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct BasicSettingsView: View {
    @ObservedObject var viewModel: ChatParametersViewModel
    
    var body: some View {
        Form {
            if viewModel.useAIAlignment {
                Section(header: Text("AI Alignment")) {
                    Text("Configure AI Alignment")
                        .font(.headline)
                    Text("Customize your AI assistant by providing details about its personality, skills, learning objectives, and intended behaviors.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Specific Needs")
                            .font(.headline)
                        Text("Describe any specific requirements or constraints for your AI assistant.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $viewModel.specificNeeds)
                            .frame(height: 100)
                            .border(Color.secondary, width: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Personality")
                            .font(.headline)
                        Text("Define the personality traits of your AI assistant.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $viewModel.personality)
                            .frame(height: 100)
                            .border(Color.secondary, width: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Skills")
                            .font(.headline)
                        Text("List the skills and capabilities you want your AI assistant to have.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $viewModel.skills)
                            .frame(height: 100)
                            .border(Color.secondary, width: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Learning Objectives")
                            .font(.headline)
                        Text("Specify what you want your AI assistant to learn or focus on.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $viewModel.learningObjectives)
                            .frame(height: 100)
                            .border(Color.secondary, width: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Intended Behaviors")
                            .font(.headline)
                        Text("Describe the desired behaviors and actions of your AI assistant.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $viewModel.intendedBehaviors)
                            .frame(height: 100)
                            .border(Color.secondary, width: 1)
                    }
                }
            }
        }
    }
}

struct AdvancedSettingsView: View {
    @ObservedObject var viewModel: ChatParametersViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Model")) {
                Picker("Model", selection: $viewModel.model) {
                    ForEach(ClaudeViewModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
            }
            
            Section(header: Text("Parameters")) {
                Stepper("Max Tokens: \(viewModel.maxTokens)", value: $viewModel.maxTokens, in: 1...2000)
                
                VStack(alignment: .leading) {
                    Text("Temperature: \(viewModel.temperature, specifier: "%.1f")")
                    Slider(value: $viewModel.temperature, in: 0...1, step: 0.1)
                }
            }
            
            Section(header: Text("System Prompt")) {
                TextEditor(text: $viewModel.systemPrompt)
                    .frame(height: 100)
            }
        }
    }
}

struct ToolsView: View {
    @ObservedObject var viewModel: ChatParametersViewModel
    @State private var showingAPISettings = false
    
    var body: some View {
        Form {
            Section(header: Text("AI Alignment")) {
                Toggle("Use AI Alignment", isOn: $viewModel.useAIAlignment)
                if viewModel.useAIAlignment {
                    NavigationLink(destination: AlignAIView(viewModel: viewModel)) {
                        Text("Configure AI Alignment")
                    }
                }
            }
            
            Section(header: Text("Generation Capabilities")) {
                Toggle("Image Generation", isOn: $viewModel.imageGenerationEnabled)
                
                // These features are disabled for now, but kept in the UI for future implementation
                HStack {
                    Text("Speech Generation")
                    Spacer()
                    Image(systemName: "speaker.slash")
                        .foregroundColor(.gray)
                }
                .opacity(0.5)
                
                HStack {
                    Text("Video Generation")
                    Spacer()
                    Image(systemName: "video.slash")
                        .foregroundColor(.gray)
                }
                .opacity(0.5)
            }
            
            Section {
                Button("Configure API Endpoint") {
                    showingAPISettings = true
                }
            }
            
            Section {
                Link("Suggest a Feature", destination: URL(string: "https://forms.gle/yourGoogleFormURL")!)
            }
            
            Section {
                Link("Report a Bug", destination: URL(string: "https://forms.gle/yourGoogleFormURL")!)
            }
        }
        .sheet(isPresented: $showingAPISettings) {
            APISettingsView(viewModel: viewModel)
        }
    }
}

struct AlignAIView: View {
    @ObservedObject var viewModel: ChatParametersViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Personality")) {
                TextEditor(text: $viewModel.personality)
                    .frame(height: 100)
            }
            
            Section(header: Text("Skills")) {
                TextEditor(text: $viewModel.skills)
                    .frame(height: 100)
            }
            
            Section(header: Text("Learning Objectives")) {
                TextEditor(text: $viewModel.learningObjectives)
                    .frame(height: 100)
            }
            
            Section(header: Text("Intended Behaviors")) {
                TextEditor(text: $viewModel.intendedBehaviors)
                    .frame(height: 100)
            }
            
            Section(header: Text("Specific Needs")) {
                TextEditor(text: $viewModel.specificNeeds)
                    .frame(height: 100)
            }
        }
        .navigationTitle("AI Alignment")
    }
}

struct APISettingsView: View {
    @ObservedObject var viewModel: ChatParametersViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Third-party API Endpoint")) {
                    TextField("Enter API endpoint", text: $viewModel.apiEndpoint)
                }
                
                Section(header: Text("JSON Schema")) {
                    TextEditor(text: $viewModel.jsonSchema)
                        .frame(height: 200)
                }
            }
            .navigationTitle("API Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct SaveConfigurationView: View {
    @ObservedObject var viewModel: ChatParametersViewModel
    @Binding var configTitle: String
    @Binding var configDescription: String
    let onSave: (Bool) -> Void // Bool parameter indicates whether it's a draft
    let onDiscard: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDiscardAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Configuration Details")) {
                    TextField("Title", text: $configTitle)
                    TextEditor(text: $configDescription)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Save Configuration")
            .navigationBarItems(
                leading: Button("Save as Draft") {
                    onSave(true)
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack {
                        Button("Discard") {
                            showingDiscardAlert = true
                        }
                        Button("Save") {
                            onSave(false)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
            .alert(isPresented: $showingDiscardAlert) {
                Alert(
                    title: Text("Discard Changes"),
                    message: Text("Are you sure you want to discard your changes?"),
                    primaryButton: .destructive(Text("Discard")) {
                        onDiscard()
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    struct Configuration: Codable {
        let title: String
        let description: String
        let parameters: ChatParametersViewModel
        let isDraft: Bool
    }

    struct LocalStorage {
        static func saveConfiguration(_ config: Configuration) {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(config) {
                UserDefaults.standard.set(encoded, forKey: "savedConfig_\(config.title)")
            }
        }
        
        static func loadConfiguration(withTitle title: String) -> Configuration? {
            if let savedConfig = UserDefaults.standard.object(forKey: "savedConfig_\(title)") as? Data {
                let decoder = JSONDecoder()
                if let loadedConfig = try? decoder.decode(Configuration.self, from: savedConfig) {
                    return loadedConfig
                }
            }
            return nil
        }
    }


    // MARK: - Cloud Storage (Firebase) Implementation Notes

    /*
    To implement cloud storage using Firebase:

    1. Set up Firebase in your project:
       - Add the Firebase SDK to your project
       - Initialize Firebase in your App Delegate

    2. Create a FirebaseStorage struct:

    struct FirebaseStorage {
        static func saveConfiguration(_ config: Configuration) {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            
            do {
                try db.collection("users").document(userId).collection("configurations").document(config.title).setData(from: config)
            } catch let error {
                print("Error saving to Firestore: \(error)")
            }
        }
        
        static func loadConfiguration(withTitle title: String, completion: @escaping (Configuration?) -> Void) {
            guard let userId = Auth.auth().currentUser?.uid else {
                completion(nil)
                return
            }
            
            let db = Firestore.firestore()
            db.collection("users").document(userId).collection("configurations").document(title).getDocument { (document, error) in
                if let document = document, document.exists {
                    let result = Result {
                        try document.data(as: Configuration.self)
                    }
                    switch result {
                    case .success(let config):
                        completion(config)
                    case .failure(let error):
                        print("Error decoding configuration: \(error)")
                        completion(nil)
                    }
                } else {
                    print("Configuration does not exist")
                    completion(nil)
                }
            }
        }
    }


    3. In the saveConfiguration() method of ChatParametersModal:
       Add: FirebaseStorage.saveConfiguration(config)

    4. Implement user authentication to associate configurations with specific users.

    5. Handle offline capabilities and data synchronization.

    6. Ensure proper security rules are set up in Firebase to protect user data.

    7. Implement error handling and loading states in the UI when interacting with Firebase.
    */
