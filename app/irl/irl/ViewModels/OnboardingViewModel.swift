//
//  OnboardingViewModel.swift
//  irl
//
//  Created by Elijah Arbee on 9/29/24.
//

import SwiftUI

class OnboardingViewModel: ObservableObject {
    @Published var step: Int = 0
    @Published var userName: String = ""
    @Published var hasCompletedOnboarding: Bool = false // Local state for managing onboarding completion

    init() {
        // Any necessary initialization logic can go here
    }

    func nextStep() {
        if step < 6 {
            step += 1
        } else {
            hasCompletedOnboarding = true
        }
    }

    func validateInput() -> Bool {
        return !userName.isEmpty
    }
}
