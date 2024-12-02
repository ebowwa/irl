import SwiftUI
import ReSwift

struct OnboardingView: View {
    @StoreState(\.onboarding.currentStep) private var currentStep
    @StoreState(\.onboarding.isLoading) private var isLoading

    var body: some View {
        VStack(spacing: 20) {
            switch currentStep {
            case .welcome:
                welcomeView
            case .nameInput:
                NameInputView()
            case .truthLieGame:
                TruthLieGameView()
            }
        }
        .padding()
        .animation(.easeInOut, value: currentStep)
    }

    private var welcomeView: some View {
        VStack(spacing: 30) {
            Image(systemName: "heart.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)

            Text("Welcome to CaringMind")
                .font(.title)
                .bold()

            Text("Your personal mental wellness companion")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                PrimaryButton(
                    title: "Get Started",
                    action: { Store.shared.dispatch(.onboarding(.nextStep)) },
                    isLoading: isLoading
                )

                Button("Already have an account? Sign in") {
                    Store.shared.dispatch(.navigation(.navigateTo(.signIn)))
                }
                .foregroundColor(.blue)
            }
            .padding(.top, 30)
        }
    }
}

struct NameInputView: View {
    @StoreState(\.onboarding.name) private var name
    @StoreState(\.onboarding.isLoading) private var isLoading

    var body: some View {
        VStack(spacing: 20) {
            Text("What's your name?")
                .font(.title2)
                .bold()

            Text("We'll use this to personalize your experience")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            InputField(
                title: "Your Name",
                placeholder: "Enter your name",
                text: Binding(
                    get: { name },
                    set: { Store.shared.dispatch(.onboarding(.updateName($0))) }
                )
            )

            Spacer()

            PrimaryButton(
                title: "Continue",
                action: { Store.shared.dispatch(.onboarding(.nextStep)) },
                isLoading: isLoading,
                isDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
        .padding()
    }
}

struct TruthLieGameView: View {
    @StoreState(\.onboarding.truthLieAnswers) private var answers
    @StoreState(\.onboarding.isLoading) private var isLoading

    var body: some View {
        VStack(spacing: 20) {
            Text("Two Truths and a Lie")
                .font(.title2)
                .bold()

            Text("Let's have some fun! Share two truths and one lie about yourself")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                ForEach(0..<3) { index in
                    InputField(
                        title: "Statement \(index + 1)",
                        placeholder: "Enter your statement",
                        text: Binding(
                            get: { answers[index] },
                            set: { Store.shared.dispatch(.onboarding(.updateTruthLieAnswer(index: index, answer: $0))) }
                        )
                    )
                }
            }

            Spacer()

            PrimaryButton(
                title: "Complete & Sign Up",
                action: { Store.shared.dispatch(.onboarding(.complete)) },
                isLoading: isLoading,
                isDisabled: answers.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            )
        }
        .padding()
    }
}
