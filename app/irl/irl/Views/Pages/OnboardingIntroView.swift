//
//  OnboardingIntroView.swift
//  irl
//
//  Created by Elijah Arbee on 9/22/24.
//
import SwiftUI

struct IntroView: View {
    @State private var step: Int = 0
    @State private var userName: String = ""

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                Spacer()

                if step == 0 {
                    Text("Welcome.")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                step = 1
                            }
                        }
                }
                // New step for "moments, thoughts, emotions"
                else if step == 1 {
                    Text("Everything in life is data—moments, thoughts, emotions.")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                step = 2
                            }
                        }
                }
                else if step == 2 {
                    Text("How you manage that data shapes your day and empowers your future.")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                step = 3
                            }
                        }
                }
                else if step == 3 {
                    Text("We're here to help you master it. Let’s start with something simple.")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                step = 4
                            }
                        }
                }
                else if step == 4 {
                    Text("What's your name?")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 10)

                    TextField("", text: $userName)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                        .shadow(radius: 5)
                    
                    Button(action: {
                        if !userName.isEmpty {
                            step = 5
                        }
                    }) {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(userName.isEmpty ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .disabled(userName.isEmpty)
                }
                // Added further questions after asking the name
                else if step == 5 {
                    Text("Great to meet you, \(userName)! How old are you?")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 10)

                    // For simplicity, asking for age here
                    TextField("Enter your age", text: $userName)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                        .shadow(radius: 5)
                    
                    Button(action: {
                        if !userName.isEmpty {
                            step = 6
                        }
                    }) {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(userName.isEmpty ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .disabled(userName.isEmpty)
                }
                else if step == 6 {
                    Text("Thanks, \(userName). Let’s get started on your journey.")
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
