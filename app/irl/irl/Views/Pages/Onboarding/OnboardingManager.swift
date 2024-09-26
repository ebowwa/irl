//
//  OnboardingManager.swift
//  irl
//
//  Created by Elijah Arbee on 9/25/24.
//
// OnboardingManager.swift
import SwiftUI

class OnboardingManager: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
}
