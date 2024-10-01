//
//  OnboardingView.swift
//  irl
//
//  Created by Elijah Arbee on 9/29/24.
// TODO: Modularized OnboardingIntro - need to test  https://chatgpt.com/share/66fa2a76-9e38-800f-92c5-4205b29f8a32
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel // Binding the ViewModel
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                Spacer()

                if viewModel.step == 0 {
                    Text("Welcome.")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                viewModel.nextStep()
                            }
                        }
                }
                else if viewModel.step == 1 {
                    Text("Everything in life is data—moments, thoughts, emotions.")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                viewModel.nextStep()
                            }
                        }
                }
                else if viewModel.step == 2 {
                    Text("How you manage that data shapes your day and empowers your future.")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                viewModel.nextStep()
                            }
                        }
                }
                else if viewModel.step == 3 {
                    Text("We're here to help you master it. Let’s start with something simple.")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                viewModel.nextStep()
                            }
                        }
                }
                else if viewModel.step == 4 {
                    Text("What's your name?")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 10)

                    TextField("", text: $viewModel.userName)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                        .shadow(radius: 5)
                    
                    Button(action: {
                        if viewModel.validateInput() {
                            viewModel.nextStep()
                        }
                    }) {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.validateInput() ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .disabled(!viewModel.validateInput())
                }
                else if viewModel.step == 5 {
                    Text("Great to meet you, \(viewModel.userName)! How old are you?")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 10)

                    TextField("Enter your age", text: $viewModel.userName)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                        .shadow(radius: 5)

                    Button(action: {
                        if viewModel.validateInput() {
                            viewModel.nextStep()
                        }
                    }) {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.validateInput() ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .disabled(!viewModel.validateInput())
                }
                else if viewModel.step == 6 {
                    Text("Thanks, \(viewModel.userName). Let’s get started on your journey.")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                }

                Spacer()
            }
        }
    }
}
