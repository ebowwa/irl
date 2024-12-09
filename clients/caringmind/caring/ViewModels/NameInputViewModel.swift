import SwiftUI
import Combine

class NameInputViewModel: ObservableObject {
    @Published var receivedName: String = ""
    @Published var prosody: String = ""
    @Published var feeling: String = ""
    @Published var confidenceScore: Int = 0
    @Published var confidenceReasoning: String = ""
    @Published var psychoanalysis: String = ""
    @Published var locationBackground: String = ""
    
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isUploading: Bool = false
    @Published var showConfirmation: Bool = false
    
    private let inputNameService = InputNameService()
    private let userManager = UserManager.shared
    
    var isRecording: Bool {
        inputNameService.isRecording
    }
    
    func startRecording() {
        do {
            try inputNameService.startRecording()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    func stopRecording() {
        inputNameService.stopRecording()
    }
    
    func processAudioFile() {
        isUploading = true
        
        Task {
            do {
                let response = try await inputNameService.uploadAudioFile()
                await MainActor.run {
                    updateUIWithResponse(response)
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    private func updateUIWithResponse(_ response: ServerResponse) {
        receivedName = response.safeName
        prosody = response.safeProsody
        feeling = response.safeFeeling
        confidenceScore = response.safeConfidenceScore
        confidenceReasoning = response.safeConfidenceReasoning
        psychoanalysis = response.safePsychoanalysis
        locationBackground = response.safeLocationBackground
        showConfirmation = true
        isUploading = false
    }
    
    private func handleError(_ error: Error) {
        isUploading = false
        showError = true
        errorMessage = error.localizedDescription
    }
    
    func confirmName(isCorrectName: Bool, confirmedName: String) {
        let nameToSave = isCorrectName ? receivedName : confirmedName
        saveNameAndCreateMoment(nameToSave: nameToSave)
    }
    
    private func saveNameAndCreateMoment(nameToSave: String) {
        userManager.saveUsername(nameToSave)
        
        // Create and add the initial moment
        let moment = Moment.voiceAnalysis(
            name: nameToSave,
            prosody: prosody,
            feeling: feeling,
            confidenceScore: confidenceScore,
            analysis: psychoanalysis
        )
        userManager.addMoment(moment)
        
        // Update user stats
        userManager.updateHoursListened(0.1) // Initial interaction time
        userManager.updateGrowthPercentage(5) // Initial growth percentage
    }
    
    func resetState() {
        showConfirmation = false
        isUploading = false
        showError = false
        errorMessage = ""
    }
}
