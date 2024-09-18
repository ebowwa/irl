//
//  AppearanceSettingsView.swift
//  irl
// TODO: the dark mode looks ugly rn the colors we are using for it need to be corrected.. no text can be read
//  Created by Elijah Arbee on 8/29/24.
//
import SwiftUI

struct AppearanceSettingsView: View {
    
    // The @EnvironmentObject property wrapper is used to access the shared AppState
    // This allows the view to react to changes in the AppState and update accordingly
    @EnvironmentObject var appState: GlobalState

    var body: some View {
        Toggle("Dark Mode", isOn: Binding(
            get: { appState.currentTheme == .dark },
            set: { _ in appState.toggleTheme() }
        ))
        // Notes on state usage:
        // 1. The toggle's state is bound to appState.currentTheme
        // 2. appState.currentTheme is a @AppStorage property in AppState,
        //    which means it's persisted between app launches
        // 3. The binding uses a custom getter and setter:
        //    - Getter: Checks if the current theme is .dark
        //    - Setter: Calls appState.toggleTheme() to switch the theme
        // 4. appState.toggleTheme() is defined in AppState.swift as:
        //    func toggleTheme() {
        //        currentTheme = currentTheme == .light ? .dark : .light
        //    }
        // 5. Since AppState is an ObservableObject and currentTheme is @Published,
        //    any view observing AppState will be updated when the theme changes
    }
}

// Note: Ensure that AppState is injected into the environment
// typically in the app's main view or app struct, like this:
// ContentView()
//     .environmentObject(AppState())
